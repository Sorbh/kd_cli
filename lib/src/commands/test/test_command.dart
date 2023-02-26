import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:kd_cli/src/cli/cli.dart';
import 'package:kd_cli/src/commands/test/constants/test_arguments.dart';
import 'package:kd_cli/src/commands/test/model/package_test_summary.dart';
import 'package:kd_cli/src/commands/test/model/test_options.dart';
import 'package:kd_cli/src/commands/test/utils/test_report_utils.dart';
import 'package:kd_cli/src/models/package_info.dart';
import 'package:kd_cli/src/models/step_result_message.dart';
import 'package:kd_cli/src/utils/file_util.dart';
import 'package:kd_cli/src/utils/kd_cli_logger.dart';
import 'package:kd_cli/src/utils/workspace_util.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';
import 'package:pool/pool.dart';

import 'input/package_select_input.dart';
import 'model/test_step_result.dart';

part 'steps/test_coverage_step.dart';
part 'steps/test_step.dart';
part 'utils/code_coverage_utils.dart';

class TestCommand extends Command<int> {
  TestCommand({
    KdCliLogger? logger,
  }) : logger = logger ?? KdCliLogger() {
    argParser
      ..addFlag(TestArguments.all,
          defaultsTo: true,
          negatable: true,
          help:
              'Set this flag to enable option to choose the package before testing')
      ..addFlag(TestArguments.clean,
          defaultsTo: false,
          negatable: true,
          abbr: 'c',
          help: 'Clean all the old icov.info file')
      ..addFlag(TestArguments.skipCoverage,
          defaultsTo: false, negatable: true, help: 'Skip the test coverage');
  }

  final KdCliLogger logger;

  @override
  String get description =>
      'Run the test or test coverage command. Run this command inside the  repo and ';

  @override
  String get summary => '$invocation\n$description';

  @override
  String get name => 'test';

  @override
  String get invocation => 'kd test <project-name>';

  @override
  Future<int> run() async {
    Progress progressLog;
    final TestOptions testOptions = TestOptions.fromArgs(argResults!);

    logger.info('Loading workspace packages');
    progressLog = logger.progress('Scaning workspace');
    final allPackages = await WorkspaceUtil.findMonoRepoPackages();
    progressLog.complete();

    logger.info('Package List');

    logger.info(allPackages.map((e) => e.name).join('\n'));
    logger.info('\n');

    final packageToTest = <PackageInfo>[];
    final packageTestSummries = <PackageTestSummary>[];

    ///Check if want to run test in all package
    if (testOptions.all) {
      packageToTest.addAll(allPackages);
      logger.writeGreenLine('Running Test in all Packages');
    } else {
      final selectedPackage =
          PackageSelectInput.promptForPackageSelect(logger, allPackages);
      packageToTest.addAll(selectedPackage);
      logger.writeGreenLine(
          'Running Test in [ ${packageToTest.map((e) => e.name).join(',')} ] packages');
    }

    final pool = Pool(packageToTest.length);

    ///Step 1
    ///Clean Up old Lcov file
    progressLog = logger.progress('Cleaning Upworkspace');
    packageToTest.forEach((element) async {
      if (FileUtil.fileExists(join(element.parent, 'coverage/lcov.info'))) {
        logger.info('Found Icov file in ${element.name}, Cleaning this up >>');
        Directory(join(element.parent, 'coverage')).deleteSync(recursive: true);
      } else {
        logger.info('No Icov file found in ${element.name}, Skipping >>');
      }
    });
    progressLog.complete();
    logger.writeLine('');

    ///Step 2
    ///Run test converage on selected package [packageToTest]
    progressLog = logger.progress('Running Test Coverage');

    ///Step 3
    ///Create Master Icov file to combine them all in the end
    await CodeCoverageUtils.createMasterCoverageFile();

    /// Run all the steps on all selected packages
    packageToTest.forEach((package) {
      unawaited(pool.withResource(() async {
        PackageTestSummary testRepot = PackageTestSummary(package.name);

        if (testOptions.skipCoverage) {
          ///Step - Run Code test
          testRepot.addResult(await TestSteps.runTest(package));
        } else {
          ///Step - Run Code test and Coverage
          testRepot
              .addResults(await TestCoverageSteps.runTestCoverage(package));
        }

        packageTestSummries.add(testRepot);
      }));
    });
    await pool.close();
    await pool.done;

    ///Copy master lcov file to defaul location to vs code to read
    await CodeCoverageUtils.copyMasterLcovToCoverage();

    progressLog.complete();

    ///Generate detailed report
    progressLog = logger.progress('\nGenerating Report');
    logger.success(
        '🔖 Test Report for packges [${packageToTest.map((e) => e.name).join(',')}]\n\n');
    packageTestSummries.forEach((packageTestSummery) {
      logger.info(
          '📦 Package Name - ${green.wrap(packageTestSummery.packageName)}');
      _logResults(packageTestSummery, false);
      logger.writeLine('');
    });

    ///Generate Short Summery for test
    logger.success('Test Short Summery');
    packageTestSummries.forEach((packageTestSummery) {
      logger.info(
          '📦 Package Name - ${packageTestSummery.hasErrors ? ' ${red.wrap(packageTestSummery.packageName)} ❌' : ' ${green.wrap(packageTestSummery.packageName)} ✅'}');
    });
    progressLog.complete();

    return ExitCode.success.code;
  }

  void _logResults(PackageTestSummary analyzeSummary, bool verbose) {
    final String packageName = analyzeSummary.packageName;
    if (analyzeSummary.hasErrors) {
      _failureStartMessage(packageName, analyzeSummary.failedSteps);
      for (final stepResult in analyzeSummary.results) {
        _logResultMessages(stepResult, verbose);
      }
      _failureEndMessage(packageName, analyzeSummary.failedSteps);
    } else if (analyzeSummary.hasWarnings) {
      if (verbose) _warningStartMessage(packageName);
      for (final stepResult in analyzeSummary.results) {
        _logResultMessages(stepResult, verbose);
      }
      if (verbose) _warningEndMessage(packageName);
    } else {
      // if (verbose) {
      _successStartMessage(packageName);
      for (final stepResult in analyzeSummary.results) {
        _logResultMessages(stepResult, verbose);
      }
      _successEndMessage(packageName);
      // } else {
      //   logger.progressPass('$packageName is all good! 🍻');
      // }
    }
  }

  void _logResultMessages(TestStepResult stepResults, bool verbose) {
    for (final resultMessage in stepResults.resultMessages) {
      switch (resultMessage.messageType) {
        case MessageType.normal:
          logger.writeLine(resultMessage.message);
          break;
        case MessageType.warning:
          logger.writeLine('⚠️ ${resultMessage.message}');
          break;
        case MessageType.failure:
          logger.writeLine(resultMessage.message);
          break;
        case MessageType.outputVerbose:
          if (verbose) logger.writeLine(resultMessage.message);
          break;

        default:
          if (verbose) logger.writeLine(resultMessage.message);
          break;
      }
    }
  }

  void _failureStartMessage(
      String packageName, List<TestStepType> stepsWithErrors) {
    return logger.writeRedLine(
        '🚨 - failure start - $packageName has errors in the following step(s): $stepsWithErrors - failure start - 🚨');
  }

  void _failureEndMessage(
      String packageName, List<TestStepType> stepsWithErrors) {
    return logger.writeRedLine(
        '🚨 -  failure end  - $packageName has errors in the following step(s): $stepsWithErrors -  failure end  - 🚨');
  }

  void _warningStartMessage(String packageName) {
    return logger.writeYellowLine(
        '⚠️ - warning start - $packageName has warnings - warning start - ⚠️');
  }

  void _warningEndMessage(String packageName) {
    return logger.writeYellowLine(
        '⚠️ -  warning end  - $packageName has warnings -  warning end  - ⚠️');
  }

  void _successStartMessage(String packageName) {
    return logger.writeGreenLine(
        '🍻 - success start - $packageName is all good! - success start - 🍻');
  }

  void _successEndMessage(String packageName) {
    return logger.writeGreenLine(
        '🍻 -  success end  - $packageName is all good! -  success end  - 🍻');
  }
}

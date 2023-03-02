// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:kd_cli/src/cli/cli.dart';
import 'package:kd_cli/src/commands/test/model/package_test_summary.dart';
import 'package:kd_cli/src/commands/test/model/test_options.dart';
import 'package:kd_cli/src/commands/test/utils/test_report_utils.dart';
import 'package:kd_cli/src/models/package_info.dart';
import 'package:kd_cli/src/models/step_result_message.dart';
import 'package:kd_cli/src/utils/file_util.dart';
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
    Logger? logger,
  }) : logger = logger ?? Logger() {
    argParser
      ..addMultiOption(
        TestArguments.packages,
        help:
            'provide the packages to run the test or test coverage. If not provided, you can choose the choose-package flag to choose the package to run test or test coverage',
      )
      ..addFlag(
        TestArguments.choosePackage,
        help:
            'Prompt to choose the package to run test or test coverage. If not provided, it will run test in all packages',
      )
      ..addFlag(TestArguments.doClean,
          help:
              'Clean up the old coverage file before running test, default is off')
      ..addFlag(TestArguments.pubUpdate,
          help: 'run pub update before running test, default is off')
      ..addFlag(
        TestArguments.skipCoverage,
        help:
            'Skip the test coverage and run only test, default it run the coverage',
      )
      ..addFlag(
        TestArguments.fullReport,
        help: 'Create full report with all the details, default is off',
      )
      ..addFlag(
        TestArguments.exportReport,
        help: 'Export the report to reprt file, default is off',
      )
      ..addFlag(
        TestArguments.showProgress,
        defaultsTo: true,
        help: 'Show progress of the test on every step, default is on',
      );
  }

  final Logger logger;

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
    final startTime = DateTime.now().millisecondsSinceEpoch;

    Progress stepProgressLog;

    ///Get the test options
    final testOptions = TestOptions.fromArgs(argResults!);

    logger.level = testOptions.showProgress ? Level.info : Level.quiet;

    if (testOptions.showProgress) logger.info('Loading workspace packages');
    stepProgressLog = logger.progress('Scaning workspace');
    final allPackages = await WorkspaceUtil.findMonoRepoPackages();
    stepProgressLog.complete();

    logger.info('Package List');
    logger.info(allPackages.map((e) => e.logNameWithPath()).join('\n'));
    logger.info('\n');

    final packageToTest = <PackageInfo>[];
    final packageTestSummries = <PackageTestSummary>[];

    ///Check if want to run test in all package
    if (testOptions.packages.isEmpty && testOptions.choosePackage) {
      final selectedPackage =
          PackageSelectInput.promptForPackageSelect(logger, allPackages);
      packageToTest.addAll(selectedPackage);
      logger.success(
          'Running Test in [ ${packageToTest.map((e) => e.name).join(',')} ] packages');
    } else {
      if (testOptions.packages.isNotEmpty) {
        packageToTest.addAll(allPackages
            .where((element) => testOptions.packages.contains(element.name)));
        logger.success(
            'Running Test in [ ${packageToTest.map((e) => e.name).join(',')} ] packages');
      } else {
        packageToTest.addAll(allPackages);
        logger.success('Running Test in all Packages');
      }
    }

    ///TestArguments.doClean
    if (testOptions.doClean) {
      stepProgressLog = logger.progress('Cleaning Upworkspace');
      for (var element in packageToTest) {
        if (FileUtil.fileExists(join(element.parent, 'coverage/lcov.info'))) {
          logger
              .info('Found Icov file in ${element.name}, Cleaning this up >>');
          Directory(join(element.parent, 'coverage'))
              .deleteSync(recursive: true);
        } else {
          logger.info('No Icov file found in ${element.name}, Skipping >>');
        }
      }
      stepProgressLog.complete();
    }

    ///TestArguments.pubUpdate
    ///Run pub update on all packages
    // function to run pub update on all packages
    if (testOptions.pubUpdate) {
      final pool = Pool(packageToTest.length);
      stepProgressLog = logger.progress('Running pub update');
      for (var element in packageToTest) {
        logger.info('Running pub update on ${element.name} >>');
        final result = await Future.wait([
          Flutter.clean(cwd: element.parent),
          Flutter.pubGet(cwd: element.parent)
        ]);
        if (result.any((element) => element.exitCode != 0)) {
          logger.err('pub update on ${element.name} failed >>');
        } else {
          logger.info('pub update on ${element.name} completed >>');
        }
      }
      await pool.close();
      await pool.done;
      stepProgressLog.complete();
    }

    ///Step 2
    ///Run test converage on selected package [packageToTest]
    stepProgressLog = logger.progress('Running Test Coverage');

    ///Step 3
    ///Create Master Icov file to combine them all in the end
    await CodeCoverageUtils.createMasterCoverageFile();

    /// Run all the steps on all selected packages
    final pool = Pool(packageToTest.length);
    for (final package in packageToTest) {
      unawaited(pool.withResource(() async {
        final testRepot = PackageTestSummary(package.name);

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
    }
    await pool.close();
    await pool.done;

    ///Copy master lcov file to defaul location to vs code to read
    await CodeCoverageUtils.copyMasterLcovToCoverage();

    stepProgressLog.complete();

    ///Generate detailed report
    if (testOptions.fullReport) {
      logger.level = Level.info;
      stepProgressLog = logger.progress('\nGenerating Report');
      logger.success(
          '🔖 Test Report for packges [${packageToTest.map((e) => e.name).join(',')}]\n\n');
      for (var packageTestSummery in packageTestSummries) {
        logger.info('📦 pu${green.wrap(packageTestSummery.packageName)}');
        _logResults(packageTestSummery, false);
        logger.info('');
      }
    }

    ///Generate Short Summery for test
    logger.level = Level.info;
    logger.success('Test Short Summery');
    for (var packageTestSummery in packageTestSummries) {
      logger.info(
          '${packageTestSummery.hasErrors ? '❌ ${red.wrap(packageTestSummery.packageName)} ' : '✅ ${green.wrap(packageTestSummery.packageName)} '}'
          '${packageTestSummery.shortResult}');
    }
    stepProgressLog.complete();

    /// show total time taken in all steps
    final elapsedTime = DateTime.now().millisecondsSinceEpoch - startTime;
    final displayInMilliseconds = elapsedTime < 100;
    final time = displayInMilliseconds ? elapsedTime : elapsedTime / 1000;
    final formattedTime =
        displayInMilliseconds ? '${time}ms' : '${time.toStringAsFixed(1)}s';
    logger
        .info('Running test Complete  - ${darkGray.wrap('($formattedTime)')}');

    return ExitCode.success.code;
  }

  void _logResults(PackageTestSummary analyzeSummary, bool verbose) {
    final packageName = analyzeSummary.packageName;
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
          logger.info(resultMessage.message);
          break;
        case MessageType.warning:
          logger.info('⚠️ ${resultMessage.message}');
          break;
        case MessageType.failure:
          logger.info(resultMessage.message);
          break;
        case MessageType.outputVerbose:
          if (verbose) logger.info(resultMessage.message);
          break;

        default:
          if (verbose) logger.info(resultMessage.message);
          break;
      }
    }
  }

  void _failureStartMessage(
          String packageName, List<TestStepType> stepsWithErrors) =>
      logger.err(
          '🚨 - failure start - $packageName has errors in the following step(s): $stepsWithErrors - failure start - 🚨');

  void _failureEndMessage(
          String packageName, List<TestStepType> stepsWithErrors) =>
      logger.err(
          '🚨 -  failure end  - $packageName has errors in the following step(s): $stepsWithErrors -  failure end  - 🚨');

  void _warningStartMessage(String packageName) => logger.warn(
      '⚠️ - warning start - $packageName has warnings - warning start - ⚠️');

  void _warningEndMessage(String packageName) => logger.warn(
      '⚠️ -  warning end  - $packageName has warnings -  warning end  - ⚠️');

  void _successStartMessage(String packageName) => logger.success(
      '🍻 - success start - $packageName is all good! - success start - 🍻');

  void _successEndMessage(String packageName) => logger.success(
      '🍻 -  success end  - $packageName is all good! -  success end  - 🍻');
}

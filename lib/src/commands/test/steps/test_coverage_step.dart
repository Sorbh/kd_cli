part of '../test_command.dart';

// ignore: avoid_classes_with_only_static_members
abstract class TestCoverageSteps {
  static Future<List<TestStepResult>> runTestCoverage(PackageInfo package,
      {double coverageLimit = 80}) async {
    final result = TestStepResult(stepType: TestStepType.test);

    //Generate Helper file
    await CodeCoverageUtils.generateCoverageHelper(package);

    final testResults =
        await Flutter.testCoverage(cwd: package.parent, throwOnError: false);

    if (testResults.exitCode != ExitCode.success.code) {
      result.addMessage(StepResultMessage(
          testResults.stderr.toString(), MessageType.outputVerbose));
      result.addMessage(StepResultMessage(
          testResults.stdout.toString(), MessageType.outputVerbose));
    } else {
      result.addMessage(StepResultMessage(
          testResults.stdout.toString(), MessageType.outputVerbose));
    }

    ///Generate Test Report
    final testReport = await TestReportUtils.parseReport(
        package, testResults.stdout.toString());

    if (!testReport.haveFailedTest) {
      result.addMessage(StepResultMessage(
          '✅ Package ${package.name} passed(${testReport.passedTestCount}) all the test',
          MessageType.normal));
    } else {
      result.addMessage(StepResultMessage(
          '❌ Package ${package.name} have some failed(${testReport.failedTestCount})/skipped(${testReport.skippedTestCount}) test',
          MessageType.failure));
      result.addMessage(
          StepResultMessage('\t🧪Failed Test name', MessageType.failure));
      for (var element in testReport.failedTest) {
        result.addMessage(
            StepResultMessage('\t🦠 ${element.name}', MessageType.failure));
        result.addMessage(
            StepResultMessage('\t   ${element.url}', MessageType.failure));
      }
    }

    ///Generaate Coverage Report
    final result1 = TestStepResult(stepType: TestStepType.codeCoverage);

    final coveragePre = await CodeCoverageUtils.checkLcovReport(package);

    if (coveragePre > coverageLimit) {
      result1.addMessage(StepResultMessage(
          '✅ Package ${package.name} have total coverage -> ${green.wrap('$coveragePre')}',
          MessageType.normal));
    } else {
      result1.addMessage(StepResultMessage(
          '❌ package ${package.name} have total coverage -> ${red.wrap('$coveragePre')} but minimum $coverageLimit is required',
          MessageType.failure));
    }

    //Step - Delete all test file helper class
    await CodeCoverageUtils.deleteCoverageHelper(package);

    //Step - Combine Icov file with master file
    await CodeCoverageUtils.appendToMasterFile(package);

    return <TestStepResult>[result, result1];
  }
}

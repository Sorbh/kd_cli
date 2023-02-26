part of '../test_command.dart';

// ignore: avoid_classes_with_only_static_members
abstract class TestSteps {
  static Future<TestStepResult> runTest(PackageInfo package,
      [bool skipCoverage = false]) async {
    final result = TestStepResult(stepType: TestStepType.test);

    final testResults =
        await Flutter.test(cwd: package.parent, throwOnError: false);

    if (testResults.exitCode != ExitCode.success.code) {
      result.addMessage(StepResultMessage(
          testResults.stdout.toString(), MessageType.outputVerbose));
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

    return result;
  }
}

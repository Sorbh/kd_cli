import 'package:kd_cli/src/commands/test/model/test_step_result.dart';

class PackageTestSummary {
  String packageName;
  List<TestStepResult> results = [];

  PackageTestSummary(this.packageName);

  void addResult(TestStepResult result) {
    results.add(result);
  }

  void addResults(List<TestStepResult> result) {
    results.addAll(result);
  }

  bool get hasErrors {
    return results.any((result) => result.hasError);
  }

  bool get hasWarnings {
    return results.any((result) => result.hasWarnings);
  }

  bool get hasCoverageErrors {
    return results.any((result) =>
        result.hasError && result.stepType == TestStepType.codeCoverage);
  }

  bool get hasTestErrors {
    return results.any(
        (result) => result.hasError && result.stepType == TestStepType.test);
  }

  List<TestStepType> get failedSteps {
    final list = <TestStepType>[];
    if (hasTestErrors) list.add(TestStepType.test);
    if (hasCoverageErrors) list.add(TestStepType.codeCoverage);
    return list;
  }

  @override
  String toString() =>
      'PackageTestSummary(packageName: $packageName, results: $results)';
}

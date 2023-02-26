import 'package:kd_cli/src/commands/code_snippet/model/code_snippet_step_result.dart';

class CodeSnippetSummary {
  String packageName;
  List<CodeSnippetStepResult> results = [];

  CodeSnippetSummary(this.packageName);

  void addStepResult(CodeSnippetStepResult result) {
    results.add(result);
  }

  void addStepResults(List<CodeSnippetStepResult> result) {
    results.addAll(result);
  }

  bool get hasErrors {
    return results.any((result) => result.hasError);
  }

  List<CodeSnippetStepResult> get errors {
    return results.where((result) => result.hasError).toList();
  }

  bool get hasWarnings {
    return results.any((result) => result.hasWarnings);
  }

  bool get hasMetaErrors {
    return results.any((result) =>
        result.hasError && result.stepType == CodeSnippetStepType.extractMeta);
  }

  List<CodeSnippetStepResult> get metaErrors {
    return results
        .where((result) =>
            result.hasError &&
            result.stepType == CodeSnippetStepType.extractMeta)
        .toList();
  }

  bool get hasMetaValidationErrors {
    return results.any((result) =>
        result.hasError && result.stepType == CodeSnippetStepType.validateMeta);
  }

  List<CodeSnippetStepResult> get metaValidationErrors {
    return results
        .where((result) =>
            result.hasError &&
            result.stepType == CodeSnippetStepType.validateMeta)
        .toList();
  }

  List<CodeSnippetStepType> get failedSteps {
    final list = <CodeSnippetStepType>[];
    if (hasMetaErrors) list.add(CodeSnippetStepType.extractMeta);
    if (hasMetaValidationErrors) list.add(CodeSnippetStepType.validateMeta);
    return list;
  }

  @override
  String toString() =>
      'CodeSnippetSummary(packageName: $packageName, results: $results)';
}

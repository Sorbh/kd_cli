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

  bool get hasErrors => results.any((result) => result.hasError);

  List<CodeSnippetStepResult> get errors =>
      results.where((result) => result.hasError).toList();

  bool get hasWarnings => results.any((result) => result.hasWarnings);

  bool get hasMetaErrors => results.any((result) =>
      result.hasError && result.stepType == CodeSnippetStepType.extractMeta);

  List<CodeSnippetStepResult> get metaErrors => results
      .where((result) =>
          result.hasError && result.stepType == CodeSnippetStepType.extractMeta)
      .toList();

  // ignore: prefer_expression_function_bodies
  bool get hasMetaValidationErrors {
    return results.any((result) =>
        result.hasError && result.stepType == CodeSnippetStepType.validateMeta);
  }

  // ignore: prefer_expression_function_bodies
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

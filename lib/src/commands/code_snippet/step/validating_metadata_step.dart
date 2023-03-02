// ignore_for_file: avoid_function_literals_in_foreach_calls, lines_longer_than_80_chars

part of '../code_snippet_command.dart';

abstract class ValidateMetadataStep {
  static Future<CodeSnippetStepResult> validateMetadata(
    List<CodeSnippet> codeSnippets,
  ) async {
    final result =
        CodeSnippetStepResult(stepType: CodeSnippetStepType.validateMeta);

    final duplicateCodeSnippet = <List<CodeSnippet>>[];
    final uniqueCodeSnippet = <CodeSnippet>[];

    codeSnippets.forEach((element) {
      if (uniqueCodeSnippet.contains(element)) {
        duplicateCodeSnippet.add(
            [uniqueCodeSnippet[uniqueCodeSnippet.indexOf(element)], element]);
      } else {
        // uniqueCodeSnippet.reversed
        uniqueCodeSnippet.add(element);
      }
    });

    if (duplicateCodeSnippet.isEmpty) {
      result.addMessage(StepResultMessage(
          '✅ Codesnippet all good !, dont have any duplicacy',
          MessageType.normal));
    } else {
      result.addMessage(StepResultMessage(
          '❌ CodeSnippet duplicacy found', MessageType.failure));
      result.addMessage(StepResultMessage(
          'Following Codesnippet have issue', MessageType.failure));
      for (var element in duplicateCodeSnippet) {
        result.addMessage(StepResultMessage(
            '\t🦠 ${red.wrap(element.map((e) => e.name).toList().join(','))} issue with ${element.first.haveIssueWithProperties(element[1]).join(',')}',
            MessageType.failure));
      }
    }

    return result;
  }
}

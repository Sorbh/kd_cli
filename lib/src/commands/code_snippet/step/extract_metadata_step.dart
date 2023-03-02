// ignore_for_file: avoid_function_literals_in_foreach_calls, lines_longer_than_80_chars

part of '../code_snippet_command.dart';

abstract class ExtractMetadataStep {
  static Future<CodeSnippetStepResult> extractMetadata(
    List<CodeSnippet> codeSnippets,
  ) async {
    final result =
        CodeSnippetStepResult(stepType: CodeSnippetStepType.extractMeta);
    final errorCodeSnippets = <CodeSnippet>[];
    codeSnippets.forEach((codeSnippet) {
      final metaDataRegex = RegExp(
          r'.*begin_sample_code((.|\n)*\*\/)\n((.|\n)*)\n(.*end_sample_code.*)');

      final metaRegexMatch = metaDataRegex.firstMatch(codeSnippet.content);

      if (metaDataRegex.hasMatch(codeSnippet.content)) {
        final metaString = metaRegexMatch!.group(1).toString();
        final codeString = metaRegexMatch.group(3).toString();

        const LineSplitter().convert(metaString).forEach((line) {
          if (line.contains(':')) {
            final component = line.split(':');
            final key = component[0].trim();
            component.removeAt(0);
            final value = component.join(':').trim();
            codeSnippet.metaDataMap[key] = value;
          }
        });

        codeSnippet.codeString = codeString;

        if (codeSnippet.haveValidMeta) {
          result.addMessage(StepResultMessage(
              '✅ CodeSnippet ${codeSnippet.name} have all the metadata ${codeSnippet.metaDataMap.toString()}',
              MessageType.outputVerbose));
        } else {
          errorCodeSnippets.add(codeSnippet);
          result.addMessage(StepResultMessage(
              '❌ CodeSnippet ${codeSnippet.name} have missing metadata ${codeSnippet.missingMeta.join(',')}',
              MessageType.outputVerbose));
        }
      } else {
        errorCodeSnippets.add(codeSnippet);
        result.addMessage(StepResultMessage(
            '❌ CodeSnippet ${codeSnippet.name} dont have meta data or issue in extracing metadata',
            MessageType.outputVerbose));
      }
    });

    if (errorCodeSnippets.isEmpty) {
      result.addMessage(StepResultMessage(
          '✅ All good with Codesnippets metadata extraction',
          MessageType.normal));
    } else {
      result.addMessage(StepResultMessage(
          '❌ CodeSnippet metadata error found', MessageType.failure));
      result.addMessage(StepResultMessage(
          'Following Codesnippet have issue', MessageType.failure));
      errorCodeSnippets.forEach((element) {
        result.addMessage(StepResultMessage(
            '\t🦠 ${red.wrap(element.name)} dont have meta data or issue in extracing metadata',
            MessageType.failure));
      });
    }

    return result;
  }
}

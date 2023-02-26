import '../../../models/step_result_message.dart';

class CodeSnippetStepResult {
  List<StepResultMessage> resultMessages = [];
  CodeSnippetStepType stepType;
  CodeSnippetStepResult({required this.stepType});

  void addMessage(StepResultMessage message) {
    resultMessages.add(message);
  }

  bool get hasWarnings {
    return resultMessages
        .any((message) => message.messageType == MessageType.warning);
  }

  bool get hasError {
    return resultMessages
        .any((message) => message.messageType == MessageType.failure);
  }

  @override
  String toString() =>
      'CodeSnippetStepResult(resultMessages: $resultMessages, stepType: $stepType)';
}

enum CodeSnippetStepType {
  extractMeta('extract'),
  validateMeta('validate');

  @override
  String toString() => friendlyName;

  final String friendlyName;
  const CodeSnippetStepType(this.friendlyName);
}

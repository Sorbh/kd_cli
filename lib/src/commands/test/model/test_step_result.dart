import '../../../models/step_result_message.dart';

class TestStepResult {
  List<StepResultMessage> resultMessages = [];
  TestStepType stepType;
  TestStepResult({required this.stepType});

  void addMessage(StepResultMessage message) {
    resultMessages.add(message);
  }

  bool get hasWarnings => resultMessages
      .any((message) => message.messageType == MessageType.warning);

  bool get hasError => resultMessages
      .any((message) => message.messageType == MessageType.failure);

  String get shortResult => resultMessages
      .where((e) => e.messageType == MessageType.short)
      .map((e) => e.message)
      .toList()
      .join(' | ');

  @override
  String toString() =>
      'TestStepResult(resultMessages: $resultMessages, stepType: $stepType)';
}

enum TestStepType {
  test('test'),
  codeCoverage('code coverage');

  @override
  String toString() => friendlyName;

  final String friendlyName;
  const TestStepType(this.friendlyName);
}

class StepResultMessage {
  String message;
  MessageType messageType;
  StepResultMessage(this.message, this.messageType);

  @override
  String toString() =>
      'StepResultMessage(message: $message, messageType: $messageType)';
}

enum MessageType {
  normal,
  failure,
  warning,
  // output,
  outputVerbose,
}

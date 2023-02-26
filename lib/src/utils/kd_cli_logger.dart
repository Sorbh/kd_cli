import 'package:mason_logger/mason_logger.dart';

// import 'package:mason/mason.dart';

class KdCliLogger extends Logger {
  // dont really know why this works but this writes over the progress log instead of next to or after
  void progressPass(String message) =>
      writeLine('''${green.wrap('✔ $message')}''');
  void progressFail(String message) =>
      writeLine('''${red.wrap('❌ $message')}''');
  void progressClear() => write(_clearLine);

  void writeLine(String? message) {
    progressClear();
    write('$message\n');
  }

  void writeRedLine(String? message) {
    progressClear();
    write('${red.wrap(message)}\n');
  }

  void writeGreenLine(String? message) {
    progressClear();
    write('${green.wrap(message)}\n');
  }

  void writeYellowLine(String? message) {
    progressClear();
    write('${lightYellow.wrap(message)}\n');
  }

  @override
  bool confirm(String? message, {bool defaultValue = false}) {
    return super.confirm('$_clearLine$message', defaultValue: defaultValue);
  }

  String get _clearLine {
    return '\u001b[2K' // clear current line
        '\r'; // bring cursor to the start of the current line
  }
}

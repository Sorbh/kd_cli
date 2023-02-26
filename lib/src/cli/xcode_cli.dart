part of 'cli.dart';

class Xcode {
  /// Check xcode version
  static Future<String> version() async {
    final ProcessResult result = await _Cmd.run('xcodebuild', ['-version']);
    return result.stdout.toString().split(' ')[1].split('\n').first.trim();
  }
}

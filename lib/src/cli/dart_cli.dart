part of 'cli.dart';

String dartPath = 'dart';

/// Dart CLI
class Dart {
  /// Determine whether dart is installed.
  static Future<bool> installed() async {
    try {
      await _Cmd.run(dartPath, ['--version']);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Apply all fixes (`dart fix --apply`).
  static Future<void> applyFixes({
    String cwd = '.',
  }) async {
    await _Cmd.run(dartPath, ['fix', '--apply'], workingDirectory: cwd);
  }
}

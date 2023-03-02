// ignore_for_file: lines_longer_than_80_chars

part of 'cli.dart';

String flutterPath = 'flutter';

/// Flutter CLI
class Flutter {
  /// Determine whether flutter is installed.
  static Future<bool> installed() async {
    try {
      await _Cmd.run(flutterPath, ['--version']);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Retrieve the flutter version
  static Future<String> version() async {
    final result = await _Cmd.run(flutterPath, ['--version']);
    return result.stdout.toString().split(' ')[1].trim();
  }

  /// Install flutter dependencies (`flutter packages get`).
  static Future<void> packagesGet({
    String cwd = '.',
    void Function([String?]) Function(String message)? progress,
  }) async {
    final installDone = progress?.call(
      'Running "flutter packages get" in $cwd',
    );
    try {
      await _Cmd.run(
        flutterPath,
        ['packages', 'get'],
        workingDirectory: cwd,
      );
    } finally {
      installDone?.call();
    }
  }

  /// Install dart dependencies (`flutter pub get`).
  static Future<ProcessResult> pubGet(
          {String cwd = '.', bool throwOnError = true}) async =>
      _Cmd.run(
        flutterPath,
        ['pub', 'get'],
        workingDirectory: cwd,
        throwOnError: throwOnError,
      );

  /// Upgrade dart dependencies (`flutter pub upgrade`).
  static Future<ProcessResult> pubUpgrade(
          // ignore: prefer_expression_function_bodies
          {String cwd = '.',
          bool throwOnError = true}) async =>
      _Cmd.run(
        flutterPath,
        ['pub', 'upgrade'],
        workingDirectory: cwd,
        throwOnError: throwOnError,
      );

  /// clean dart dependencies (`flutter clean`).
  static Future<ProcessResult> clean(
          // ignore: prefer_expression_function_bodies
          {String cwd = '.',
          bool throwOnError = true}) async =>
      _Cmd.run(
        flutterPath,
        ['clean'],
        workingDirectory: cwd,
        throwOnError: throwOnError,
      );

  /// analyze flutter project (`flutter analyze`).
  static Future<ProcessResult> analyze(
          // ignore: prefer_expression_function_bodies
          {String cwd = '.',
          bool throwOnError = true}) async =>
      _Cmd.run(
        flutterPath,
        ['analyze'],
        workingDirectory: cwd,
        throwOnError: throwOnError,
      );

  /// run build_runner build (`flutter pub run build_runner build --delete-conflicting-outputs`).
  static Future<void> pubBuildRunner({String cwd = '.'}) async {
    await _Cmd.run(
      flutterPath,
      ['pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      workingDirectory: cwd,
    );
  }

  /// run flutter test coverage (`flutter test --coverage`).
  /// `flutter test --machine > report.log --coverage`
  static Future<ProcessResult> testCoverage({
    String cwd = '.',
    bool throwOnError = true,
    // ignore: prefer_expression_function_bodies
  }) async {
    return _Cmd.run(
      flutterPath,
      ['test', '--machine', '--coverage', '-j', '12', '--no-pub'],
      workingDirectory: cwd,
      throwOnError: throwOnError,
    );
  }

  /// run flutter test (`flutter test`).
  static Future<ProcessResult> test({
    String cwd = '.',
    bool throwOnError = true,
  }) async =>
      _Cmd.run(
        flutterPath,
        ['test', '-j', '12', '--no-pub'],
        workingDirectory: cwd,
        throwOnError: throwOnError,
      );
}

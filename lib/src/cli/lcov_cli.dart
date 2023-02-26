part of 'cli.dart';

/// Lcov CLI
class Lcov {
  /// Windows uses perl to run the lcov command (which is located through the LCOV_HOME environment variable).
  /// MacOS is able to run the lcov command natively.
  static String get _lcovCommand => Platform.isWindows
      ? 'perl ${join(Platform.environment['LCOV_HOME']!, 'bin', 'lcov')}'
      : 'lcov';

  /// Windows uses perl to run the lcov command (which is located through the LCOV_HOME environment variable).
  /// MacOS is able to run the lcov command natively.
  static String get _genhtmlCommand => Platform.isWindows
      ? 'perl ${join(Platform.environment['LCOV_HOME']!, 'bin', 'genhtml')}'
      : 'genhtml';

  static String get _openCommand => Platform.isWindows ? 'start' : 'open';

  /// Determine whether flutter is installed.
  static Future<bool> installed() async {
    try {
      await _Cmd.run(_lcovCommand, ['--version']);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Remove generated lcov files
  /// 'lcov --remove coverage/lcov.info '**/*.freezed.dart' '**/*.g.dart' 'lib/app/app.*.dart' -o coverage/lcov.info'
  static Future<void> removeGeneratedDartFiles({
    String cwd = '.',
    String outputDir = '.',
    String infoFileDir = 'lcov.info',
  }) async {
    await _Cmd.run(
      _lcovCommand,
      [
        '--remove',
        infoFileDir,
        '**/*.freezed.dart',
        '**/*.gr.dart',
        '**/*.g.dart',
        'lib/app/app.*.dart',
        '-o',
        outputDir,
      ],
      workingDirectory: cwd,
    );
  }

  /// Extract Bloc coverage.
  /// lcov --extract coverage/lcov.info '**/*cubit.dart' '**/*bloc.dart' -o coverage/bloc_lcov.info
  static Future<void> extractBlocTest({
    String cwd = '.',
    String outputDir = '.',
    String infoFileDir = 'lcov.info',
  }) async {
    await _Cmd.run(
      _lcovCommand,
      [
        '-e',
        infoFileDir,
        '**/*cubit.dart',
        '**/*bloc.dart',
        '-o',
        outputDir,
      ],
      workingDirectory: cwd,
    );
  }

  /// Extract Service coverage.
  /// lcov --extract coverage/lcov.info '**/*service.dart' -o coverage/bloc_lcov.info
  static Future<void> extractServiceTest({
    String cwd = '.',
    String outputDir = '.',
    String infoFileDir = 'lcov.info',
  }) async {
    await _Cmd.run(
      _lcovCommand,
      [
        '-e',
        infoFileDir,
        '**/*service.dart',
        '-o',
        outputDir,
      ],
      workingDirectory: cwd,
    );
  }

  /// Generate html of coverage
  /// genhtml -o coverage/full coverage/lcov.info
  static Future<void> generateHtml({
    String cwd = '.',
    String outputDir = '.',
    String infoFileDir = 'lcov.info',
    String? title,
  }) async {
    await _Cmd.run(
      _genhtmlCommand,
      [
        '-o',
        outputDir,
        infoFileDir,
        if (title != null) '-t',
        if (title != null) title,
      ],
      workingDirectory: cwd,
    );
  }

  static Future<void> openHtml({
    String cwd = '.',
    String htmlName = 'index.html',
  }) async {
    await _Cmd.run(
      _openCommand,
      [htmlName],
      workingDirectory: cwd,
    );
  }

  static Future<String> generateSummary({
    String cwd = '.',
    String infoFileDir = 'lcov.info',
  }) async {
    final result = await _Cmd.run(
      _lcovCommand,
      [
        '--summary',
        infoFileDir,
      ],
      workingDirectory: cwd,
    );
    return result.stdout.toString();
  }
}

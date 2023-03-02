import 'package:args/command_runner.dart';
import 'package:kd_cli/src/commands/code_snippet/code_snippet_command.dart';
import 'package:kd_cli/src/commands/packages/packages_command.dart';
import 'package:kd_cli/src/commands/test/test_command.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template msi_command_runner}
/// A [CommandRunner] for the Kd CLI.
/// {@endtemplate}
class KdCommandRunner extends CommandRunner<int> {
  /// Standard timeout duration for the CLI.
  static const timeout = Duration(milliseconds: 500);

  final Logger _logger;
  KdCommandRunner({
    Logger? logger,
  })  : _logger = logger ?? Logger(),
        super('kd', '🐳 A Kd Command Line Interface') {
    addCommand(TestCommand());
    addCommand(CodeSnippetCommand());
    addCommand(PackagesCommand());
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final argResults = parse(args);
      return await runCommand(argResults) ?? ExitCode.success.code;
    } on FormatException catch (e, stackTrace) {
      _logger
        ..err(e.message)
        ..err('$stackTrace')
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);
      return ExitCode.usage.code;
    }
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:kd_cli/src/commands/code_snippet/model/code_snippet_step_result.dart';
import 'package:kd_cli/src/commands/code_snippet/model/code_snippet_summary.dart';
import 'package:kd_cli/src/models/code_snippet.dart';
import 'package:kd_cli/src/models/step_result_message.dart';
import 'package:kd_cli/src/utils/kd_cli_logger.dart';
import 'package:kd_cli/src/utils/workspace_util.dart';
import 'package:mason_logger/mason_logger.dart';

part 'step/extract_metadata_step.dart';
part 'step/validating_metadata_step.dart';

class CodeSnippetCommand extends Command<int> {
  CodeSnippetCommand({
    KdCliLogger? logger,
  }) : logger = logger ?? KdCliLogger() {
    // argParser
    //   ..addFlag(TestArguments.all,
    //       defaultsTo: true,
    //       negatable: true,
    //       help:
    //           'Set this flag to enable option to choose the package before testing')
    //   ..addFlag(TestArguments.clean,
    //       defaultsTo: false,
    //       negatable: true,
    //       abbr: 'c',
    //       help: 'Clean all the old icov.info file');
  }

  final KdCliLogger logger;

  @override
  String get description => 'Run the code snipper command.';

  @override
  String get summary => '$invocation\n$description';

  @override
  String get name => 'codesnippet';

  @override
  String get invocation => 'kd codesnippet ';

  @override
  Future<int> run() async {
    bool verbose = false;
    Progress progressLog =
        logger.progress('Scanning WorkSpece for CodeSnippet');

    final codeSnippets = await WorkspaceUtil.findCodeSnippetInWorkSpace();

    if (codeSnippets.isEmpty) {
      progressLog.fail('No code snippet found in the workspace');
      return ExitCode.tempFail.code;
    }
    progressLog
        .complete('${codeSnippets.length} code snippet found in the workspace');

    final codeSnippetSummary = CodeSnippetSummary('Code Snippet');

    // Step - 1
    // Extract metadata from code snippet
    codeSnippetSummary
        .addStepResult(await ExtractMetadataStep.extractMetadata(codeSnippets));

    // Step - 2
    // Validate metadata from code snippet
    codeSnippetSummary.addStepResult(
        await ValidateMetadataStep.validateMetadata(codeSnippets));

    ///Generate detailed report
    progressLog = logger.progress('\nGenerating Report');

    ///Generate Short Summery for test
    logger.success('\nCode Snippet Short Summery');

    if (codeSnippetSummary.hasErrors) {
      logger.writeLine('');
      logger.err('❌ Issue found with Code Snippet ❌');
      logger.info(
          '❌ Following have steps have error -> ${codeSnippetSummary.failedSteps.join(',')}');
      codeSnippetSummary.errors.forEach((step) {
        logger.writeLine('');
        _logResultMessages(step, verbose);
      });
    } else {
      logger
          .success('All Good with the Code Snippet, All Step passed 👏🏻👏🏻');
    }
    progressLog.complete();

    return ExitCode.success.code;
  }

  void _logResultMessages(CodeSnippetStepResult stepResults, bool verbose) {
    for (final resultMessage in stepResults.resultMessages) {
      switch (resultMessage.messageType) {
        case MessageType.normal:
          logger.writeLine(resultMessage.message);
          break;
        case MessageType.warning:
          logger.writeLine('⚠️ ${resultMessage.message}');
          break;
        case MessageType.failure:
          logger.writeLine(resultMessage.message);
          break;
        case MessageType.outputVerbose:
          if (verbose) logger.writeLine(resultMessage.message);
          break;

        default:
          if (verbose) logger.writeLine(resultMessage.message);
          break;
      }
    }
  }
}

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:kd_cli/src/utils/workspace_util.dart';
import 'package:mason_logger/mason_logger.dart';

class PackagesCommand extends Command<int> {
  PackagesCommand({
    Logger? logger,
  }) : logger = logger ?? Logger();

  final Logger logger;

  @override
  String get description => 'List down all the packages in the workspace';

  @override
  String get summary => '$invocation\n$description';

  @override
  String get name => 'packages';

  @override
  String get invocation => 'kd packages';

  @override
  Future<int> run() async {
    Progress stepProgressLog;

    logger.info('Loading workspace packages');
    stepProgressLog = logger.progress('Scaning workspace');
    final allPackages = await WorkspaceUtil.findMonoRepoPackages();
    stepProgressLog.complete();

    logger.info('Package List');
    logger.info(allPackages.map((e) => e.logNameWithPath()).join('\n'));
    logger.info('\n');

    stepProgressLog.complete();

    return ExitCode.success.code;
  }
}

import 'package:args/args.dart';
import 'package:kd_cli/src/commands/test/constants/test_arguments.dart';

class TestOptions {
  bool all;
  bool skipCoverage;

  TestOptions({
    required this.all,
    required this.skipCoverage,
  });

  factory TestOptions.fromArgs(ArgResults argResults) {
    final bool all = argResults[TestArguments.all] as bool;
    final bool skipCoverage = argResults[TestArguments.skipCoverage] as bool;
    return TestOptions(all: all, skipCoverage: skipCoverage);
  }
  // factory TestOptions.fromMap(Map<String, dynamic> argResults) {
  //   final bool all = argResults[TestArguments.all] as bool;
  //   return TestOptions(
  //     all: all,
  //   );
  // }
}

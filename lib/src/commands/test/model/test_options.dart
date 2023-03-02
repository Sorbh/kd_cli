import 'package:args/args.dart';

abstract class TestArguments {
  static const String packages = 'packages';
  static const String choosePackage = 'choose-package';
  static const String doClean = 'do-clean';
  static const String pubUpdate = 'pub-update';
  static const String skipCoverage = 'skip-coverage';
  static const String fullReport = 'full-report';
  static const String exportReport = 'export-report';
  static const String showProgress = 'show-progress';
}

class TestOptions {
  List<String> packages;
  bool choosePackage;
  bool doClean;
  bool pubUpdate;
  bool skipCoverage;
  bool fullReport;
  bool exportReport;
  bool showProgress;

  TestOptions({
    required this.packages,
    required this.choosePackage,
    required this.doClean,
    required this.pubUpdate,
    required this.skipCoverage,
    required this.fullReport,
    required this.exportReport,
    required this.showProgress,
  });

  factory TestOptions.fromArgs(ArgResults argResults) => TestOptions(
        packages: argResults[TestArguments.packages] as List<String>,
        choosePackage: argResults[TestArguments.choosePackage] as bool,
        doClean: argResults[TestArguments.doClean] as bool,
        pubUpdate: argResults[TestArguments.pubUpdate] as bool,
        skipCoverage: argResults[TestArguments.skipCoverage] as bool,
        fullReport: argResults[TestArguments.fullReport] as bool,
        exportReport: argResults[TestArguments.exportReport] as bool,
        showProgress: argResults[TestArguments.showProgress] as bool,
      );
}

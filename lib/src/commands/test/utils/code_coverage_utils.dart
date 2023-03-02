// ignore_for_file: lines_longer_than_80_chars

part of '../test_command.dart';

abstract class CodeCoverageUtils {
  /// Generate a coverage helper since currently `flutter test coverage` wont check coverage for any files that aren't
  /// tested. https://github.com/flutter/flutter/issues/27997
  static Future<StepResultMessage> generateCoverageHelper(
      PackageInfo package) async {
    try {
      final libDir = Directory(join(package.parent, 'lib'));
      final buffer = StringBuffer();

      final files = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) =>
              file.path.endsWith('.dart') &&
              !file.path.contains('.freezed.') &&
              !file.path.contains('.g.') &&
              !file.path.contains('.gr.') &&
              !file.path.contains('.event.') &&
              !file.path.contains('.state.') &&
              !file.path.contains('.config.') &&
              !file.path.endsWith('generated_plugin_registrant.dart') &&
              !file.readAsLinesSync().any((line) => line.startsWith('part of')))
          .toList();

      buffer.writeln('// ignore_for_file: unused_import');
      buffer.writeln();

      for (final file in files) {
        final fileLibPath =
            file.uri.toFilePath().substring(libDir.uri.toFilePath().length);
        buffer.writeln(
            'import \'package:${package.name}/${_normalizeImportSlashes(fileLibPath)}\';');
      }

      buffer.writeln();
      buffer.writeln('void main() {}');
      buffer.writeln();

      final file =
          File(join(package.parent, 'test', 'coverage_helper_test.dart'));
      file.createSync(recursive: true);
      await file.writeAsString(buffer.toString());
      return StepResultMessage(
          'All Test File Created Successfully -> ${file.path}',
          MessageType.outputVerbose);
    } catch (error) {
      return StepResultMessage(
          'All Test File Create Faild -> ${error.toString()}',
          MessageType.failure);
    }
  }

  static Future<void> deleteCoverageHelper(PackageInfo package) async {
    if (FileUtil.fileExists(
        join(package.parent, 'test', 'coverage_helper_test.dart'))) {
      File(join(package.parent, 'test', 'coverage_helper_test.dart'))
          .deleteSync();
      //Check if test folder is emtpry delete is as well.
      if (Directory(join(package.parent, 'test'))
          .listSync(recursive: true)
          .isEmpty) {
        Directory(join(package.parent, 'test')).deleteSync(recursive: true);
      }
    }
  }

  static Future<void> createMasterCoverageFile([String cwd = '.']) async {
    final file = File(join(cwd, 'coverage_master', 'lcov.info'));
    if (file.existsSync()) file.deleteSync(recursive: true);
    file.createSync(recursive: true);
  }

  static Future<void> appendToMasterFile(PackageInfo packageInfo,
      {String cwd = '.', bool deletelcov = true}) async {
    final file = File(join(cwd, 'coverage_master', 'lcov.info'));
    file.createSync(recursive: true);

    final lcovFile = File(join(packageInfo.parent, 'coverage', 'lcov.info'));
    final lcovContent = lcovFile.readAsStringSync();

    file.writeAsStringSync(
        lcovContent.replaceAll('SF:', 'SF:${packageInfo.parent}/'),
        mode: FileMode.append);

    //Delete Origin lcov fle
    if (deletelcov) lcovFile.parent.deleteSync(recursive: true);
  }

  static Future<void> copyMasterLcovToCoverage([String cwd = '.']) async {
    final masterLcovFile = File(join(cwd, 'coverage_master', 'lcov.info'));
    final lcovFile = File(join(cwd, 'coverage', 'lcov.info'));
    lcovFile.createSync(recursive: true);
    masterLcovFile.copySync(join(cwd, 'coverage', 'lcov.info'));
    if (masterLcovFile.existsSync()) {
      masterLcovFile.parent.deleteSync(recursive: true);
    }
  }

  static String _normalizeImportSlashes(String filePath) {
    if (Platform.isWindows) {
      // Replace backslashes with forward slashes which is what dart uses for import statements.
      return filePath.replaceAll(r'\', '/');
    } else {
      return filePath;
    }
  }

//   static Future<AnalyzeStepResult> generateCoverageReport({
//     required Package package,
//     required bool openCoverageOnFail,
//     required CoverageLimits coverageLimits,
//   }) async {
//     final result = AnalyzeStepResult(stepType: AnalyzeStepType.codeCoverage);
//     final String coveragePath = p.join(package.path, 'coverage');
//     await Lcov.removeGeneratedDartFiles(
//       outputDir: 'lcov_no_gen.info',
//       infoFileDir: 'lcov.info',
//       cwd: coveragePath,
//     );

//     await Lcov.extractBlocTest(
//       outputDir: 'bloc_lcov.info',
//       infoFileDir: 'lcov_no_gen.info',
//       cwd: coveragePath,
//     );

//     await _checkFileCoverage(
//       package: package,
//       fileType: _FileType.bloc,
//       coverageLimit: coverageLimits.bloc,
//       result: result,
//       messageTypeOnFail: MessageType.failure,
//       openCoverageOnFail: openCoverageOnFail,
//     );

//     await Lcov.extractServiceTest(
//       outputDir: 'service_lcov.info',
//       infoFileDir: 'lcov_no_gen.info',
//       cwd: coveragePath,
//     );

//     await _checkFileCoverage(
//       package: package,
//       fileType: _FileType.service,
//       coverageLimit: coverageLimits.service,
//       result: result,
//       messageTypeOnFail: MessageType.warning,
//       openCoverageOnFail: false,
//     );

//     return result;
//   }

  static Future<double> checkLcovReport(
    PackageInfo package,
  ) async {
    final file = File(join(package.parent, 'coverage', 'lcov.info'));

    if (await file.exists() && await file.length() != 0) {
      final coverage = await Lcov.generateSummary(
        cwd: file.parent.path,
      );

      final regexp = RegExp(r'\d*[,]?\d*\.\d+[%]?');

      if (regexp.hasMatch(coverage)) {
        final match = regexp.firstMatch(coverage)?.group(0);
        final numberString = match!.replaceAll('%', '');

        final coverageTotal = double.parse(numberString);
        return coverageTotal;
      }
    }
    return -1;
  }

//   static Future<void> openCoverageHtml(
//       Package package, String fileTypeString) async {
//     await Lcov.generateHtml(
//         cwd: package.path,
//         outputDir: p.join('coverage', '${fileTypeString}_report'),
//         infoFileDir: p.join('coverage', '${fileTypeString}_lcov.info'),
//         title: package.name);
//     await Lcov.openHtml(
//         cwd: p.join(package.path, 'coverage', '${fileTypeString}_report'));
//   }
}

// enum _FileType {
//   bloc,
//   service,
// }

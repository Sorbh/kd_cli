// ignore_for_file: avoid_dynamic_calls, unnecessary_overrides

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

import '../../../models/package_info.dart';

// ignore: avoid_classes_with_only_static_members
class TestReportUtils {
  static Future<TestReport> parseReportFile(PackageInfo package) async {
    final tests = <TestModel>[];
    tests.addAll(await _TestReporParser()
        .parseFile(join(package.parent, 'test_report.log')));
    return TestReport(package.name, tests);
  }

  static Future<TestReport> parseReport(
      PackageInfo package, String reportString) async {
    final tests = <TestModel>[];
    tests.addAll(await _TestReporParser().parseString(reportString));
    return TestReport(package.name, tests);
  }

  static void deleteReportFile(PackageInfo package) {
    File(join(package.parent, 'test_report.log')).deleteSync();
  }
}

class _TestReporParser {
  Map<int, TestModel> tests = {};

  Future<List<TestModel>> parseFile(String path) async {
    await File(path)
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach(_parseLine);

    return tests.values.toList();
  }

  Future<List<TestModel>> parseString(String report) async {
    const LineSplitter().convert(report).forEach(_parseLine);
    return tests.values.toList();
  }

  void _parseLine(String jsonString) {
    late Map<String, dynamic> line;
    try {
      line = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return;
    }

    if (line.containsKey('type')) {
      _parseTestStart(line);
      _parseTestError(line);
      _parseTestMessage(line);
      _parseTestDone(line);
    }
  }

  void _parseTestStart(Map<String, dynamic> line) {
    if (line['type'] == 'testStart') {
      final id = int.parse(line['test']['id'].toString());
      final name = line['test']['name'].toString();
      final url = line['test']['url'].toString();

      if (name.startsWith('loading /')) {
        return;
      }

      final model = tests.putIfAbsent(id, TestModel.new);
      model.id = id;
      model.name = name;
      model.url = url;
      if (line['test']['metadata']['skip'] as bool) {
        model.state = State.skipped;
      }
    }
  }

  void _parseTestError(Map<String, dynamic> line) {
    if (line['type'] == 'error') {
      final id = line['testID'];
      final error = line['error'].toString();

      final model = tests[id];
      if (model != null) {
        if (!error.startsWith('Test failed. See exception logs above.')) {
          model.error = error.endsWith('\n') ? '\t$error' : '\t$error\n';
        }
      }
    }
  }

  void _parseTestMessage(Map<String, dynamic> line) {
    if (line['type'] == 'print') {
      final id = int.parse(line['testID'].toString());
      final message = line['message'].toString();

      final model = tests[id];
      if (model != null) {
        model.message = '\t$message\n';
      }
    }
  }

  void _parseTestDone(Map<String, dynamic> line) {
    if (line['type'] == 'testDone') {
      final id = line['testID'];

      final model = tests[id];
      if (model != null && model.state == null) {
        model.state =
            line['result'] == 'success' ? State.success : State.failure;
      }
    }
  }
}

class TestReport {
  final String name;
  final List<TestModel> tests;

  TestReport(this.name, this.tests);

  bool get haveFailedTest =>
      tests.any((element) => element.state == State.failure);

  bool get haveSkippedTest =>
      tests.any((element) => element.state == State.skipped);

  int get passedTestCount =>
      tests.where((element) => element.state == State.success).toList().length;

  int get failedTestCount =>
      tests.where((element) => element.state == State.failure).toList().length;

  int get skippedTestCount =>
      tests.where((element) => element.state == State.skipped).toList().length;

  List<TestModel> get failedTest =>
      tests.where((element) => element.state == State.failure).toList();

  List<TestModel> get skippedTest =>
      tests.where((element) => element.state == State.skipped).toList();
}

enum State {
  success,
  skipped,
  failure,
}

class TestModel {
  int? id;
  String? name;
  String? url;
  String? error;
  String? message;
  State? state;

  @override
  bool operator ==(dynamic other) {
    if (other is TestModel) {
      return id == other.id &&
          name == other.name &&
          url == other.url &&
          error == other.error &&
          message == other.message &&
          state == other.state;
    }
    return false;
  }

  @override
  String toString() => 'TestModel { $id $state $name $error $message }';

  @override
  int get hashCode => super.hashCode;
}

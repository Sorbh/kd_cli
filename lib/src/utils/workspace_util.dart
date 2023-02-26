import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:kd_cli/src/models/code_snippet.dart';
import 'package:kd_cli/src/models/package_info.dart';
import 'package:path/path.dart';
import 'package:pubspec/pubspec.dart';

abstract class WorkspaceUtil {
  static Future<List<PackageInfo>> findMonoRepoPackages(
      {String workspacePath = '.'}) async {
    final dartToolGlob = Glob('**.dart_tool**');
    // Flutter symlinked plugins for iOS/macOS should not be included in the package list.
    final symlinksPluginsGlob = Glob('**.symlinks/plugins**');
    // Flutter version manager should not be included in the package list.
    final fvmGlob = Glob('**.fvm**');
    // Ephemeral plugin symlinked packages should not be included in the package
    // list.
    final pluginSymlinksGlob = Glob('**.plugin_symlinks**');

    final pubspecGlob = Glob('**pubspec.yaml', recursive: true);

    final allPackages = <PackageInfo>[];
    for (var entity in pubspecGlob
        .listSync(root: workspacePath)
        .where((value) => !(dartToolGlob.matches(value.path) ||
            fvmGlob.matches(value.path) ||
            pluginSymlinksGlob.matches(value.path) ||
            symlinksPluginsGlob.matches(value.path)))
        .toList()) {
      var pubSpec = await PubSpec.load(entity.parent);
      allPackages
          .add(PackageInfo(pubSpec.name!, entity.path, entity.parent.path));
    }
    return allPackages;
  }

  static Future<List<CodeSnippet>> findCodeSnippetInWorkSpace(
      {String workspacePath = '.'}) async {
    final dartCodeSnippetFile = Glob('**.dart');

    final codeSnippets = <CodeSnippet>[];

    for (var entity in dartCodeSnippetFile.listSync(root: workspacePath)) {
      final pattern = RegExp(r'\* end_sample_code \*');
      final codeSnippetFile = File(entity.path);
      final codeSnippetString = codeSnippetFile.readAsStringSync();
      if (pattern.hasMatch(codeSnippetString)) {
        codeSnippets.add(CodeSnippet(basename(codeSnippetFile.path),
            codeSnippetFile.path, codeSnippetString));
      }
    }
    return codeSnippets;
  }
}

class CodeSnippet {
  final String name;
  final String filePath;
  final String content;

  CodeSnippet(this.name, this.filePath, this.content);

  final metaDataMap = <String, String>{};
  String? codeString;

  bool get haveValidMeta => !MetaData.values
      .map((e) => e.name)
      .any((element) => !metaDataMap.keys.contains(element));

  List<String> get missingMeta => MetaData.values
      .map((e) => e.name)
      .where((element) => !metaDataMap.keys.contains(element))
      .toList();

  @override
  bool operator ==(dynamic other) {
    if (other is CodeSnippet) {
      return name == other.name &&
              metaDataMap[MetaData.gist_id.name] ==
                  other.metaDataMap[MetaData.gist_id.name] ||
          metaDataMap[MetaData.filename.name] ==
              other.metaDataMap[MetaData.filename.name] ||
          metaDataMap[MetaData.description.name] ==
              other.metaDataMap[MetaData.description.name];
    }
    return false;
  }

  List<String> haveIssueWithProperties(dynamic other) {
    if (other is CodeSnippet) {
      final issue = <String>[];
      if (name == other.name) issue.add('Name');
      if (metaDataMap[MetaData.gist_id.name] ==
          other.metaDataMap[MetaData.gist_id.name]) issue.add('Gist Id');
      if (metaDataMap[MetaData.filename.name] ==
          other.metaDataMap[MetaData.filename.name]) issue.add('File name');
      if (metaDataMap[MetaData.description.name] ==
          other.metaDataMap[MetaData.description.name])
        issue.add('Description');

      return issue;
    }
    return [];
  }
}

// ignore: constant_identifier_names
enum MetaData { gist_id, filename, description }

import 'package:mason_logger/mason_logger.dart';

class PackageInfo {
  final String name;
  final String path;
  final String parent;

  PackageInfo(this.name, this.path, this.parent);

  String logNameWithPath() => '\t${yellow.wrap(name)}\n\t\t↳$parent';
}

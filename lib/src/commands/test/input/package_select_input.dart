import 'package:kd_cli/src/models/package_info.dart';
import 'package:kd_cli/src/utils/kd_cli_logger.dart';

/// Class handle all the user input for package selection
abstract class PackageSelectInput {
  /// Ask user to select the package name
  static List<PackageInfo> promptForPackageSelect(
      KdCliLogger logger, List<PackageInfo> packages) {
    return logger.chooseAny(
      'Please select package to test',
      choices: packages,
      defaultValues: [packages.first],
      // defaultValue: [packages.first],
      display: (choice) => choice.name,
    );
  }
}

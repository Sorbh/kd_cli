import 'package:kd_cli/src/models/package_info.dart';
import 'package:mason_logger/mason_logger.dart';

/// Class handle all the user input for package selection
abstract class PackageSelectInput {
  /// Ask user to select the package name
  static List<PackageInfo> promptForPackageSelect(
          Logger logger, List<PackageInfo> packages) =>
      logger.chooseAny(
        'Please select package to test',
        choices: packages,
        defaultValues: [packages.first],
        // defaultValue: [packages.first],
        display: (choice) => choice.name,
      );
}

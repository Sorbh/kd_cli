// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:pool/pool.dart';

/// The pool used for restricting access to asynchronous operations that consume
/// file descriptors.
///
/// The maximum number of allocated descriptors is based on empirical tests that
/// indicate that beyond 32, additional file reads don't provide substantial
/// additional throughput.
final _descriptorPool = Pool(32);

abstract class FileUtil {
  /// Returns whether [file] exists on the file system.
  ///
  /// This returns `true` for a symlink only if that symlink is unbroken and
  /// points to a file.
  static bool fileExists(String file) => File(file).existsSync();

  /// Reads the contents of the text file [file].
  static Future<String> readTextFileAsync(String file) =>
      _descriptorPool.withResource(() => File(file).readAsString());
}

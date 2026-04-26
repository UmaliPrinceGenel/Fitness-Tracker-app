import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('rockies_fitness/asset_copy');

/// Copies a Flutter asset to a file on disk using a platform channel that
/// streams the data in small chunks (64 KB) instead of loading the entire
/// file into the Dart heap via [rootBundle.load].
///
/// This is essential for large assets like the bundled GGUF model (~84 MB)
/// because [rootBundle.load] would allocate the full file size in Dart memory,
/// which can trigger the OOM killer on devices with limited RAM.
///
/// Returns `true` if the copy succeeded, `false` otherwise.
Future<bool> copyAssetToFile({
  required String assetKey,
  required String destPath,
}) async {
  try {
    final result = await _channel.invokeMethod<bool>(
      'copyAssetToFile',
      <String, String>{
        'assetKey': assetKey,
        'destPath': destPath,
      },
    );
    return result == true;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:masterfabric_core/masterfabric_core.dart';

/// Go API base URL.
/// Prefers flavor config (`assets/config/app_config_*.json`) →
/// `apiConfiguration.baseUrl` when set.
String defaultApiBaseUrl() {
  try {
    final fromConfig = AssetConfigHelper().getString(
      'apiConfiguration.baseUrl',
      '',
    );
    if (fromConfig.trim().isNotEmpty) {
      // Android emulator cannot use host localhost in config as-is.
      if (!kIsWeb && Platform.isAndroid && fromConfig.contains('localhost')) {
        return fromConfig.replaceAll('localhost', '10.0.2.2');
      }
      return fromConfig;
    }
  } catch (_) {}

  if (kIsWeb) return 'http://localhost:8080';
  try {
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
  } catch (_) {}
  return 'http://127.0.0.1:8080';
}

import 'package:flutter/material.dart';
import 'package:masterfabric_core/masterfabric_core.dart';
import 'package:navgo_mobile/app/app.dart';
import 'package:navgo_mobile/app/routes.dart';
import 'package:navgo_mobile/data/session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build flavors for NavGo mobile.
enum AppFlavor {
  dev,
  prod;

  String get assetConfigPath => switch (this) {
        AppFlavor.dev => 'assets/config/app_config_dev.json',
        AppFlavor.prod => 'assets/config/app_config_prod.json',
      };

  String get displayName => switch (this) {
        AppFlavor.dev => 'NavGo Dev',
        AppFlavor.prod => 'NavGo',
      };
}

Future<void> startApp(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  await MasterApp.runBefore(
    assetConfigPath: flavor.assetConfigPath,
    hydrated: false,
    requestTrackingTransparency: false,
    networkFeatures: const {},
    runBeforeFeatures: const {},
  );

  await configureSystemUi();

  final prefs = await SharedPreferences.getInstance();
  final session = SessionRepository(prefs);
  final router = NavGoRoutes.createRouter(session);

  runApp(App(router: router, title: flavor.displayName));
}

import 'package:flutter/material.dart';
import 'package:masterfabric_core/masterfabric_core.dart'
    hide AppLocale, AppLocaleUtils, LocaleSettings, TranslationProvider;
import 'package:navgo_mobile/app/app.dart';
import 'package:navgo_mobile/app/routes.dart';
import 'package:navgo_mobile/data/session_repository.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build flavors for NavGo mobile.
enum AppFlavor {
  dev,
  prod;

  String get assetConfigPath => switch (this) {
        AppFlavor.dev => 'assets/config/app_config_dev.json',
        AppFlavor.prod => 'assets/config/app_config_prod.json',
      };

  String get displayName => 'NavGo';
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
  await _applyStoredLocale(session);

  final router = NavGoRoutes.createRouter(session);

  runApp(
    TranslationProvider(
      child: App(router: router, title: flavor.displayName),
    ),
  );
}

Future<void> _applyStoredLocale(SessionRepository session) async {
  final stored = session.localeCode;
  final match = AppLocale.values.where((l) => l.languageCode == stored);
  if (match.isNotEmpty) {
    await LocaleSettings.setLocale(match.first);
    return;
  }
  await LocaleSettings.useDeviceLocale();
}

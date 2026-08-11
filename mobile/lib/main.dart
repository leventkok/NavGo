import 'package:flutter/material.dart';
import 'package:masterfabric_core/masterfabric_core.dart';
import 'package:navgo_mobile/app/app.dart';
import 'package:navgo_mobile/app/routes.dart';
import 'package:navgo_mobile/data/session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MasterApp.runBefore(
    assetConfigPath: 'assets/app_config.json',
    hydrated: false,
    requestTrackingTransparency: false,
    networkFeatures: const {},
    runBeforeFeatures: const {},
  );

  await configureSystemUi();

  final prefs = await SharedPreferences.getInstance();
  final session = SessionRepository(prefs);
  final router = NavGoRoutes.createRouter(session);

  runApp(App(router: router));
}

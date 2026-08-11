import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:masterfabric_core/masterfabric_core.dart';
import 'package:navgo_mobile/core/themes/app_theme_light.dart';

/// Product shell: MasterFabric bootstrap + NavGo theme.
class App extends StatelessWidget {
  const App({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NavGo',
      debugShowCheckedModeBanner: false,
      theme: navGoThemeLight,
      themeMode: ThemeMode.light,
      routerConfig: router,
      scaffoldMessengerKey: MasterApp.messengerKey,
    );
  }
}

Future<void> configureSystemUi() async {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
}

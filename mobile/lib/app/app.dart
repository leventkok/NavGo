import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:masterfabric_core/masterfabric_core.dart';
import 'package:navgo_mobile/core/themes/app_theme_light.dart';

/// Product shell: MasterFabric bootstrap + NavGo theme.
///
/// `masterfabric_core` 1.0 `MasterApp` hardcodes ThemeData; we keep NavGo
/// Material theme and still initialize core via [MasterApp.runBefore].
class App extends StatelessWidget {
  const App({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp.router(
      title: 'NavGo',
      debugShowCheckedModeBanner: false,
      theme: appThemeLight(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      scaffoldMessengerKey: MasterApp.messengerKey,
    );
  }
}

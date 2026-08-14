import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:masterfabric_core/masterfabric_core.dart'
    hide AppLocale, AppLocaleUtils, LocaleSettings, TranslationProvider;
import 'package:navgo_mobile/core/themes/app_theme_light.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';

/// Product shell: MasterFabric bootstrap + NavGo theme + i18n.
class App extends StatelessWidget {
  const App({super.key, required this.router, this.title = 'NavGo'});

  final GoRouter router;
  final String title;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: navGoThemeLight,
      themeMode: ThemeMode.light,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/data/session_repository.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key, required this.session});

  final SessionRepository session;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (widget.session.onboardingComplete) {
      context.go('/plan');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('NavGo', style: context.textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'Grounded day plans',
              style: context.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

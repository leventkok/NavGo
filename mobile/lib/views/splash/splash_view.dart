import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/core/widgets/primary_button.dart';
import 'package:navgo_mobile/data/session_repository.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key, required this.session});

  final SessionRepository session;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  var _navigated = false;
  var _showContinue = false;
  Timer? _failsafeTimer;

  @override
  void initState() {
    super.initState();
    // Navigate on first frame — delayed timers can starve under emulator jank
    // and leave the splash spinner looking "frozen".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goNext();
      _failsafeTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted || _navigated) return;
        setState(() => _showContinue = true);
        _goNext();
      });
    });
  }

  @override
  void dispose() {
    _failsafeTimer?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final next = widget.session.onboardingComplete
        ? '/plan'
        : '/onboarding';
    debugPrint('Splash → $next');
    try {
      GoRouter.of(context).go(next);
    } catch (e, st) {
      debugPrint('Splash navigate failed: $e\n$st');
      _navigated = false;
      if (mounted) setState(() => _showContinue = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  t.common.brand,
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  t.splash.tagline,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.neutral,
                  ),
                ),
                const SizedBox(height: 28),
                if (_showContinue)
                  PrimaryButton(
                    label: t.splash.continueAction,
                    onPressed: _goNext,
                  )
                else
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/core/widgets/primary_button.dart';
import 'package:navgo_mobile/data/session_repository.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key, required this.session});

  final SessionRepository session;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  var _navigated = false;
  var _showContinue = false;
  Timer? _bootTimer;
  Timer? _failsafeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootTimer = Timer(const Duration(milliseconds: 600), _goNext);
      _failsafeTimer = Timer(const Duration(milliseconds: 1800), () {
        if (!mounted || _navigated) return;
        setState(() => _showContinue = true);
        // One more automatic attempt if the first schedule was starved.
        _goNext();
      });
    });
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
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
                  'NavGo',
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Grounded day plans',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.neutral,
                  ),
                ),
                const SizedBox(height: 28),
                if (_showContinue)
                  PrimaryButton(
                    label: 'Devam',
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

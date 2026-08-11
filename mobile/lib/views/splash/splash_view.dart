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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text('NavGo', style: context.textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Grounded day plans',
                style: context.textTheme.bodyMedium,
              ),
              const Spacer(),
              if (_showContinue)
                PrimaryButton(
                  label: 'Devam',
                  onPressed: _goNext,
                )
              else
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

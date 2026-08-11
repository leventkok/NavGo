import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navgo_mobile/core/constants/api_constants.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/core/widgets/primary_button.dart';
import 'package:navgo_mobile/data/session_repository.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key, required this.session});

  final SessionRepository session;

  static const _tempoLabels = {
    'calm': 'Sakin',
    'balanced': 'Dengeli',
    'packed': 'Dolu',
  };

  static const _groupLabels = {
    'solo': 'Yalnız',
    'couple': 'Çift',
    'friends': 'Arkadaş',
    'family': 'Aile',
  };

  static const _transportLabels = {
    'walk': 'Yürüyüş',
    'transit': 'Toplu taşıma',
    'drive': 'Araç',
    'bike': 'Bisiklet',
  };

  static const _interestLabels = {
    'history': 'Tarih',
    'food': 'Yemek',
    'nature': 'Doğa',
    'art': 'Sanat',
    'shopping': 'Alışveriş',
  };

  @override
  Widget build(BuildContext context) {
    final name = session.displayName.isEmpty ? 'Gezgin' : session.displayName;
    final interests = session.interests
        .map((id) => _interestLabels[id] ?? id)
        .join(', ');

    return Scaffold(
      backgroundColor: context.cBackground,
      body: SafeArea(
        child: ListView(
          padding: context.paddingNormal,
          children: [
            Text('Profile', style: context.textTheme.headlineMedium),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'N',
                      style: context.textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: context.textTheme.titleLarge),
                        Text(
                          session.defaultArea.isEmpty
                              ? 'Konum yok'
                              : session.defaultArea,
                          style: context.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Row(
              label: 'Konum',
              value: session.defaultArea.isEmpty ? '—' : session.defaultArea,
            ),
            _Row(
              label: 'Tempo',
              value: _tempoLabels[session.tempo] ?? session.tempo,
            ),
            _Row(
              label: 'İlgi',
              value: interests.isEmpty ? '—' : interests,
            ),
            _Row(
              label: 'Grup',
              value: _groupLabels[session.groupType] ?? session.groupType,
            ),
            _Row(
              label: 'Taşıt',
              value:
                  _transportLabels[session.transportMode] ??
                  session.transportMode,
            ),
            _Row(label: 'API', value: defaultApiBaseUrl()),
            _Row(
              label: 'Onboarding',
              value: session.onboardingComplete ? 'Tamam' : 'Eksik',
            ),
            const SizedBox(height: 24),
            SecondaryButton(
              label: 'Onboarding’i sıfırla',
              onPressed: () async {
                await session.resetOnboarding();
                if (context.mounted) context.go('/onboarding');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(label, style: context.textTheme.titleMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: context.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

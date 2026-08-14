import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/core/widgets/locale_dropdown.dart';
import 'package:navgo_mobile/core/widgets/primary_button.dart';
import 'package:navgo_mobile/data/session_repository.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, required this.session});

  final SessionRepository session;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String _tempoLabel(Translations t, String id) => switch (id) {
        'calm' => t.common.tempo.calm,
        'balanced' => t.common.tempo.balanced,
        'packed' => t.common.tempo.packed,
        _ => id,
      };

  String _groupLabel(Translations t, String id) => switch (id) {
        'solo' => t.common.group.solo,
        'couple' => t.common.group.couple,
        'friends' => t.common.group.friends,
        'family' => t.common.group.family,
        _ => id,
      };

  String _transportLabel(Translations t, String id) => switch (id) {
        'walk' => t.common.transport.walk,
        'transit' => t.common.transport.transit,
        'drive' => t.common.transport.drive,
        'bike' => t.common.transport.bike,
        _ => id,
      };

  String _interestLabel(Translations t, String id) => switch (id) {
        'history' => t.common.interest.history,
        'food' => t.common.interest.food,
        'nature' => t.common.interest.nature,
        'art' => t.common.interest.art,
        'shopping' => t.common.interest.shopping,
        _ => id,
      };

  Future<void> _setLocale(AppLocale locale) async {
    await widget.session.setLocaleCode(locale.languageCode);
    await LocaleSettings.setLocale(locale);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final session = widget.session;
    final name =
        session.displayName.isEmpty ? t.common.defaultTravelerName : session.displayName;
    final interests = session.interests
        .map((id) => _interestLabel(t, id))
        .join(', ');
    final selectedLocale = LocaleSettings.currentLocale;

    return Scaffold(
      backgroundColor: context.cBackground,
      body: SafeArea(
        child: ListView(
          padding: context.paddingNormal,
          children: [
            Text(t.profile.title, style: context.textTheme.headlineMedium),
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
                              ? t.profile.noLocation
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
              label: t.profile.labelLocation,
              value: session.defaultArea.isEmpty
                  ? t.common.emDash
                  : session.defaultArea,
            ),
            _Row(
              label: t.profile.labelTempo,
              value: _tempoLabel(t, session.tempo),
            ),
            _Row(
              label: t.profile.labelInterests,
              value: interests.isEmpty ? t.common.emDash : interests,
            ),
            _Row(
              label: t.profile.labelGroup,
              value: _groupLabel(t, session.groupType),
            ),
            _Row(
              label: t.profile.labelTransport,
              value: _transportLabel(t, session.transportMode),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    t.profile.labelLanguage,
                    style: context.textTheme.titleMedium,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: LocaleCodeDropdown(
                        value: selectedLocale,
                        onChanged: _setLocale,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SecondaryButton(
              label: t.profile.resetOnboarding,
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

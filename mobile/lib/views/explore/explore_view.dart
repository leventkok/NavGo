import 'package:flutter/material.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';

class ExploreView extends StatelessWidget {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final areas = <(String, String, IconData)>[
      (
        t.explore.destinations.istanbul.name,
        t.explore.destinations.istanbul.blurb,
        Icons.mosque_outlined,
      ),
      (
        t.explore.destinations.cappadocia.name,
        t.explore.destinations.cappadocia.blurb,
        Icons.terrain_outlined,
      ),
      (
        t.explore.destinations.rome.name,
        t.explore.destinations.rome.blurb,
        Icons.account_balance_outlined,
      ),
      (
        t.explore.destinations.lisbon.name,
        t.explore.destinations.lisbon.blurb,
        Icons.tram_outlined,
      ),
      (
        t.explore.destinations.tokyo.name,
        t.explore.destinations.tokyo.blurb,
        Icons.temple_buddhist_outlined,
      ),
      (
        t.explore.destinations.barcelona.name,
        t.explore.destinations.barcelona.blurb,
        Icons.beach_access_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: context.cBackground,
      body: SafeArea(
        child: ListView(
          padding: context.paddingNormal,
          children: [
            Text(t.explore.title, style: context.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              t.explore.subtitle,
              style: context.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            for (final a in areas) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(a.$3, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.$1, style: context.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(a.$2, style: context.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.neutral),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

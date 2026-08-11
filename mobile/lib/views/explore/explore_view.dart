import 'package:flutter/material.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';

class ExploreView extends StatelessWidget {
  const ExploreView({super.key});

  /// Inspiration destinations — not tied to a single home city.
  static const _areas = <(String, String, IconData)>[
    ('İstanbul', 'Tarihi yarımada · Boğaz · kahve', Icons.mosque_outlined),
    ('Kapadokya', 'Vadiler · gün doğumu · yürüyüş', Icons.terrain_outlined),
    ('Roma', 'Forum · Trastevere · gelato', Icons.account_balance_outlined),
    ('Lizbon', 'Alfama · tramvay · miradouro', Icons.tram_outlined),
    ('Tokyo', 'Mahalleler · tapınak · ramen', Icons.temple_buddhist_outlined),
    ('Barselona', 'Gotik mahalle · plaj · tapas', Icons.beach_access_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cBackground,
      body: SafeArea(
        child: ListView(
          padding: context.paddingNormal,
          children: [
            Text('Explore', style: context.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Herhangi bir şehir veya bölge için fikirler. Plan sekmesinde destinasyonunu seç.',
              style: context.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            for (final a in _areas) ...[
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

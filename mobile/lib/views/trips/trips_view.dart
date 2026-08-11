import 'package:flutter/material.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';

class TripsView extends StatelessWidget {
  const TripsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cBackground,
      body: SafeArea(
        child: Padding(
          padding: context.paddingNormal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trips', style: context.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Kaydettiğin gün planları burada listelenir.',
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.luggage_outlined, size: 48, color: AppColors.neutral),
                      const SizedBox(height: 12),
                      Text(
                        'Henüz kayıtlı trip yok',
                        style: context.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Plan sekmesinden bir gün oluştur, sonra burada görünecek.',
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

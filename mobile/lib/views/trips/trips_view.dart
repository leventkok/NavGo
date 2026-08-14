import 'package:flutter/material.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';

class TripsView extends StatelessWidget {
  const TripsView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: context.cBackground,
      body: SafeArea(
        child: Padding(
          padding: context.paddingNormal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.trips.title, style: context.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                t.trips.subtitle,
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
                        t.trips.emptyTitle,
                        style: context.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.trips.emptyBody,
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

import 'package:flutter/material.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';

/// Activity template — area comes from the user's chosen city/region.
class PlanSuggestion {
  const PlanSuggestion({
    required this.title,
    required this.subtitle,
    required this.query,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String query;
  final IconData icon;
  final Color accent;
}

List<PlanSuggestion> planSuggestionsFor(Translations t) => [
      PlanSuggestion(
        title: t.plan.suggestion.historicCenter.title,
        subtitle: t.plan.suggestion.historicCenter.subtitle,
        query: 'tarihi yerler meydan kahve',
        icon: Icons.fort_outlined,
        accent: AppColors.primary,
      ),
      PlanSuggestion(
        title: t.plan.suggestion.waterfront.title,
        subtitle: t.plan.suggestion.waterfront.subtitle,
        query: 'sahil liman yürüyüş manzara',
        icon: Icons.sailing_outlined,
        accent: const Color(0xFF1A5A6B),
      ),
      PlanSuggestion(
        title: t.plan.suggestion.coffeeRoute.title,
        subtitle: t.plan.suggestion.coffeeRoute.subtitle,
        query: 'kahve cafe specialty',
        icon: Icons.coffee_outlined,
        accent: AppColors.tertiary,
      ),
      PlanSuggestion(
        title: t.plan.suggestion.museumCulture.title,
        subtitle: t.plan.suggestion.museumCulture.subtitle,
        query: 'müze galeri anıt kültür',
        icon: Icons.account_balance_outlined,
        accent: AppColors.secondary,
      ),
    ];

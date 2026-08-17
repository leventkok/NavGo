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
    this.iconKey = 'modern',
  });

  final String title;
  final String subtitle;
  final String query;
  final IconData icon;
  final Color accent;
  final String iconKey;

  factory PlanSuggestion.fromApi(Map<String, dynamic> json) {
    final iconKey = (json['icon'] as String? ?? 'modern').trim().toLowerCase();
    final style = suggestionStyleFor(iconKey);
    return PlanSuggestion(
      title: (json['title'] as String? ?? '').trim(),
      subtitle: (json['subtitle'] as String? ?? '').trim(),
      query: (json['query'] as String? ?? '').trim(),
      icon: style.icon,
      accent: style.accent,
      iconKey: iconKey,
    );
  }
}

class SuggestionStyle {
  const SuggestionStyle({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;
}

SuggestionStyle suggestionStyleFor(String iconKey) {
  return switch (iconKey) {
    'historic' => const SuggestionStyle(
        icon: Icons.fort_outlined,
        accent: AppColors.primary,
      ),
    'waterfront' => const SuggestionStyle(
        icon: Icons.sailing_outlined,
        accent: Color(0xFF1A5A6B),
      ),
    'coffee' => const SuggestionStyle(
        icon: Icons.coffee_outlined,
        accent: AppColors.tertiary,
      ),
    'museum' => const SuggestionStyle(
        icon: Icons.account_balance_outlined,
        accent: AppColors.secondary,
      ),
    'parks' => const SuggestionStyle(
        icon: Icons.park_outlined,
        accent: Color(0xFF2E7D4F),
      ),
    'bazaar' => const SuggestionStyle(
        icon: Icons.storefront_outlined,
        accent: Color(0xFFB85C38),
      ),
    'viewpoints' => const SuggestionStyle(
        icon: Icons.landscape_outlined,
        accent: Color(0xFF5B6C8C),
      ),
    _ => const SuggestionStyle(
        icon: Icons.explore_outlined,
        accent: AppColors.primary,
      ),
  };
}

/// Inland-safe static cards — prefer LLM [suggestDayCards] when available.
List<PlanSuggestion> fallbackSuggestionsFor(Translations t) {
  final historic = suggestionStyleFor('historic');
  final coffee = suggestionStyleFor('coffee');
  final museum = suggestionStyleFor('museum');
  final parks = suggestionStyleFor('parks');
  return [
    PlanSuggestion(
      title: t.plan.suggestion.historicCenter.title,
      subtitle: t.plan.suggestion.historicCenter.subtitle,
      query: 'tarihi yerler meydan kahve',
      icon: historic.icon,
      accent: historic.accent,
      iconKey: 'historic',
    ),
    PlanSuggestion(
      title: t.plan.suggestion.coffeeRoute.title,
      subtitle: t.plan.suggestion.coffeeRoute.subtitle,
      query: 'kahve cafe specialty',
      icon: coffee.icon,
      accent: coffee.accent,
      iconKey: 'coffee',
    ),
    PlanSuggestion(
      title: t.plan.suggestion.museumCulture.title,
      subtitle: t.plan.suggestion.museumCulture.subtitle,
      query: 'müze galeri anıt kültür',
      icon: museum.icon,
      accent: museum.accent,
      iconKey: 'museum',
    ),
    PlanSuggestion(
      title: t.plan.suggestion.parksLakes.title,
      subtitle: t.plan.suggestion.parksLakes.subtitle,
      query: 'park göl yeşil alan yürüyüş',
      icon: parks.icon,
      accent: parks.accent,
      iconKey: 'parks',
    ),
  ];
}

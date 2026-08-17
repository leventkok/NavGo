import 'package:flutter/material.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';

/// Mood / playlist-style day route card for the plan home screen.
class PlanSuggestion {
  const PlanSuggestion({
    required this.title,
    required this.subtitle,
    required this.query,
    required this.icon,
    required this.accent,
    this.iconKey = 'modern',
    this.intent = 'first_day',
    this.area = '',
  });

  final String title;
  final String subtitle;
  final String query;
  final IconData icon;
  final Color accent;
  final String iconKey;
  final String intent;
  final String area;

  factory PlanSuggestion.fromApi(Map<String, dynamic> json) {
    var iconKey = (json['icon'] as String? ?? '').trim().toLowerCase();
    var intent = (json['intent'] as String? ?? '').trim().toLowerCase();
    if (intent.isEmpty) {
      intent = intentForIcon(iconKey);
    }
    if (iconKey.isEmpty) {
      iconKey = iconForIntent(intent);
    }
    final style = suggestionStyleFor(iconKey);
    return PlanSuggestion(
      title: (json['title'] as String? ?? '').trim(),
      subtitle: (json['subtitle'] as String? ?? '').trim(),
      query: (json['query'] as String? ?? '').trim(),
      icon: style.icon,
      accent: style.accent,
      iconKey: iconKey,
      intent: intent,
      area: (json['area'] as String? ?? '').trim(),
    );
  }
}

class SuggestionStyle {
  const SuggestionStyle({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;
}

String iconForIntent(String intent) {
  return switch (intent) {
    'slow' => 'coffee',
    'culture' => 'museum',
    'food' || 'shop' => 'bazaar',
    'photo' => 'viewpoints',
    'family' => 'parks',
    _ => 'modern',
  };
}

String intentForIcon(String iconKey) {
  return switch (iconKey) {
    'historic' || 'museum' => 'culture',
    'coffee' => 'slow',
    'parks' => 'family',
    'bazaar' => 'food',
    'viewpoints' => 'photo',
    'waterfront' => 'slow',
    _ => 'first_day',
  };
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

/// Inland-safe intent cards — prefer LLM [suggestDayCards] when available.
List<PlanSuggestion> fallbackSuggestionsFor(Translations t) {
  PlanSuggestion card({
    required String intent,
    required String title,
    required String subtitle,
    required String query,
  }) {
    final iconKey = iconForIntent(intent);
    final style = suggestionStyleFor(iconKey);
    return PlanSuggestion(
      title: title,
      subtitle: subtitle,
      query: query,
      icon: style.icon,
      accent: style.accent,
      iconKey: iconKey,
      intent: intent,
    );
  }

  final fb = t.plan.routelistFallback;
  return [
    card(
      intent: 'first_day',
      title: fb.firstDay.title,
      subtitle: fb.firstDay.subtitle,
      query: 'tarihi yerler meydan ikonik',
    ),
    card(
      intent: 'slow',
      title: fb.slow.title,
      subtitle: fb.slow.subtitle,
      query: 'kahve cafe park yürüyüş',
    ),
    card(
      intent: 'culture',
      title: fb.culture.title,
      subtitle: fb.culture.subtitle,
      query: 'müze galeri anıt kültür',
    ),
    card(
      intent: 'food',
      title: fb.food.title,
      subtitle: fb.food.subtitle,
      query: 'lokal yemek pazar esnaf',
    ),
  ];
}

import 'package:flutter/material.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';

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

const planSuggestions = <PlanSuggestion>[
  PlanSuggestion(
    title: 'Tarihi merkez',
    subtitle: 'Eski sokaklar · meydan · kahve',
    query: 'tarihi yerler meydan kahve',
    icon: Icons.fort_outlined,
    accent: AppColors.primary,
  ),
  PlanSuggestion(
    title: 'Sahil / liman',
    subtitle: 'Su kenarı · yürüyüş · manzara',
    query: 'sahil liman yürüyüş manzara',
    icon: Icons.sailing_outlined,
    accent: Color(0xFF1A5A6B),
  ),
  PlanSuggestion(
    title: 'Kahve rotası',
    subtitle: 'Üç durak · sakin tempo',
    query: 'kahve cafe specialty',
    icon: Icons.coffee_outlined,
    accent: AppColors.tertiary,
  ),
  PlanSuggestion(
    title: 'Müze & kültür',
    subtitle: 'Müze · galeri · anıt',
    query: 'müze galeri anıt kültür',
    icon: Icons.account_balance_outlined,
    accent: AppColors.secondary,
  ),
];

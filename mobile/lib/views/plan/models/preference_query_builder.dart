/// Builds Places search queries from onboarding preferences + suggestion seed.
class PreferenceQueryBuilder {
  const PreferenceQueryBuilder();

  static const interestTokens = <String, String>{
    'history': 'müze anıt tarihi yerler',
    'food': 'restoran cafe yemek',
    'nature': 'park bahçe doğa',
    'art': 'galeri sanat müze',
    'shopping': 'çarşı market alışveriş',
  };

  String build({
    required List<String> interests,
    required String groupType,
    String seedQuery = '',
  }) {
    final parts = <String>[];

    if (seedQuery.trim().isNotEmpty) {
      parts.add(seedQuery.trim());
    }

    for (final id in interests) {
      final token = interestTokens[id];
      if (token != null) parts.add(token);
    }

    // Soft group bias — family avoids nightlife keywords.
    switch (groupType) {
      case 'family':
        parts.add('aile dostu park');
      case 'couple':
        parts.add('romantik cafe manzara');
      case 'friends':
        parts.add('paylaşılabilir deneyim');
      case 'solo':
        parts.add('sakin keşif');
      default:
        break;
    }

    var query = parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    if (groupType == 'family') {
      query = _stripNightlife(query);
    }

    return query.isEmpty ? 'gezilecek yerler' : query;
  }

  String _stripNightlife(String query) {
    const banned = [
      'bar',
      'pub',
      'gece',
      'nightclub',
      'club',
      'içki',
      'meyhane',
    ];
    var out = query.toLowerCase();
    for (final w in banned) {
      out = out.replaceAll(RegExp('\\b$w\\b', caseSensitive: false), '');
    }
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

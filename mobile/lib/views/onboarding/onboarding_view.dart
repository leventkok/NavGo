import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/core/widgets/manual_area_dialog.dart';
import 'package:navgo_mobile/core/widgets/primary_button.dart';
import 'package:navgo_mobile/data/location_service.dart';
import 'package:navgo_mobile/data/session_repository.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({
    super.key,
    required this.session,
    this.locationService,
  });

  final SessionRepository session;
  final LocationService? locationService;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _page = PageController();
  final _nameCtrl = TextEditingController();
  late final LocationService _location =
      widget.locationService ?? LocationService();

  var _index = 0;
  var _tempo = 'balanced';
  final _interests = <String>{'history', 'food'};
  var _group = 'solo';
  var _transport = 'walk';
  var _saving = false;
  String? _nameError;
  String? _interestsError;

  static const _steps = 6;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (_nameError != null && _nameCtrl.text.trim().isNotEmpty) {
      setState(() => _nameError = null);
    }
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _page.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_saving) return;
    if (_index == 1 && _nameCtrl.text.trim().isEmpty) {
      setState(() => _nameError = 'Sana nasıl sesleneceğimizi bilmemiz için isim gerekli');
      return;
    }
    if (_index == 3 && _interests.isEmpty) {
      setState(
        () => _interestsError =
            'Sana uygun mekanlar önerebilmemiz için en az bir ilgi alanı seç',
      );
      return;
    }
    if (_index >= _steps - 1) {
      await _finish();
      return;
    }
    // Keep the button responsive — don't await animation on the call stack.
    unawaited(
      _page.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _previous() {
    if (_saving || _index <= 0) return;
    unawaited(
      _page.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      var area = '';
      final outcome = await _location.resolveAreaDetailed();
      if (outcome.result != null && outcome.result!.area.isNotEmpty) {
        area = outcome.result!.area;
      } else {
        final manual = await promptLocationAreaAfterFailure(
          context,
          failure: outcome.failure,
          resolveAgain: _location.resolveAreaDetailed,
        );
        if (manual == null || manual.trim().isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Şehir veya ilçe gerekli')),
            );
          }
          return;
        }
        area = manual.trim();
      }

      await widget.session.completeOnboarding(
        displayName: _nameCtrl.text.trim(),
        defaultArea: area,
        tempo: _tempo,
        interests: _interests.toList(),
        groupType: _group,
        transportMode: _transport,
      );
      if (!mounted) return;
      context.go('/plan');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SizedBox(height: top + 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (_index > 0)
                  IconButton(
                    onPressed: _saving ? null : _previous,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Geri',
                    visualDensity: VisualDensity.compact,
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    'NavGo',
                    style: context.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${_index + 1}/$_steps',
                    style: context.textTheme.labelLarge,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (_index + 1) / _steps,
                minHeight: 4,
                backgroundColor: AppColors.surfaceMuted,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                const _WelcomeStep(),
                _NameStep(controller: _nameCtrl, errorText: _nameError),
                _TempoStep(
                  selected: _tempo,
                  onSelect: (v) => setState(() => _tempo = v),
                ),
                _InterestsStep(
                  selected: _interests,
                  errorText: _interestsError,
                  onToggle: (id) {
                    setState(() {
                      if (_interests.contains(id)) {
                        _interests.remove(id);
                      } else {
                        _interests.add(id);
                      }
                      if (_interests.isNotEmpty) _interestsError = null;
                    });
                  },
                ),
                _GroupStep(
                  selected: _group,
                  onSelect: (v) => setState(() => _group = v),
                ),
                _TransportStep(
                  selected: _transport,
                  onSelect: (v) => setState(() => _transport = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: PrimaryButton(
              label: _saving
                  ? 'Konum alınıyor…'
                  : (_index >= _steps - 1 ? 'NavGo’ya gir' : 'Devam'),
              onPressed: _saving ? null : _next,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.explore, size: 64, color: AppColors.primary),
        ),
        const SizedBox(height: 22),
        Text(
          'Günü gerçek yerlerle planla',
          style: context.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'NavGo, konumunu ve tercihlerini alır; gerçek yerlerden rota ve gün planı oluşturur.',
          style: context.textTheme.bodyLarge?.copyWith(color: AppColors.neutral),
        ),
      ],
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller, this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      children: [
        Text('Seni nasıl çağıralım?', style: context.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Profilinde görünecek kısa bir isim yeter.',
          style: context.textTheme.bodyLarge?.copyWith(color: AppColors.neutral),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Adın',
            errorText: errorText,
            errorMaxLines: 3,
          ),
        ),
      ],
    );
  }
}

class _TempoStep extends StatelessWidget {
  const _TempoStep({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = <(String, String, String, IconData)>[
      ('calm', 'Sakin', 'Az durak · bol nefes', Icons.spa_outlined),
      ('balanced', 'Dengeli', 'Günün tadını çıkar', Icons.balance_outlined),
      ('packed', 'Dolu', 'Mümkün olduğunca keşfet', Icons.bolt_outlined),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      children: [
        Text('Günün temposu', style: context.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Kaç durak istediğin — mekan yoğunluğundan bağımsız tercihin.',
          style: context.textTheme.bodyLarge?.copyWith(color: AppColors.neutral),
        ),
        const SizedBox(height: 20),
        for (final o in options) ...[
          _ChoiceCard(
            title: o.$2,
            subtitle: o.$3,
            icon: o.$4,
            selected: selected == o.$1,
            onTap: () => onSelect(o.$1),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _InterestsStep extends StatelessWidget {
  const _InterestsStep({
    required this.selected,
    required this.onToggle,
    this.errorText,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final String? errorText;

  static const _options = <(String, String, IconData)>[
    ('history', 'Tarih', Icons.account_balance_outlined),
    ('food', 'Yemek', Icons.restaurant_outlined),
    ('nature', 'Doğa', Icons.park_outlined),
    ('art', 'Sanat', Icons.palette_outlined),
    ('shopping', 'Alışveriş', Icons.shopping_bag_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      children: [
        Text('İlgi alanların', style: context.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Birden fazla seçebilirsin. Mekan aramasını buna göre yönlendiririz.',
          style: context.textTheme.bodyLarge?.copyWith(color: AppColors.neutral),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final o in _options)
              Builder(
                builder: (context) {
                  final isSelected = selected.contains(o.$1);
                  return FilterChip(
                    label: Text(o.$2),
                    avatar: isSelected
                        ? null
                        : Icon(o.$3, size: 18, color: AppColors.neutral),
                    showCheckmark: true,
                    selected: isSelected,
                    onSelected: (_) => onToggle(o.$1),
                    selectedColor: AppColors.primary.withValues(alpha: 0.12),
                    backgroundColor: AppColors.surface,
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.secondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceMuted,
                    ),
                  );
                },
              ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 12),
          Text(
            errorText!,
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.danger,
            ),
          ),
        ],
      ],
    );
  }
}

class _GroupStep extends StatelessWidget {
  const _GroupStep({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = <(String, String, String, IconData)>[
      ('solo', 'Yalnız', 'Kendi temposunda keşif', Icons.person_outline),
      ('couple', 'Çift', 'İki kişilik rotalar', Icons.favorite_outline),
      ('friends', 'Arkadaş', 'Paylaşılabilir duraklar', Icons.groups_outlined),
      (
        'family',
        'Aile',
        'Aile dostu; bar/pub önerilmez',
        Icons.family_restroom_outlined,
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      children: [
        Text('Kimle geziyorsun?', style: context.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Tercihin rotanı ve durakları şekillendirir.',
          style: context.textTheme.bodyLarge?.copyWith(color: AppColors.neutral),
        ),
        const SizedBox(height: 20),
        for (final o in options) ...[
          _ChoiceCard(
            title: o.$2,
            subtitle: o.$3,
            icon: o.$4,
            selected: selected == o.$1,
            onTap: () => onSelect(o.$1),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TransportStep extends StatelessWidget {
  const _TransportStep({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = <(String, String, String, IconData)>[
      ('walk', 'Yürüyüş', 'Yaya rota', Icons.directions_walk),
      ('transit', 'Toplu taşıma', 'Metro · otobüs · tramvay', Icons.directions_transit),
      ('drive', 'Araç', 'Araba ile bağlantı', Icons.directions_car),
      ('bike', 'Bisiklet', 'Hafif tempo', Icons.directions_bike),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      children: [
        Text('Nasıl ilerleyelim?', style: context.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Gün boyunca nasıl dolaşacağını seç — rotan buna göre kurulur.',
          style: context.textTheme.bodyLarge?.copyWith(color: AppColors.neutral),
        ),
        const SizedBox(height: 20),
        for (final o in options) ...[
          _ChoiceCard(
            title: o.$2,
            subtitle: o.$3,
            icon: o.$4,
            selected: selected == o.$1,
            onTap: () => onSelect(o.$1),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.surfaceMuted,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.neutral,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: selected ? AppColors.primary : null,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: selected ? AppColors.secondary : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

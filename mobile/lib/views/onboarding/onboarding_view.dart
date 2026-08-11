import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
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

  static const _steps = 6;

  @override
  void dispose() {
    _page.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_saving) return;
    if (_index == 1 && _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İsim gerekli')),
      );
      return;
    }
    if (_index == 3 && _interests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir ilgi alanı seç')),
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

  Future<String?> _promptManualArea(LocationFailure? failure) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Şehir veya ilçe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocationService.failureMessage(failure),
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Örn. Kadıköy, İstanbul',
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
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
        final manual = await _promptManualArea(outcome.failure);
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
                Text('NavGo', style: context.textTheme.titleLarge),
                const Spacer(),
                Text(
                  '${_index + 1}/$_steps',
                  style: context.textTheme.labelLarge,
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
                _NameStep(controller: _nameCtrl),
                _TempoStep(
                  selected: _tempo,
                  onSelect: (v) => setState(() => _tempo = v),
                ),
                _InterestsStep(
                  selected: _interests,
                  onToggle: (id) {
                    setState(() {
                      if (_interests.contains(id)) {
                        _interests.remove(id);
                      } else {
                        _interests.add(id);
                      }
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
          'NavGo konumundan şehir ve ilçeni alır; tercihlerine göre grounded Places ve rota üretir. Yer uydurmaz.',
          style: context.textTheme.bodyLarge?.copyWith(color: AppColors.neutral),
        ),
      ],
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller});
  final TextEditingController controller;

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
          decoration: const InputDecoration(hintText: 'Adın'),
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
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;

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
              FilterChip(
                label: Text(o.$2),
                avatar: Icon(o.$3, size: 18),
                selected: selected.contains(o.$1),
                onSelected: (_) => onToggle(o.$1),
                selectedColor: AppColors.primary.withValues(alpha: 0.18),
                checkmarkColor: AppColors.primary,
              ),
          ],
        ),
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
          'Öneri tipini etkiler — örneğin ailede gece hayatı önerilmez.',
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
          'Rota hesaplamasında kullanılacak taşıt stili.',
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
                    Text(title, style: context.textTheme.titleMedium),
                    Text(subtitle, style: context.textTheme.bodyMedium),
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

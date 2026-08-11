import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/core/widgets/primary_button.dart';
import 'package:navgo_mobile/data/session_repository.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key, required this.session});

  final SessionRepository session;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _page = PageController();
  final _nameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  var _index = 0;
  var _style = 'walk';
  var _saving = false;

  static const _steps = 4;

  @override
  void dispose() {
    _page.dispose();
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index == 1 && _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İsim gerekli')),
      );
      return;
    }
    if (_index == 2 && _areaCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şehir veya bölge gerekli')),
      );
      return;
    }
    if (_index >= _steps - 1) {
      await _finish();
      return;
    }
    await _page.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.session.completeOnboarding(
        displayName: _nameCtrl.text.trim(),
        travelStyle: _style,
        defaultArea: _areaCtrl.text.trim(),
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
                _WelcomeStep(),
                _NameStep(controller: _nameCtrl),
                _AreaStep(controller: _areaCtrl),
                _StyleStep(
                  selected: _style,
                  onSelect: (v) => setState(() => _style = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: PrimaryButton(
              label: _saving
                  ? 'Kaydediliyor…'
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
          child: Icon(Icons.explore, size: 64, color: AppColors.primary),
        ),
        const SizedBox(height: 22),
        Text('Günü gerçek yerlerle planla', style: context.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'NavGo, seçtiğin şehirde grounded Places ve yürüyüş rotası üretir. Yer uydurmaz.',
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

class _AreaStep extends StatelessWidget {
  const _AreaStep({required this.controller});
  final TextEditingController controller;

  static const _chips = <String>[
    'İstanbul',
    'Ankara',
    'İzmir',
    'Kapadokya',
    'Roma',
    'Lizbon',
    'Tokyo',
    'Barselona',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      children: [
        Text('Nerede planlıyorsun?', style: context.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Herhangi bir şehir veya bölge. Sonra her planda değiştirebilirsin.',
          style: context.textTheme.bodyLarge?.copyWith(color: AppColors.neutral),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Örn. İstanbul, Roma, Tokyo…',
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in _chips)
              ActionChip(
                label: Text(c),
                onPressed: () => controller.text = c,
              ),
          ],
        ),
      ],
    );
  }
}

class _StyleStep extends StatelessWidget {
  const _StyleStep({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = <(String, String, IconData)>[
      ('walk', 'Yürüyüş', Icons.directions_walk),
      ('mix', 'Karışık', Icons.alt_route),
      ('coffee', 'Kahve molalı', Icons.coffee_outlined),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      children: [
        Text('Gezi stilin', style: context.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Varsayılan rota tercihin. Sonra her planda değiştirebilirsin.',
          style: context.textTheme.bodyLarge?.copyWith(color: AppColors.neutral),
        ),
        const SizedBox(height: 20),
        for (final o in options) ...[
          _StyleCard(
            label: o.$2,
            icon: o.$3,
            selected: selected == o.$1,
            onTap: () => onSelect(o.$1),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.surfaceMuted,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? AppColors.primary : AppColors.neutral),
              const SizedBox(width: 12),
              Text(label, style: context.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

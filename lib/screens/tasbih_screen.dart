import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../theme/app_theme.dart';
import '../widgets/fx.dart';

/// Digital tasbih for the adhkar after salah:
/// SubhanAllah ×33, Alhamdulillah ×33, Allahu Akbar ×34.
///
/// Deliberately earns NO XP: it can't be verified, and dhikr is between the
/// user and Allah. It is here because it's the natural next step after prayer.
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> with SingleTickerProviderStateMixin {
  late final _steps = [
    (ar: 'سُبْحَانَ ٱللَّٰهِ', ml: 'സുബ്ഹാനല്ലാഹ്', en: tr('Glory be to Allah'), n: 33),
    (ar: 'ٱلْحَمْدُ لِلَّٰهِ', ml: 'അൽഹംദുലില്ലാഹ്', en: tr('All praise is for Allah'), n: 33),
    (ar: 'ٱللَّٰهُ أَكْبَرُ', ml: 'അല്ലാഹു അക്ബർ', en: tr('Allah is the Greatest'), n: 34),
  ];

  int _step = 0;
  int _count = 0;
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _tap() {
    if (_step >= _steps.length) return;
    _pulse.forward(from: 0);
    setState(() => _count++);
    if (_count >= _steps[_step].n) {
      HapticFeedback.mediumImpact();
      setState(() {
        _step++;
        _count = 0;
      });
      if (_step >= _steps.length) {
        celebrate(context, title: tr('Dhikr complete'), subtitle: tr('Adhkar complete · 100 ✓'), emoji: '📿');
      }
    } else {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final done = _step >= _steps.length;
    final s = _steps[done ? _steps.length - 1 : _step];
    final total = _steps.fold<int>(0, (a, b) => a + b.n);
    final soFar = _steps.take(_step).fold<int>(0, (a, b) => a + b.n) + _count;

    return Scaffold(
      appBar: AppBar(title: Text(tr('📿 Tasbih'))),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  for (final (i, st) in _steps.indexed)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: NeonBar(
                          value: i < _step ? 1 : (i == _step ? _count / st.n : 0),
                          height: 6,
                          colors: const [AppColors.violet, AppColors.gold],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              done ? 'മാഷാ അല്ലാഹ്' : s.ar,
              style: const TextStyle(fontSize: 38, color: AppColors.gold, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              done
                  ? tr('All 100 done')
                  : switch (L10n.lang.value) {
                      AppLang.ml => '${s.ml} · ${s.en}',
                      AppLang.ar => s.ar,
                      AppLang.en => s.en,
                    },
              style: t.bodyMedium,
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: _tap,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) {
                  final k = 1 - 0.06 * Curves.easeOut.transform(1 - (_pulse.value - 0.5).abs() * 2);
                  return Transform.scale(scale: done ? 1 : k, child: child);
                },
                child: Container(
                  width: 230,
                  height: 230,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(colors: [Color(0xFF1E5A4F), Color(0xFF0B2A24)]),
                    border: Border.all(color: AppColors.emerald.withValues(alpha: 0.6), width: 2),
                    boxShadow: [
                      BoxShadow(color: AppColors.emerald.withValues(alpha: 0.45), blurRadius: 50, spreadRadius: 2),
                      BoxShadow(color: AppColors.gold.withValues(alpha: 0.15), blurRadius: 90, spreadRadius: 10),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          done ? '✓' : '$_count',
                          style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w200, color: AppColors.cream),
                        ),
                        Text(done ? tr('tap back to finish') : tr('of {n}', {'n': s.n}), style: t.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('$soFar / $total', style: t.bodySmall?.copyWith(letterSpacing: 2)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() {
                _step = 0;
                _count = 0;
              }),
              icon: const Icon(Icons.restart_alt),
              label: Text(tr('Reset')),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
              child: Text(
                tr('Dhikr earns no XP. It stays between you and Allah 🤍'),
                textAlign: TextAlign.center,
                style: t.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

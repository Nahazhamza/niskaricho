import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../theme/app_theme.dart';
import '../widgets/fx.dart';
import '../widgets/islamic_icons.dart';

/// Very first screen: pick the app language and text size. Big buttons, each
/// language written in its own script, so anyone can find theirs.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              children: [
                const Center(child: CrescentIcon(size: 48, color: AppColors.gold)),
                const SizedBox(height: 12),
                Text('നിസ്കരിച്ചോ?', textAlign: TextAlign.center, style: t.headlineMedium),
                const SizedBox(height: 18),
                // Shown in all three languages on purpose.
                Text(
                  'Choose your language\nഭാഷ തിരഞ്ഞെടുക്കുക\nاختر لغتك',
                  textAlign: TextAlign.center,
                  style: t.titleMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 18),
                for (final l in AppLang.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: LanguageButton(
                      lang: l,
                      onTap: () async {
                        await L10n.set(l);
                        onDone();
                      },
                    ),
                  ),
                const SizedBox(height: 18),
                // Before a language is chosen, the sizes are shown as A, A+, A++.
                const TextSizePicker(symbols: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key, required this.lang, required this.onTap, this.selected = false});
  final AppLang lang;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 68,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: selected ? AppColors.gold : AppColors.surfaceHigh,
        foregroundColor: selected ? AppColors.night : AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(lang.native, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          ),
          if (lang != AppLang.en) Text(lang.english, style: const TextStyle(fontSize: 15)),
          if (selected) const Padding(padding: EdgeInsetsDirectional.only(start: 8), child: Icon(Icons.check)),
        ],
      ),
    ),
  );
}

/// Normal / Large / Extra large text, with a live sample.
class TextSizePicker extends StatelessWidget {
  const TextSizePicker({super.key, this.symbols = false});
  final bool symbols;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: L10n.textScale,
    builder: (context, scale, _) => GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(symbols ? 'Aa' : tr('Text size'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SegmentedButton<double>(
            segments: [
              ButtonSegment(
                value: 1.0,
                label: Text(symbols ? 'A' : tr('Normal'), style: const TextStyle(fontSize: 14)),
              ),
              ButtonSegment(
                value: 1.15,
                label: Text(symbols ? 'A+' : tr('Large'), style: const TextStyle(fontSize: 17)),
              ),
              ButtonSegment(
                value: 1.3,
                label: Text(symbols ? 'A++' : tr('Extra large'), style: const TextStyle(fontSize: 20)),
              ),
            ],
            selected: {scale},
            showSelectedIcon: false,
            onSelectionChanged: (s) => L10n.setTextScale(s.first),
          ),
        ],
      ),
    ),
  );
}

/// Language and text size, for Journey → Settings.
class LanguageCard extends StatelessWidget {
  const LanguageCard({super.key});

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('🌐 ${tr('Language')}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final l in AppLang.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: LanguageButton(lang: l, selected: L10n.lang.value == l, onTap: () => L10n.set(l)),
          ),
        const SizedBox(height: 8),
        const TextSizePicker(),
      ],
    ),
  );
}

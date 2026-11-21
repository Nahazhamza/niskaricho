import 'package:material_ui/material_ui.dart';

import '../../l10n/tr.dart';
import '../../models/learn_namaz_model.dart';
import '../../services/learn_namaz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fx.dart';

class LearnSettingsSheet extends StatelessWidget {
  const LearnSettingsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const LearnSettingsSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final s = LearnNamazService.instance;
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF071B1B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF1B4E44), width: 1.5)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('⚙️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(tr('Learning Settings'), style: t.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Madhhab selector
          Text(tr('Teaching Tradition (Madhhab)'), style: t.titleMedium),
          const SizedBox(height: 4),
          Text(
            tr('Highlights specific rulings, hand placement, and recitations for your school of thought.'),
            style: t.bodySmall,
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<LearningMadhhab>(
            valueListenable: s.madhhab,
            builder: (context, current, _) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in LearningMadhhab.values)
                  ChoiceChip(
                    label: Text('${m.label} (${m.ml})'),
                    selected: current == m,
                    onSelected: (selected) {
                      if (selected) s.setMadhhab(m);
                    },
                    selectedColor: AppColors.emerald.withValues(alpha: 0.35),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    side: BorderSide(
                      color: current == m ? AppColors.emerald : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Arabic Font Size
          Text(tr('Arabic Text Size'), style: t.titleMedium),
          ValueListenableBuilder<double>(
            valueListenable: s.arabicFontScale,
            builder: (context, scale, _) => Row(
              children: [
                const Text('A', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                Expanded(
                  child: Slider(
                    value: scale,
                    min: 0.85,
                    max: 1.5,
                    divisions: 5,
                    activeColor: AppColors.cyan,
                    inactiveColor: Colors.white.withValues(alpha: 0.15),
                    onChanged: (v) => s.setArabicFontScale(v),
                  ),
                ),
                const Text('A', style: TextStyle(fontSize: 22, color: AppColors.cream, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Audio Playback Speed
          Text(tr('Audio Playback Speed'), style: t.titleMedium),
          const SizedBox(height: 8),
          ValueListenableBuilder<double>(
            valueListenable: s.audioSpeed,
            builder: (context, speed, _) => Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: () => s.setAudioSpeed(1.0),
                    child: GlassCard(
                      glow: speed == 1.0 ? AppColors.emerald : null,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text(
                          tr('1.0x (Normal)'),
                          style: TextStyle(
                            color: speed == 1.0 ? AppColors.emerald : AppColors.cream,
                            fontWeight: speed == 1.0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Pressable(
                    onTap: () => s.setAudioSpeed(0.75),
                    child: GlassCard(
                      glow: speed == 0.75 ? AppColors.gold : null,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text(
                          tr('0.75x (Slow - Practice)'),
                          style: TextStyle(
                            color: speed == 0.75 ? AppColors.gold : AppColors.cream,
                            fontWeight: speed == 0.75 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Toggles: Transliteration & Translation
          ValueListenableBuilder<bool>(
            valueListenable: s.showTransliteration,
            builder: (context, val, _) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('Show English Transliteration')),
              subtitle: Text(tr('Helps with pronunciation when learning Arabic script')),
              value: val,
              activeThumbColor: AppColors.cyan,
              onChanged: (_) => s.toggleTransliteration(),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: s.showTranslation,
            builder: (context, val, _) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('Show Translation & Meaning')),
              subtitle: Text(tr('Understand what you recite in every movement')),
              value: val,
              activeThumbColor: AppColors.cyan,
              onChanged: (_) => s.toggleTranslation(),
            ),
          ),
        ],
      ),
    );
  }
}

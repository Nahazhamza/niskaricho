import 'package:material_ui/material_ui.dart';

import '../../l10n/tr.dart';
import '../../models/learn_namaz_model.dart';
import '../../services/learn_namaz_content.dart';
import '../../services/learn_namaz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fx.dart';
import 'learn_settings_sheet.dart';
import 'salah_guide_screen.dart';

class PrayersBreakdownScreen extends StatefulWidget {
  const PrayersBreakdownScreen({super.key});

  @override
  State<PrayersBreakdownScreen> createState() => _PrayersBreakdownScreenState();
}

class _PrayersBreakdownScreenState extends State<PrayersBreakdownScreen> {
  final _service = LearnNamazService.instance;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('The Five Daily Prayers')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => LearnSettingsSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Top Overview Card
            GlassCard(
              glow: AppColors.gold,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🕋', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr('Obligatory Farḍ & Sunnah Prayers'),
                          style: t.titleMedium?.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'Every Muslim performs 17 Farḍ rak\'ahs daily. Below, obligatory Farḍ and recommended Sunnah prayers are kept strictly separate.',
                    ),
                    style: t.bodySmall?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<LearningMadhhab>(
                    valueListenable: _service.madhhab,
                    builder: (context, m, _) => Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 16, color: AppColors.cyan),
                        const SizedBox(width: 6),
                        Text(
                          '${tr('Active Tradition')}: ${m.label} (${m.ml})',
                          style: const TextStyle(fontSize: 12, color: AppColors.cyan, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => LearnSettingsSheet.show(context),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          child: Text(tr('Change')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Five Daily Prayer Cards
            for (final prayer in LearnNamazContent.prayers) ...[
              _PrayerCard(prayer: prayer),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({required this.prayer});

  final PrayerInfo prayer;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = LearnNamazService.instance;

    return GlassCard(
      glow: prayer.id == 'fajr' ? AppColors.gold : AppColors.cyan,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    switch (prayer.id) {
                      'fajr' => '🌅',
                      'dhuhr' => '☀️',
                      'asr' => '🌤️',
                      'maghrib' => '🌇',
                      _ => '🌙',
                    },
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(prayer.name),
                      style: t.titleLarge?.copyWith(fontSize: 20),
                    ),
                    Text(
                      tr(prayer.description),
                      style: t.bodySmall?.copyWith(fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // STRICT SEPARATION: Farḍ vs Sunnah Badges
          Row(
            children: [
              // Obligatory Farḍ
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${prayer.fardRakats} ${tr('Farḍ Rak\'ahs')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('Obligatory (Mandatory)'),
                        style: const TextStyle(fontSize: 10, color: AppColors.cream),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Sunnah (Optional)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${prayer.sunnahBefore + prayer.sunnahAfter} ${tr('Sunnah')}${prayer.witr > 0 ? ' + ${prayer.witr} Witr' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.emerald, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('Recommended (Voluntary)'),
                        style: const TextStyle(fontSize: 10, color: AppColors.cream),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Breakdown details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Structure Breakdown:'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.cyan),
                ),
                const SizedBox(height: 4),
                for (final rakah in prayer.rakahSummary)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('• ${tr(rakah)}', style: t.bodySmall?.copyWith(fontSize: 12, height: 1.35)),
                  ),
              ],
            ),
          ),

          // Madhhab specific notes
          ValueListenableBuilder<LearningMadhhab>(
            valueListenable: s.madhhab,
            builder: (context, m, _) {
              final note = prayer.madhhabNotes[m];
              if (note == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📌 ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Text(
                        '${m.label}: $note',
                        style: const TextStyle(fontSize: 11, color: AppColors.gold, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Start Learning Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SalahGuideScreen(prayer: prayer),
                  ),
                );
              },
              icon: const Icon(Icons.play_circle_outline),
              label: Text(tr('Learn Step-by-Step {p}', {'p': tr(prayer.name)})),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

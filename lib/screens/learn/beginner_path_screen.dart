import 'package:material_ui/material_ui.dart';

import '../../l10n/tr.dart';
import '../../models/learn_namaz_model.dart';
import '../../services/learn_namaz_content.dart';
import '../../services/learn_namaz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fx.dart';
import 'prayers_breakdown_screen.dart';
import 'recitation_library_screen.dart';
import 'salah_guide_screen.dart';
import 'wudu_tutorial_screen.dart';

class BeginnerPathScreen extends StatelessWidget {
  const BeginnerPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = LearnNamazService.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Beginner 7-Day Path')),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<LearnProgress>(
          valueListenable: s.progress,
          builder: (context, prog, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Welcome Banner
              GlassCard(
                glow: AppColors.emerald,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🌱', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tr('Start Your Journey to Prayer'),
                            style: t.titleMedium?.copyWith(color: AppColors.emerald, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(
                        'Take it one day at a time without feeling overwhelmed. In just one week, you will be able to perform a complete prayer with confidence and peace in your heart.',
                      ),
                      style: t.bodySmall?.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${tr('Progress')}: ${prog.beginnerDayCompleted}/7 ${tr('days completed')}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gold),
                        ),
                        const Spacer(),
                        Text(
                          '+${prog.beginnerDayCompleted * 10} XP',
                          style: const TextStyle(fontSize: 12, color: AppColors.cyan, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (prog.beginnerDayCompleted / 7).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 7 Days Road
              for (final day in LearnNamazContent.beginnerDays) ...[
                _DayCard(
                  day: day,
                  isCompleted: prog.beginnerDayCompleted >= day.day,
                  isUnlocked: prog.beginnerDayCompleted >= day.day - 1,
                  onComplete: () => s.completeBeginnerDay(day.day),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.isCompleted,
    required this.isUnlocked,
    required this.onComplete,
  });

  final BeginnerDay day;
  final bool isCompleted;
  final bool isUnlocked;
  final VoidCallback onComplete;

  void _openAction(BuildContext context) {
    switch (day.day) {
      case 1:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrayersBreakdownScreen()));
        break;
      case 2:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WuduTutorialScreen()));
        break;
      case 3:
      case 5:
      case 6:
      case 7:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SalahGuideScreen()));
        break;
      case 4:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecitationLibraryScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return GlassCard(
      glow: isCompleted ? AppColors.emerald : (isUnlocked ? AppColors.cyan : null),
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
                  color: (isCompleted ? AppColors.emerald : AppColors.cyan).withValues(alpha: 0.15),
                  border: Border.all(
                    color: isCompleted ? AppColors.emerald : AppColors.cyan.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Text(day.icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr(day.title),
                            style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isCompleted)
                          const Icon(Icons.check_circle, color: AppColors.emerald, size: 20),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr(day.subtitle),
                      style: t.bodySmall?.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tr(day.overview),
            style: t.bodySmall?.copyWith(height: 1.4, fontSize: 12.5, color: AppColors.cream.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 10),

          // Key takeaways
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in day.keyTakeaways)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✓ ', style: TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.bold)),
                        Expanded(child: Text(tr(item), style: const TextStyle(fontSize: 11.5, height: 1.35))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openAction(context),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(tr('Start Lesson')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cyan,
                    side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.6)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (!isCompleted)
                FilledButton(
                  onPressed: onComplete,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.black,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(tr('Mark Done (+10 XP)')),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tr('Completed'),
                    style: const TextStyle(fontSize: 11, color: AppColors.emerald, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

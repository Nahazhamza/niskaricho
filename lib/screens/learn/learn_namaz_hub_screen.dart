import 'package:material_ui/material_ui.dart';

import '../../l10n/tr.dart';
import '../../models/learn_namaz_model.dart';
import '../../services/learn_namaz_content.dart';
import '../../services/learn_namaz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fx.dart';
import 'beginner_path_screen.dart';
import 'learn_settings_sheet.dart';
import 'prayers_breakdown_screen.dart';
import 'recitation_library_screen.dart';
import 'salah_guide_screen.dart';
import 'wudu_tutorial_screen.dart';

class LearnNamazHubScreen extends StatelessWidget {
  const LearnNamazHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = LearnNamazService.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Learn Namaz')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: tr('Learning Settings'),
            onPressed: () => LearnSettingsSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<LearnProgress>(
          valueListenable: s.progress,
          builder: (context, prog, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Hero Welcome Banner
              GlassCard(
                glow: AppColors.emerald,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.emerald.withValues(alpha: 0.2),
                            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.5)),
                          ),
                          child: const Center(
                            child: Text('📖', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('Learn Namaz'),
                                style: t.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tr('Step-by-step Islamic prayer & purification guide'),
                                style: t.bodySmall?.copyWith(color: AppColors.cyan),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      tr('Learn how to perform Salah, step by step, with Arabic recitations, translations, and visual guidance.'),
                      style: t.bodyMedium?.copyWith(height: 1.4, color: AppColors.cream),
                    ),
                    const SizedBox(height: 14),

                    // Quick Stats Row
                    Row(
                      children: [
                        _quickStat('💧 ${tr('Wudu')}', prog.completedWudu ? tr('Completed') : tr('In Progress'), prog.completedWudu ? AppColors.emerald : AppColors.gold),
                        _quickStat('🕋 ${tr('Prayers')}', '${prog.completedPrayers.length}/5', AppColors.cyan),
                        _quickStat('📿 ${tr('Recitations')}', '${prog.masteredRecitations.length}/${LearnNamazContent.recitations.length}', AppColors.violet),
                        _quickStat('⚡ ${tr('Learning XP')}', '+${prog.xpEarned}', AppColors.gold),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 7-Day Beginner Path Highlight Card
              Pressable(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BeginnerPathScreen()),
                ),
                child: GlassCard(
                  glow: AppColors.gold,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withValues(alpha: 0.2),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
                        ),
                        child: const Center(
                          child: Text('🌱', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  tr('Beginner 7-Day Path'),
                                  style: t.titleMedium?.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${prog.beginnerDayCompleted}/7 ${tr('Done')}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.gold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('Gentle step-by-step roadmap from Wudu to your first full prayer.'),
                              style: t.bodySmall?.copyWith(fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Category 1: Learn Wudu
              _CategoryHubCard(
                icon: '💧',
                title: tr('1. Learn Wudu'),
                subtitle: tr('Complete ablution guide: 12 illustrated steps, conditions, Farḍ vs Sunnah, and post-Wudu supplications.'),
                badge: prog.completedWudu ? tr('COMPLETED') : tr('12 STEPS'),
                badgeColor: prog.completedWudu ? AppColors.emerald : AppColors.cyan,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WuduTutorialScreen()),
                ),
              ),
              const SizedBox(height: 12),

              // Category 2: Five Daily Prayers Breakdown
              _CategoryHubCard(
                icon: '🕋',
                title: tr('2. Five Daily Prayers'),
                subtitle: tr('Obligatory Farḍ rak\'ahs and Sunnah prayers clearly separated for Fajr, Dhuhr, Asr, Maghrib, and Isha.'),
                badge: '${prog.completedPrayers.length}/5 ${tr('PRAYERS')}',
                badgeColor: AppColors.gold,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrayersBreakdownScreen()),
                ),
              ),
              const SizedBox(height: 12),

              // Category 3: Step-by-Step Salah Guide
              _CategoryHubCard(
                icon: '🧍',
                title: tr('3. Step-by-Step Salah Guide'),
                subtitle: tr('Interactive visual guide covering all 13 positions: Takbir, Qiyam, Ruku, Sujood, Tashahhud, and Tasleem.'),
                badge: tr('INTERACTIVE'),
                badgeColor: AppColors.emerald,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SalahGuideScreen()),
                ),
              ),
              const SizedBox(height: 12),

              // Category 4: Recitations & Duas
              _CategoryHubCard(
                icon: '📿',
                title: tr('4. Recitations & Duas'),
                subtitle: tr('Audio recitations, Surahs, Tashahhud, Durood Ibrahim, and line-by-line translation and pronunciation.'),
                badge: '${prog.masteredRecitations.length} ${tr('LEARNED')}',
                badgeColor: AppColors.violet,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RecitationLibraryScreen()),
                ),
              ),
              const SizedBox(height: 12),

              // Category 5: My Learning Progress
              _CategoryHubCard(
                icon: '📊',
                title: tr('5. My Learning Progress'),
                subtitle: tr('Track your completed tutorials, mastered prayers, and learning XP rewards.'),
                badge: '+${prog.xpEarned} XP',
                badgeColor: AppColors.gold,
                onTap: () => _showProgressDetails(context, prog),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickStat(String label, String value, Color color) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    ),
  );

  void _showProgressDetails(BuildContext context, LearnProgress prog) {
    final t = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF071C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Text(tr('My Learning Progress'), style: t.titleLarge),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '+${prog.xpEarned} XP',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                prog.completedWudu ? Icons.check_circle : Icons.radio_button_unchecked,
                color: prog.completedWudu ? AppColors.emerald : AppColors.muted,
              ),
              title: Text(tr('Wudu Tutorial')),
              trailing: Text(prog.completedWudu ? tr('Completed (+15 XP)') : tr('Not completed')),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                prog.completedPrayers.length == 5 ? Icons.check_circle : Icons.radio_button_unchecked,
                color: prog.completedPrayers.length == 5 ? AppColors.emerald : AppColors.cyan,
              ),
              title: Text(tr('Prayers Guided')),
              trailing: Text('${prog.completedPrayers.length}/5 ${tr('prayers')}'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                prog.beginnerDayCompleted == 7 ? Icons.check_circle : Icons.radio_button_unchecked,
                color: prog.beginnerDayCompleted == 7 ? AppColors.emerald : AppColors.gold,
              ),
              title: Text(tr('Beginner Path')),
              trailing: Text('${prog.beginnerDayCompleted}/7 ${tr('days')}'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bookmark, color: AppColors.violet),
              title: Text(tr('Recitations Mastered')),
              trailing: Text('${prog.masteredRecitations.length} ${tr('recitations')}'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _CategoryHubCard extends StatelessWidget {
  const _CategoryHubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Pressable(
      onTap: onTap,
      child: GlassCard(
        glow: badgeColor,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor.withValues(alpha: 0.15),
                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: t.bodySmall?.copyWith(fontSize: 11.5, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../services/hijri.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/look.dart';
import 'fx.dart';

/// Design switch (Night sky / Masjid), Lite mode for older phones, the Hijri
/// date adjustment, and account deletion.
class AppearanceCard extends StatelessWidget {
  const AppearanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final look = LookScope.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('🎨 Appearance'), style: t.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final s in AppStyle.values) ...[
                Expanded(
                  child: Pressable(
                    onTap: () {
                      Look.style.value = s;
                      Look.save();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: look.style == s ? AppColors.gold : Colors.white24,
                          width: look.style == s ? 2 : 1,
                        ),
                        gradient: LinearGradient(
                          colors: s == AppStyle.nightSky
                              ? const [Color(0xFF030A12), Color(0xFF14403A)]
                              : const [Color(0xFF0A1A2A), Color(0xFF0B2420)],
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(s == AppStyle.nightSky ? '✨' : '🕌', style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(tr(s.label), style: t.titleSmall),
                          Text(tr(s.blurb), textAlign: TextAlign.center, style: t.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ),
                if (s != AppStyle.values.last) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Lite mode (older phones)')),
            subtitle: Text(tr('No blur, no moving background, no entrance animations. Saves battery.')),
            value: Look.lite.value,
            onChanged: (v) {
              Look.lite.value = v;
              Look.save();
            },
          ),
          const Divider(height: 18),
          ValueListenableBuilder<int>(
            valueListenable: Look.hijriAdjust,
            builder: (_, adj, _) {
              final h = HijriDate.fromDate(SupabaseService.instance.myToday, adjust: adj);
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('🌙 Hijri date'), style: t.titleSmall),
                        Text('${h.ml}\n${h.en}', style: t.bodySmall),
                        Text(
                          tr('Adjust to match your local moon sighting.'),
                          style: t.bodySmall?.copyWith(fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: tr('One day earlier'),
                    onPressed: adj > -2 ? () => _setAdj(adj - 1) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(adj == 0 ? '0' : '${adj > 0 ? '+' : ''}$adj', style: t.titleSmall),
                  IconButton(
                    tooltip: tr('One day later'),
                    onPressed: adj < 2 ? () => _setAdj(adj + 1) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 18),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.missed),
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
            label: Text(tr('Delete my account and data')),
          ),
        ],
      ),
    );
  }

  static void _setAdj(int v) {
    Look.hijriAdjust.value = v;
    Look.save();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final db = SupabaseService.instance;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('Delete your account?')),
        content: Text(
          tr(
            'This permanently removes your profile, prayer history, streaks and photos. Circles you created are passed to another member. This cannot be undone.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Keep my account'))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Delete'))),
        ],
      ),
    );
    if (ok != true) return;
    if (db.isDemo) {
      messenger.showSnackBar(
        SnackBar(content: Text(tr('Demo: in the real app your account and data are deleted now.'))),
      );
      return;
    }
    try {
      await db.deleteMyAccount();
    } on ServerRuleException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../models/prayer_model.dart';
import '../services/supabase_service.dart';
import '../services/zones.dart';
import '../theme/app_theme.dart';
import 'fx.dart';

/// Private haid / nifas pause. Only visible to the woman herself: the circle
/// sees "Not shared" (the same as anyone who keeps their status private).
class WomenCard extends StatefulWidget {
  const WomenCard({super.key});

  @override
  State<WomenCard> createState() => _WomenCardState();
}

class _WomenCardState extends State<WomenCard> {
  final _db = SupabaseService.instance;
  bool _busy = false;
  bool _showRules = false;

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _start(String kind) async {
    setState(() => _busy = true);
    try {
      await _db.startExcused(kind);
      _toast(
        kind == 'haid'
            ? tr('Marked privately. Salah is excused with no qada, and your streak is paused.')
            : tr('Marked privately. May Allah make it easy. Salah is excused with no qada.'),
      );
    } on ServerRuleException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _end() async {
    setState(() => _busy = true);
    try {
      final current = _currentPrayer();
      await _db.endExcused();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(tr('Alhamdulillah')),
          content: Text(_dueText(current)),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('OK')))],
        ),
      );
    } on ServerRuleException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  PrayerName? _currentPrayer() {
    final loc = _db.myLocation;
    if (loc == null) return null;
    final now = _db.serverNow;
    final calc = _db.myCalculator();
    final today = calc.windowsFor(loc, _db.myToday);
    final y = calc.windowsFor(loc, _db.myToday.subtract(const Duration(days: 1)));
    return calc.currentWindow(today, y, now)?.prayer;
  }

  /// Which prayers become due when bleeding stops now.
  String _dueText(PrayerName? p) {
    final ghusl = tr('Make ghusl first, then pray.');
    if (p == null) {
      return '$ghusl ${tr('No prayer time is running right now, so the next prayer is the first one due.')}';
    }
    final shafi = _db.myMadhab == 'shafi';
    final also = !shafi
        ? null
        : p == PrayerName.asr
        ? PrayerName.dhuhr
        : p == PrayerName.isha
        ? PrayerName.maghrib
        : null;
    return also == null
        ? '$ghusl ${tr('{prayer} is due now, while its time lasts.', {'prayer': p.label})}'
        : '$ghusl ${tr("{prayer} is due now. In the Shafi'i school {also} is also due, because purity came in {prayer} time. You can log {also} too.", {'prayer': p.label, 'also': also.label})}';
  }

  static List<String> get _shafiRules => [
    tr("Shafi'i school:"),
    tr('• Haid: at least 24 hours, usually 6 or 7 days, at most 15 days. At least 15 days of purity between periods.'),
    tr('• Nifas: usually 40 days, at most 60.'),
    tr('• No salah and no qada during haid or nifas.'),
    tr(
      '• If bleeding starts after a prayer time began and there was time to pray it, that prayer is owed (the app allows 5 minutes).',
    ),
    tr(
      '• When bleeding stops within a prayer time, that prayer is due. If it stops in Asr time, Dhuhr is also due. In Isha time, Maghrib too. Ghusl first.',
    ),
    tr(
      '• Bleeding beyond the maximum, or too soon after the last period, is istihada: pray, with a fresh wudu for each prayer.',
    ),
    tr('These are general rules. For your own situation, ask a scholar you trust.'),
  ];

  static List<String> get _hanafiRules => [
    tr('Hanafi school:'),
    tr('• Haid: 3 to 10 days. At least 15 days of purity between periods.'),
    tr('• Nifas: at most 40 days.'),
    tr('• No salah and no qada during haid or nifas.'),
    tr('• When bleeding stops, only the current prayer is due, if there is time for ghusl and the opening takbir.'),
    tr('• Istihada: pray, with one wudu for each prayer time.'),
    tr('These are general rules. For your own situation, ask a scholar you trust.'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final open = _db.openPeriod;
    final fmt = DateFormat('d MMM, h:mm a', L10n.lang.value.name);
    final history = _db.myPeriods.where((p) => !p.isOpen).take(6).toList();
    final shafi = _db.myMadhab == 'shafi';
    String kindName(String k) => k == 'haid' ? tr('Haid') : tr('Nifas');
    return GlassCard(
      glow: open != null ? const Color(0xFFE9D5FF) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('🤍 ${tr('Haid and Nifas')}', style: t.titleMedium)),
              const Icon(Icons.lock_outline, size: 16, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(tr('Private'), style: t.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          if (open != null) ...[
            Text(
              tr('{kind} since {date}. Salah is excused and needs no qada. Your streak is paused, not broken.', {
                'kind': kindName(open.kind),
                'date': fmt.format(Zones.wall(open.startedAt, _db.myTimezone)),
              }),
              style: t.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              tr('Counts at most {n} days ({school}). After that it is istihada and salah is due again.', {
                'n': ExcusedPeriod.maxFor(open.kind, _db.myMadhab).inDays,
                'school': shafi ? tr("Shafi'i") : tr('Hanafi'),
              }),
              style: t.bodySmall,
            ),
            const SizedBox(height: 10),
            FilledButton(onPressed: _busy ? null : _end, child: Text(tr('Bleeding has stopped'))),
          ] else ...[
            Text(
              tr('Mark the start privately. Prayers in that time are shown to you as excused, never as missed.'),
              style: t.bodyMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _start('haid'),
                    child: Text(tr('Haid started')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _start('nifas'),
                    child: Text(tr('Nifas started')),
                  ),
                ),
              ],
            ),
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(tr('Your history (only you can see this)'), style: t.titleSmall),
            for (final p in history)
              Text(
                '${kindName(p.kind)} · ${fmt.format(Zones.wall(p.startedAt, _db.myTimezone))} · '
                '${tr('{n} days', {'n': (p.effectiveEnd(_db.myMadhab).difference(p.startedAt).inHours / 24).toStringAsFixed(1)})}',
                style: t.bodySmall,
              ),
          ],
          TextButton(
            onPressed: () => setState(() => _showRules = !_showRules),
            child: Text(_showRules ? tr('Hide the rules') : tr('How the app applies the rules')),
          ),
          if (_showRules)
            Text((shafi ? _shafiRules : _hanafiRules).join('\n'), style: t.bodySmall?.copyWith(height: 1.45)),
        ],
      ),
    );
  }
}

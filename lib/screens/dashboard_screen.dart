import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../models/prayer_model.dart';
import '../models/progress_model.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../services/hijri.dart';
import '../services/zones.dart';
import '../theme/look.dart';
import '../theme/app_theme.dart';
import '../widgets/fx.dart';
import '../widgets/islamic_icons.dart';
import 'focus_timer_screen.dart';
import 'photo_proof_screen.dart';
import 'tasbih_screen.dart';

/// Today: the sun's path through the five prayers, a live countdown,
/// level + XP, and one glass card per prayer.
///
/// Buttons are driven by the SERVER windows and the server-corrected clock,
/// so changing the phone's time cannot unlock a prayer early.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = SupabaseService.instance;
  Timer? _tick;
  List<PrayerWindow> _today = [];
  List<PrayerWindow> _yesterday = [];
  Map<PrayerName, PrayerLog> _logs = {};
  Map<PrayerName, PrayerLog> _yesterdayLogs = {};
  Progress? _progress;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // Re-sync when a window boundary passes so statuses flip on time.
      final crossed = _today.any((w) => _justCrossed(w.start) || _justCrossed(w.end));
      if (crossed) _load();
      setState(() {});
    });
  }

  bool _justCrossed(DateTime t) {
    final d = _db.serverNow.difference(t).inMilliseconds;
    return d >= 0 && d < 1000;
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final todayDate = _db.myToday;
      final today = await _db.fetchMyWindows(todayDate);
      final yesterdayDate = todayDate.subtract(const Duration(days: 1));
      final yesterday = await _db.fetchMyWindows(yesterdayDate);
      final logs = await _db.myLogsFor(todayDate);
      final yLogs = await _db.myLogsFor(yesterdayDate);
      final progress = await _db.myProgress();
      if (_db.myGender == 'female') await _db.loadMyPeriods();
      if (!mounted) return;
      setState(() {
        _today = today;
        _yesterday = yesterday;
        _logs = {for (final l in logs) l.prayer: l};
        _yesterdayLogs = {for (final l in yLogs) l.prayer: l};
        _progress = progress;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e is ServerRuleException ? e.message : '$e');
    }
  }

  PrayerWindow? get _active {
    final now = _db.serverNow;
    for (final w in [..._yesterday.where((w) => w.prayer == PrayerName.isha), ..._today]) {
      if (w.isOpenAt(now)) return w;
    }
    return null;
  }

  PrayerWindow? get _next {
    final now = _db.serverNow;
    for (final w in _today) {
      if (w.start.isAfter(now)) return w;
    }
    return null;
  }

  PrayerStatus _statusOf(PrayerWindow w, PrayerLog? log) {
    final now = _db.serverNow;
    if (log == null && !w.start.isAfter(now) && _db.isExcused(w)) return PrayerStatus.excused;
    return log?.status ??
        (w.isOpenAt(now)
            ? PrayerStatus.pending
            : w.hasEndedAt(now)
            ? PrayerStatus.missed
            : PrayerStatus.upcoming);
  }

  // ------------------------------------------------------------------ actions
  Future<void> _prayNow(PrayerName p, {DateTime? qadaDate}) async {
    final levelBefore = _progress?.level ?? 1;
    try {
      final log = await _db.startPrayer(p, qadaDate: qadaDate);
      if (!mounted) return;
      var done = await Navigator.of(context)
          .push<PrayerLog>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => FocusTimerScreen(log: log)));
      if (done != null) {
        await NotificationService.instance.cancelWarning(p);
        if (await _db.anyCircleRequiresPhoto() && mounted) {
          final withPhoto = await Navigator.of(context)
              .push<bool>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => PhotoProofScreen(log: done!)));
          if (withPhoto == true) {
            done = (await _db.myLogsFor(done.prayerDate)).firstWhere((l) => l.id == done!.id, orElse: () => done!);
          }
        }
        await _load();
        if (!mounted) return;
        final xp = xpForLog(done);
        final perfect = _logs.values.where((l) => l.status == PrayerStatus.onTime).length == 5;
        final levelAfter = _progress?.level ?? levelBefore;
        if (levelAfter > levelBefore) {
          final t = levelTitle(levelAfter);
          await celebrate(
            context,
            title: tr('Level {n}!', {'n': levelAfter}),
            subtitle: '${t.emoji} ${tr(t.en)}',
            emoji: '🏆',
            big: true,
          );
        } else if (perfect && done.status == PrayerStatus.onTime) {
          await celebrate(
            context,
            title: tr('Perfect day 5/5'),
            subtitle: '+$xp XP  ${tr('+{n} bonus · Masha Allah!', {'n': perfectDayBonus})}',
            emoji: '🌟',
            big: true,
          );
        } else {
          await celebrate(
            context,
            title: '+$xp XP · ${done.status.label}',
            subtitle: tr('May Allah accept it 🤲'),
            emoji: done.status == PrayerStatus.onTime ? '🟢' : '🟡',
          );
        }
      }
    } on ServerRuleException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    await _load();
  }

  // ------------------------------------------------------------------ UI
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (_loading && _error == null) return const Center(child: CircularProgressIndicator());

    final statuses = {for (final w in _today) w.prayer: _statusOf(w, _logs[w.prayer])};
    final active = _active;
    final now = _db.serverNow;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            SafeArea(bottom: false, child: _header(t, statuses)),
            if (_error != null) GlassCard(glow: AppColors.missed, child: Text(_error!)),
            if (_db.openPeriod != null)
              GlassCard(
                glow: const Color(0xFFE9D5FF),
                child: Text(
                  '🤍 ${_db.openPeriod!.kind == 'nifas' ? tr('Nifas') : tr('Haid')}: ${tr('Salah is excused, no qada. Your streak is paused, not broken. Only you see this. When the bleeding stops, tap "Bleeding has stopped" in Journey.')}',
                  style: t.bodySmall,
                ),
              ),
            RiseIn(
              child: GlassCard(
                glow: active != null && active.remainingAt(now) <= const Duration(minutes: 20)
                    ? AppColors.missed
                    : AppColors.emerald,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                child: Column(
                  children: [
                    _CountdownHero(active: active, next: _next, now: now),
                    const SizedBox(height: 6),
                    SkyArc(windows: _today, now: now, statuses: statuses),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            RiseIn(index: 1, child: _quickActions(t)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                tr("TODAY'S PRAYERS"),
                style: t.bodySmall?.copyWith(letterSpacing: 2, fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                '📍 ${_db.myPlaceLabel} · ${Zones.offsetLabel(_db.myTimezone)} · ${calcMethodLabels[_db.myMethod] ?? _db.myMethod}'
                '${_db.myMadhab == 'hanafi' ? ' · ${tr('Hanafi Asr')}' : ''}',
                style: t.bodySmall?.copyWith(fontSize: 11, color: AppColors.muted),
              ),
            ),
            for (final (i, w) in _today.indexed) RiseIn(index: i + 2, child: _buildCard(w, _logs[w.prayer], null)),
            // Isha of yesterday is still live until Fajr.
            if (active != null && active.prayer == PrayerName.isha && _yesterday.contains(active))
              _buildCard(active, _yesterdayLogs[PrayerName.isha], tr('Last night')),
          ],
        ),
      ),
    );
  }

  Widget _header(TextTheme t, Map<PrayerName, PrayerStatus> statuses) {
    final p = _progress;
    final title = levelTitle(p?.level ?? 1);
    final onTime = statuses.values.where((s) => s == PrayerStatus.onTime).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          PrayerRings(
            size: 92,
            statuses: [for (final n in PrayerName.values) statuses[n] ?? PrayerStatus.upcoming],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$onTime/5', style: t.titleLarge?.copyWith(color: AppColors.gold, fontSize: 22)),
                Text(tr('today'), style: t.bodySmall?.copyWith(fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Niskaricho?'), style: t.headlineMedium?.copyWith(fontSize: 24)),
                ValueListenableBuilder<int>(
                  valueListenable: Look.hijriAdjust,
                  builder: (_, adj, _) {
                    final h = HijriDate.fromDate(_db.myToday, adjust: adj);
                    return Text(
                      '🌙 ${h.label}${_db.myToday.weekday == DateTime.friday ? ' · ${tr("Jumu'ah")}' : ''}',
                      style: t.bodySmall?.copyWith(fontSize: 11, color: AppColors.gold),
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  '${title.emoji} ${tr('Level {n}', {'n': p?.level ?? 1})} · ${tr(title.en)}',
                  style: t.titleMedium?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 6),
                NeonBar(value: p?.levelProgress ?? 0, height: 8),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${p?.xp ?? 0} XP', style: t.bodySmall),
                    const Spacer(),
                    Text(
                      '🔥 ${trn('1 day', '{n} days', p?.streak.currentDays ?? 0)}',
                      style: t.bodySmall?.copyWith(color: AppColors.gold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(TextTheme t) => Row(
    children: [
      Expanded(
        child: Pressable(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasbihScreen())),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              children: [
                const Text('📿', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(child: Text(tr('Tasbih after salah'), style: const TextStyle(fontSize: 14, height: 1.25))),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('{n} XP\nthis week', {'n': _progress?.weekXp ?? 0}),
                  style: const TextStyle(fontSize: 12.5, height: 1.25),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildCard(PrayerWindow w, PrayerLog? log, String? tag) {
    final now = _db.serverNow;
    final status = _statusOf(w, log);
    final isYesterdayIsha = tag != null;
    final prayerDate = isYesterdayIsha ? _db.myToday.subtract(const Duration(days: 1)) : _db.myToday;

    Widget? action;
    if (status == PrayerStatus.excused) {
      action = const Text('🤍', style: TextStyle(fontSize: 18)); // no salah, no qada
    } else if (w.isOpenAt(now) && (log == null || log.status == PrayerStatus.inProgress)) {
      action = _GlowButton(
        label: log?.status == PrayerStatus.inProgress ? tr('Start again') : tr('Pray Now'),
        onTap: () => _prayNow(w.prayer),
      );
    } else if (w.hasEndedAt(now) && (log == null || log.status == PrayerStatus.missed)) {
      action = OutlinedButton(
        onPressed: () => _prayNow(w.prayer, qadaDate: prayerDate),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.qada,
          side: BorderSide(color: AppColors.qada.withValues(alpha: 0.6)),
        ),
        child: Text(tr('Log Qada')),
      );
    } else if (!w.hasEndedAt(now) && !w.isOpenAt(now)) {
      action = const Icon(Icons.lock_clock, color: AppColors.muted); // cannot log in advance
    } else if (log != null && log.status.isDone) {
      action = Text(
        '+${xpForLog(log)} XP',
        style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 13),
      );
    }

    return _PrayerCard(window: w, status: status, log: log, tag: tag, action: action, live: w.isOpenAt(now));
  }
}

// ---------------------------------------------------------------------------
class _CountdownHero extends StatelessWidget {
  const _CountdownHero({required this.active, required this.next, required this.now});
  final PrayerWindow? active;
  final PrayerWindow? next;
  final DateTime now;

  String _fmt(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    return h > 0
        ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final a = active;
    final urgent = a != null && a.remainingAt(now) <= const Duration(minutes: 20);
    final digits = TextStyle(
      fontSize: 46,
      fontWeight: FontWeight.w200,
      letterSpacing: 2,
      color: AppColors.cream,
      fontFeatures: const [FontFeature.tabularFigures()],
      shadows: [Shadow(color: (urgent ? AppColors.missed : AppColors.cyan).withValues(alpha: 0.7), blurRadius: 18)],
    );
    if (a == null) {
      return Column(
        children: [
          Text(
            '${tr('NEXT')} · ${next?.prayer.label ?? PrayerName.fajr.label}',
            style: t.bodySmall?.copyWith(letterSpacing: 3, color: AppColors.cyan),
          ),
          const SizedBox(height: 4),
          if (next != null) Text(_fmt(next!.start.difference(now)), style: digits),
          Text(
            next != null
                ? tr('until the adhan of {prayer}', {'prayer': next!.prayer.label})
                : tr('Rest well. Fajr comes soon 🌙'),
            style: t.bodySmall,
          ),
        ],
      );
    }
    return Column(
      children: [
        Text(a.prayer.label, style: t.titleMedium?.copyWith(color: AppColors.gold, letterSpacing: 1.5)),
        const SizedBox(height: 2),
        Text(
          urgent ? tr('TIME IS ENDING') : tr('TIME LEFT'),
          style: t.bodySmall?.copyWith(letterSpacing: 3, color: urgent ? AppColors.missed : AppColors.cyan),
        ),
        Text(_fmt(a.remainingAt(now)), style: digits),
        Text(tr('ends at {time}', {'time': Zones.hm(a.end, SupabaseService.instance.myTimezone)}), style: t.bodySmall),
      ],
    );
  }
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFFF0CF7A), AppColors.gold]),
        boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.55), blurRadius: 18, spreadRadius: -2)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MusallaIcon(size: 18, color: AppColors.night),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.night, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({required this.window, required this.status, this.log, this.tag, this.action, this.live = false});
  final PrayerWindow window;
  final PrayerStatus status;
  final PrayerLog? log;
  final String? tag;
  final Widget? action;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tzId = SupabaseService.instance.myTimezone;
    final jumuah = window.prayer == PrayerName.dhuhr && SupabaseService.instance.myToday.weekday == DateTime.friday;
    final color = AppColors.forStatus(status);
    return GlassCard(
      glow: live ? AppColors.gold : (status.isDone ? color.withValues(alpha: 0.6) : null),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
              boxShadow: status.isDone ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 14)] : null,
            ),
            child: Text(status.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // On Friday, Dhuhr is Jumu'ah (same window).
                    Text(jumuah ? tr("Jumu'ah") : window.prayer.label, style: t.titleMedium),
                    if (tag != null) ...[const SizedBox(width: 8), Text('· $tag', style: t.bodySmall)],
                  ],
                ),
                const SizedBox(height: 2),
                Text('${Zones.hm(window.start, tzId)} – ${Zones.hm(window.end, tzId)}', style: t.bodySmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    GlowChip(status.label, color),
                    if (log?.focusVerified ?? false) GlowChip(tr('⏱️ Focus'), AppColors.cyan),
                    if (log?.hasPhoto ?? false) GlowChip(tr('📸 Photo'), AppColors.gold),
                    if (window.prayer == PrayerName.fajr && status == PrayerStatus.onTime)
                      GlowChip(tr('2× XP'), AppColors.violet),
                  ],
                ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

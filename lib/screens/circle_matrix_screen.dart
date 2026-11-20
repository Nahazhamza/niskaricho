import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../models/circle_model.dart';
import '../models/prayer_model.dart';
import '../models/progress_model.dart';
import '../services/supabase_service.dart';
import '../services/zones.dart';
import '../theme/app_theme.dart';
import '../widgets/circle_members_sheet.dart';
import '../widgets/fx.dart';

/// The Live Squad Dashboard: a co-op weekly quest, members (rows) × today's
/// 5 prayers (columns), nudges, reactions, and a weekly XP league.
///
/// Every status comes from the server (`get_circle_matrix`), computed from
/// each member's own location and the server clock. Realtime pushes a
/// refresh whenever any member's log changes.
class CircleMatrixScreen extends StatefulWidget {
  const CircleMatrixScreen({super.key, required this.circle});
  final Circle circle;

  @override
  State<CircleMatrixScreen> createState() => _CircleMatrixScreenState();
}

class _CircleMatrixScreenState extends State<CircleMatrixScreen> {
  final _db = SupabaseService.instance;
  List<MatrixRow> _rows = [];
  List<LeaderboardEntry> _league = [];
  CircleQuest? _quest;
  int _fajrStreak = 0;
  Unsubscribe? _channel;
  Timer? _minuteTick;
  bool _loading = true;
  int _view = 0; // 0 = today, 1 = league

  @override
  void initState() {
    super.initState();
    _load();
    _channel = _db.watchCircle(widget.circle.id, _load);
    // Windows open/close with time even when nobody logs anything.
    _minuteTick = Timer.periodic(const Duration(minutes: 1), (_) => _load());
  }

  @override
  void dispose() {
    _minuteTick?.cancel();
    _channel?.call();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await _db.circleMatrix(widget.circle.id);
      final streak = await _db.circleFajrStreak(widget.circle.id);
      final league = await _db.leaderboard(widget.circle.id);
      final quest = await _db.circleQuest(widget.circle.id);
      if (!mounted) return;
      setState(() {
        _rows = rows..sort((a, b) => b.onTimeCount.compareTo(a.onTimeCount));
        _fajrStreak = streak;
        _league = league;
        _quest = quest;
        _loading = false;
      });
    } on ServerRuleException catch (e) {
      _toast(e.message);
    }
  }

  void _toast(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _nudge(MatrixRow r, PrayerName p) async {
    try {
      await _db.sendNudge(widget.circle.id, r.userId, p);
      _toast(
        '👋 ${tr('Reminder sent to {name}: "It is {prayer} time. Did you pray?"', {'name': r.displayName, 'prayer': p.label})}',
      );
      await _load();
    } on ServerRuleException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _openCell(MatrixRow r, MatrixCell c) async {
    final isMe = r.userId == _db.userId;
    final image = c.hasPhoto ? await _db.photoImage(c.photoPath!) : null;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0C1F1C),
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${r.displayName} · ${c.prayer.label}',
              style: Theme.of(ctx).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              tr('{prayer} time in {place} ({zone}): {from} to {to}', {
                'prayer': c.prayer.label,
                'place': r.place ?? tr('their place'),
                'zone': Zones.offsetLabel(r.timezone),
                'from': Zones.hm(c.windowStart, r.timezone),
                'to': Zones.hm(c.windowEnd, r.timezone),
              }),
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            if (Zones.offsetLabel(r.timezone) != Zones.offsetLabel(_db.myTimezone))
              Text(
                tr('Your time: {from} to {to}', {
                  'from': Zones.hm(c.windowStart, _db.myTimezone),
                  'to': Zones.hm(c.windowEnd, _db.myTimezone),
                }),
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              children: [
                GlowChip('${c.status.emoji} ${c.status.label}', AppColors.forStatus(c.status)),
                if (c.focusVerified) GlowChip(tr('⏱️ Focus verified'), AppColors.cyan),
                if (c.reactionCount > 0)
                  GlowChip('💬 ${tr('{n} encouragements', {'n': c.reactionCount})}', AppColors.violet),
              ],
            ),
            if (image != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Image(image: image, fit: BoxFit.cover),
                ),
              ),
            ],
            if (!isMe && c.logId != null) ...[
              const SizedBox(height: 18),
              Text(tr('Send encouragement'), textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final e in reactionEmojis)
                    Pressable(
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          await _db.react(c.logId!, e);
                          _toast('$e ${tr('sent to {name}. May Allah accept it!', {'name': r.displayName})}');
                          await _load();
                        } on ServerRuleException catch (err) {
                          _toast(err.message);
                        }
                      },
                      child: Container(
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.myReaction == e ? AppColors.gold.withValues(alpha: 0.25) : Colors.white10,
                          border: Border.all(color: c.myReaction == e ? AppColors.gold : Colors.white12),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pct = (circleCompletion(_rows) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.circle.name),
        actions: [
          if (widget.circle.createdBy == _db.userId || _db.isAdmin)
            IconButton(
              tooltip: tr('Members and requests'),
              icon: const Icon(Icons.manage_accounts_outlined),
              onPressed: () async {
                await showCircleMembersSheet(context, widget.circle, _rows);
                await _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  if (_quest != null) RiseIn(child: _QuestCard(quest: _quest!)),
                  RiseIn(
                    index: 1,
                    child: Row(
                      children: [
                        Expanded(
                          child: _Stat(label: tr('Circle on-time today'), value: '$pct%', color: AppColors.emerald),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Stat(
                            label: tr('Full Circle Fajr 🌅'),
                            value: trn('1 day', '{n} days', _fajrStreak),
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(value: 0, label: Text(tr('Today')), icon: Icon(Icons.grid_view_rounded)),
                      ButtonSegment(
                        value: 1,
                        label: Text(tr('Weekly league')),
                        icon: Icon(Icons.emoji_events_outlined),
                      ),
                    ],
                    selected: {_view},
                    onSelectionChanged: (s) => setState(() => _view = s.first),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _view == 0
                        ? Column(
                            key: const ValueKey('grid'),
                            children: [
                              _header(t),
                              for (final (i, r) in _rows.indexed) RiseIn(index: i, child: _row(r, t)),
                              const SizedBox(height: 14),
                              const _Legend(),
                            ],
                          )
                        : Column(
                            key: const ValueKey('league'),
                            children: [
                              for (final (i, e) in _league.indexed) RiseIn(index: i, child: _leagueRow(i, e, t)),
                              const SizedBox(height: 10),
                              Text(
                                tr('League resets every Monday. XP comes only from verified prayers.'),
                                textAlign: TextAlign.center,
                                style: t.bodySmall,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _header(TextTheme t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        const Expanded(flex: 3, child: SizedBox()),
        for (final p in PrayerName.values)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  p.label,
                  style: t.bodySmall?.copyWith(color: AppColors.gold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _row(MatrixRow r, TextTheme t) {
    final isMe = r.userId == _db.userId;
    return GlassCard(
      glow: isMe ? AppColors.gold : null,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    _Avatar(name: r.displayName, highlight: isMe),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMe ? tr('You') : r.displayName,
                            style: t.titleMedium?.copyWith(fontSize: 13.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('🔥${r.streakDays} · ${r.onTimeCount}/5', style: t.bodySmall?.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              for (final p in PrayerName.values) Expanded(flex: 2, child: _cell(r, r.cells[p])),
            ],
          ),
          // Their own clock: each member's prayers follow their local time
          // (Dubai is 1 h 30 min behind Kerala).
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              '🕐 ${tr('{time} in {place}', {'time': Zones.hm(_db.serverNow, r.timezone), 'place': r.place != null ? tr(r.place!) : (r.timezone ?? tr('their place')).split('/').last.replaceAll('_', ' ')})}'
              ' (${Zones.offsetLabel(r.timezone)})',
              style: t.bodySmall?.copyWith(fontSize: 10.5, color: AppColors.muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(MatrixRow r, MatrixCell? c) {
    if (c == null) return const SizedBox();
    final color = AppColors.forStatus(c.status);
    final badges = [if (c.focusVerified) '⏱️', if (c.hasPhoto) '📸'].join();

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: c.status == PrayerStatus.upcoming ? 0.04 : 0.14),
            boxShadow: c.status.isDone ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 10)] : null,
          ),
          child: Text(c.status == PrayerStatus.upcoming ? '·' : c.status.emoji, style: const TextStyle(fontSize: 15)),
        ),
        if (badges.isNotEmpty) Text(badges, style: const TextStyle(fontSize: 9)),
        if (c.reactionCount > 0)
          Text('${c.myReaction ?? '✨'}${c.reactionCount}', style: const TextStyle(fontSize: 9, color: AppColors.muted)),
        if (c.canNudge)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Pressable(
              onTap: () => _nudge(r, c.prayer),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF0CF7A), AppColors.gold]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.5), blurRadius: 8)],
                ),
                child: Text(
                  tr('👋 Nudge'),
                  style: TextStyle(fontSize: 9, color: AppColors.night, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          )
        else if (c.alreadyNudged)
          Text(tr('reminded'), style: const TextStyle(fontSize: 9, color: AppColors.muted)),
      ],
    );

    // Every cell opens: done ones show photo + reactions, all show the
    // member's own window in their local time.
    return Center(
      child: GestureDetector(onTap: () => _openCell(r, c), child: body),
    );
  }

  Widget _leagueRow(int i, LeaderboardEntry e, TextTheme t) {
    final medal = ['🥇', '🥈', '🥉'];
    final isMe = e.userId == _db.userId;
    final top = _league.isEmpty ? 1 : _league.first.weekXp.clamp(1, 1 << 30);
    return GlassCard(
      glow: i == 0 ? AppColors.gold : (isMe ? AppColors.cyan : null),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(i < 3 ? medal[i] : '${i + 1}', style: const TextStyle(fontSize: 20))),
          _Avatar(name: e.displayName, highlight: isMe),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMe ? tr('You') : e.displayName, style: t.titleMedium?.copyWith(fontSize: 14)),
                const SizedBox(height: 4),
                NeonBar(
                  value: e.weekXp / top,
                  height: 6,
                  colors: i == 0
                      ? const [AppColors.gold, Color(0xFFF0CF7A)]
                      : const [AppColors.emerald, AppColors.cyan],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${e.weekXp} XP', style: t.titleMedium?.copyWith(color: AppColors.gold, fontSize: 14)),
              Text(
                '${tr('Level {n}', {'n': e.level})} · 🔥${e.streakDays}',
                style: t.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest});
  final CircleQuest quest;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final daysLeft = quest.endsAt.difference(DateTime.now()).inDays + 1;
    return GlassCard(
      glow: AppColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(child: Text(tr(quest.title), style: t.titleMedium)),
              GlowChip(tr('{n} days left', {'n': daysLeft}), AppColors.violet),
            ],
          ),
          const SizedBox(height: 10),
          NeonBar(value: quest.fraction, height: 12, colors: const [AppColors.violet, AppColors.cyan, AppColors.gold]),
          const SizedBox(height: 6),
          Text(
            quest.fraction >= 1
                ? tr('Quest complete! Masha Allah, the whole circle did it 🤝')
                : tr('{done} of {goal} on-time prayers together. Everyone counts!', {
                    'done': quest.progress,
                    'goal': quest.goal,
                  }),
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.highlight = false});
  final String name;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final hue = (name.codeUnits.fold<int>(0, (a, b) => a + b) * 37) % 360;
    final c = HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.45).toColor();
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [c, c.withValues(alpha: 0.5)]),
        border: Border.all(color: highlight ? AppColors.gold : Colors.white24, width: highlight ? 2 : 1),
      ),
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            shadows: [Shadow(color: color.withValues(alpha: 0.6), blurRadius: 14)],
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final items = [
      tr('🟢 On-Time'),
      tr('⏱️ Focus Verified'),
      tr('📸 Photo Proof'),
      tr('🟡 Qada'),
      tr('🔴 Missed'),
      tr('⏳ Pending'),
      tr('🤲 Praying now'),
    ];
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 6,
          children: [for (final i in items) Text(i, style: Theme.of(context).textTheme.bodySmall)],
        ),
        const SizedBox(height: 6),
        Text(
          tr('Tap a completed prayer to see the photo or send encouragement.'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

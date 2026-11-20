import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../models/prayer_model.dart';
import '../models/progress_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fx.dart';
import '../widgets/appearance_card.dart';
import '../widgets/prayer_settings_card.dart';
import '../widgets/profile_form.dart';
import '../widgets/women_card.dart';
import 'admin_screen.dart';
import 'language_screen.dart';

/// "Journey": level, XP, streaks, a 5-week heatmap, per-prayer strength,
/// the badge cabinet and the Qibla direction.
class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  final _db = SupabaseService.instance;
  Progress? _p;
  double? _qibla;
  String? _error;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _db.myProgress();
      final prof = await _db.myProfile();
      double? q;
      if (prof['latitude'] != null) {
        q = adhan.Qibla.qibla(
          adhan.Coordinates((prof['latitude'] as num).toDouble(), (prof['longitude'] as num).toDouble()),
        );
      }
      if (mounted) {
        setState(() {
          _p = p;
          _qibla = q;
          _profile = prof;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  String _profileLine() {
    final db = SupabaseService.instance;
    final age = db.myBirthYear == null ? null : DateTime.now().year - db.myBirthYear!;
    return [
      db.myName,
      if (db.myGender != null) db.myGender == 'female' ? tr('Female') : tr('Male'),
      if (age != null) tr('about {n} years', {'n': age}),
      db.myMadhab == 'hanafi' ? tr('Hanafi') : tr("Shafi'i"),
      if (db.myMosque?.isNotEmpty ?? false) db.myMosque!,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = _p;
    if (p == null) {
      return Center(child: _error != null ? Text(_error!) : const CircularProgressIndicator());
    }
    final title = levelTitle(p.level);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            SafeArea(bottom: false, child: Text(tr('Your Journey'), style: t.headlineMedium)),
            const SizedBox(height: 8),
            if (SupabaseService.instance.isAdmin)
              GlassCard(
                glow: AppColors.gold,
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 6, 8, 6),
                  leading: const Text('🛡️', style: TextStyle(fontSize: 26)),
                  title: Text(tr('Admin'), style: t.titleMedium),
                  subtitle: Text(tr('Approve people and make invite codes')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminScreen())),
                ),
              ),
            RiseIn(child: _levelCard(p, title, t)),
            RiseIn(index: 1, child: _statsRow(p, t)),
            RiseIn(index: 2, child: _heatmap(p, t)),
            RiseIn(index: 3, child: _perPrayer(p, t)),
            RiseIn(index: 4, child: _badges(p, t)),
            if (_qibla != null) RiseIn(index: 5, child: _QiblaCard(bearing: _qibla!)),
            RiseIn(
              index: 5,
              child: GlassCard(
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  shape: const Border(),
                  title: Text(tr('👤 My profile'), style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text(_profileLine(), style: Theme.of(context).textTheme.bodySmall),
                  children: [ProfileForm(onSaved: () {})],
                ),
              ),
            ),
            if (SupabaseService.instance.myGender == 'female') const RiseIn(index: 6, child: WomenCard()),
            if (_profile != null) const RiseIn(index: 6, child: PrayerSettingsCard()),
            const RiseIn(index: 7, child: LanguageCard()),
            const RiseIn(index: 7, child: AppearanceCard()),
            const SizedBox(height: 8),
            Text(
              tr(
                'XP: On-Time 10 (Fajr 20) · Focus +5 · Photo +5 · Qada 4 · Perfect day +25.\nXP is calculated on the server from verified prayers only.',
              ),
              textAlign: TextAlign.center,
              style: t.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelCard(Progress p, ({String en, String ml, String emoji}) title, TextTheme t) => GlassCard(
    glow: AppColors.violet,
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(colors: [AppColors.violet, AppColors.cyan, AppColors.gold, AppColors.violet]),
            boxShadow: [BoxShadow(color: AppColors.violet.withValues(alpha: 0.6), blurRadius: 30)],
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0A1A1F)),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr('LV'), style: t.bodySmall?.copyWith(letterSpacing: 2, fontSize: 10)),
                  Text(
                    '${p.level}',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.cream),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${title.emoji} ${tr(title.en)}', style: t.titleLarge),
              const SizedBox(height: 10),
              NeonBar(value: p.levelProgress, colors: const [AppColors.violet, AppColors.cyan]),
              const SizedBox(height: 4),
              Text(
                tr('{xp} of {next} XP to level {n}', {'xp': p.xp, 'next': p.nextLevelXp, 'n': p.level + 1}),
                style: t.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _statsRow(Progress p, TextTheme t) {
    Widget stat(String emoji, String v, String l) => Expanded(
      child: GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            Text(v, style: t.titleLarge?.copyWith(color: AppColors.cream)),
            Text(l, style: t.bodySmall?.copyWith(fontSize: 10.5), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
    return Row(
      children: [
        stat('🔥', '${p.streak.currentDays}', tr('day streak')),
        stat('🏔️', '${p.streak.bestDays}', tr('best')),
        stat('🌅', '${p.streak.fajrCurrentDays}', tr('Fajr streak')),
        stat('⚡', '${p.weekXp}', tr('XP this week')),
      ],
    );
  }

  Widget _heatmap(Progress p, TextTheme t) {
    Color cell(DayHistory d) {
      if (d.onTime + d.qada + d.missed == 0) return Colors.white.withValues(alpha: 0.05);
      if (d.onTime == 5) return AppColors.onTime;
      return Color.lerp(AppColors.missed, AppColors.onTime, d.onTime / 5)!.withValues(alpha: 0.35 + 0.13 * d.onTime);
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tr('Last 5 weeks'), style: t.titleMedium),
              const Spacer(),
              Text(tr('{n} perfect days', {'n': p.history.where((d) => d.onTime == 5).length}), style: t.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final size = (c.maxWidth - 6 * 6) / 7;
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final (i, d) in p.history.indexed)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + i * 25),
                      builder: (_, v, _) => Tooltip(
                        message: tr('{date}: {on} on time, {qada} qada', {
                          'date': DateFormat.MMMd(L10n.lang.value.name).format(d.date),
                          'on': d.onTime,
                          'qada': d.qada,
                        }),
                        child: Container(
                          width: size,
                          height: size * 0.62,
                          decoration: BoxDecoration(
                            color: cell(d).withValues(alpha: cell(d).a * v),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: d.onTime == 5
                                ? [BoxShadow(color: AppColors.onTime.withValues(alpha: 0.5 * v), blurRadius: 8)]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text('${d.date.day}', style: const TextStyle(fontSize: 9, color: Colors.white60)),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _perPrayer(Progress p, TextTheme t) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('On-time strength (30 days)'), style: t.titleMedium),
        const SizedBox(height: 10),
        for (final n in PrayerName.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(width: 74, child: Text(n.label, style: t.bodyMedium)),
                Expanded(
                  child: NeonBar(
                    value: (p.perPrayer[n] ?? 0) / 100,
                    height: 8,
                    colors: (p.perPrayer[n] ?? 0) >= 90
                        ? const [AppColors.emerald, AppColors.onTime]
                        : const [AppColors.qada, AppColors.gold],
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text('${p.perPrayer[n] ?? 0}%', textAlign: TextAlign.right, style: t.bodySmall),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Builder(
          builder: (_) {
            final weakest = PrayerName.values.reduce((a, b) => (p.perPrayer[a] ?? 0) <= (p.perPrayer[b] ?? 0) ? a : b);
            return Text(
              '💡 ${tr('Focus on {prayer}. Ask someone in your circle to remind you.', {'prayer': weakest.label})}',
              style: t.bodySmall,
            );
          },
        ),
      ],
    ),
  );

  Widget _badges(Progress p, TextTheme t) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(tr('Badge cabinet'), style: t.titleMedium),
            const Spacer(),
            Text(
              '${badgeCatalogue.where((b) => p.badges.contains(b.code)).length}/${badgeCatalogue.length}',
              style: t.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 8,
          children: [
            for (final b in badgeCatalogue)
              Tooltip(
                message: '${tr(b.name)}\n${tr(b.how)}',
                child: _Badge(info: b, unlocked: p.badges.contains(b.code)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(tr('Tap and hold a badge to see how to earn it.'), style: t.bodySmall),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.info, required this.unlocked});
  final BadgeInfo info;
  final bool unlocked;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: unlocked ? const RadialGradient(colors: [Color(0xFF3B2F12), Color(0xFF14231E)]) : null,
      color: unlocked ? null : Colors.white.withValues(alpha: 0.04),
      border: Border.all(
        color: unlocked ? AppColors.gold.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.08),
      ),
      boxShadow: unlocked ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.35), blurRadius: 14)] : null,
    ),
    alignment: Alignment.center,
    child: Opacity(
      opacity: unlocked ? 1 : 0.25,
      child: Text(unlocked ? info.emoji : '🔒', style: const TextStyle(fontSize: 22)),
    ),
  );
}

class _QiblaCard extends StatelessWidget {
  const _QiblaCard({required this.bearing});
  final double bearing; // degrees clockwise from true north

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GlassCard(
      glow: AppColors.gold,
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: bearing),
              duration: const Duration(milliseconds: 1600),
              curve: Curves.elasticOut,
              builder: (_, v, _) => CustomPaint(painter: _CompassPainter(v)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('🕋 Qibla'), style: t.titleMedium),
                Text('ഖിബ്‌ല ദിശ', style: t.bodySmall?.copyWith(color: AppColors.gold)),
                const SizedBox(height: 6),
                Text(
                  tr('{deg}° from North', {'deg': bearing.toStringAsFixed(1)}),
                  style: t.titleLarge?.copyWith(color: AppColors.cream, fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('Point the top of your phone North, then turn {deg}° clockwise.', {'deg': bearing.round()}),
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter(this.bearing);
  final double bearing;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    canvas.drawCircle(c, r, Paint()..color = Colors.white.withValues(alpha: 0.05));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.gold.withValues(alpha: 0.4),
    );
    for (var i = 0; i < 36; i++) {
      final a = i * math.pi / 18;
      final inner = i % 9 == 0 ? r - 10 : r - 5;
      canvas.drawLine(
        c + Offset(math.sin(a) * inner, -math.cos(a) * inner),
        c + Offset(math.sin(a) * r, -math.cos(a) * r),
        Paint()..color = Colors.white.withValues(alpha: i % 9 == 0 ? 0.6 : 0.2),
      );
    }
    final tp = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c + Offset(-tp.width / 2, -r + 12));
    final a = bearing * math.pi / 180;
    final tip = c + Offset(math.sin(a) * (r - 14), -math.cos(a) * (r - 14));
    canvas.drawLine(
      c,
      tip,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.5)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawLine(
      c,
      tip,
      Paint()
        ..color = AppColors.gold
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(tip, 6, Paint()..color = AppColors.gold);
    canvas.drawCircle(c, 4, Paint()..color = AppColors.cream);
  }

  @override
  bool shouldRepaint(_CompassPainter old) => old.bearing != bearing;
}

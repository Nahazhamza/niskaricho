import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/access_model.dart';
import '../models/circle_model.dart';
import '../models/prayer_model.dart';
import '../models/progress_model.dart';

import 'dart:convert';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prayer_calculator_service.dart';
import 'zones.dart';

/// Demo mode is on when the app is started without Supabase credentials
/// (e.g. plain `flutter run -d chrome`), or with `--dart-define=DEMO=true`.
const kDemoMode = bool.fromEnvironment('DEMO') || String.fromEnvironment('SUPABASE_URL') == '';

/// Raised by the demo backend with the same codes the real SQL functions use,
/// so the UI behaves identically.
class DemoRuleException implements Exception {
  DemoRuleException(this.code, [this.hint]);
  final String code;
  final String? hint;
}

/// One sample member and where they pray from. Each member's windows come
/// from their *own* location, method and time zone, exactly like the server.
class DemoMember {
  DemoMember(this.name, this.place, this.location, {this.method = 'karachi', this.madhab = 'shafi'});
  String name;
  String place;
  UserLocation location;
  String method;
  String madhab;
  bool methodAuto = true;
  List<int> offsets = const [0, 0, 0, 0, 0];
  String? gender;
  int? birthYear;
  String? mosque;
  String language = 'ml';
  bool hideStatus = false;
  bool onboarded = true;

  /// True after you pick a city from the demo list: travel detection then
  /// leaves your pretend location alone.
  bool pinned = false;
}

/// Cities you can switch to from the Journey tab in the demo.
final demoCities = <String, (UserLocation, String)>{
  'Kozhikode': (const UserLocation(latitude: 11.2588, longitude: 75.7804, timezone: 'Asia/Kolkata'), 'karachi'),
  'Kochi': (const UserLocation(latitude: 9.9312, longitude: 76.2673, timezone: 'Asia/Kolkata'), 'karachi'),
  'Thiruvananthapuram': (const UserLocation(latitude: 8.5241, longitude: 76.9366, timezone: 'Asia/Kolkata'), 'karachi'),
  'Kannur': (const UserLocation(latitude: 11.8745, longitude: 75.3704, timezone: 'Asia/Kolkata'), 'karachi'),
  'Malappuram': (const UserLocation(latitude: 11.0510, longitude: 76.0711, timezone: 'Asia/Kolkata'), 'karachi'),
  'Dubai': (const UserLocation(latitude: 25.2048, longitude: 55.2708, timezone: 'Asia/Dubai'), 'dubai'),
  'Makkah': (const UserLocation(latitude: 21.4225, longitude: 39.8262, timezone: 'Asia/Riyadh'), 'umm_al_qura'),
  'Doha': (const UserLocation(latitude: 25.2854, longitude: 51.5310, timezone: 'Asia/Qatar'), 'qatar'),
  'Kuala Lumpur': (
    const UserLocation(latitude: 3.1390, longitude: 101.6869, timezone: 'Asia/Kuala_Lumpur'),
    'singapore',
  ),
  'London': (
    const UserLocation(latitude: 51.5074, longitude: -0.1278, timezone: 'Europe/London'),
    'muslim_world_league',
  ),
  'New York': (
    const UserLocation(latitude: 40.7128, longitude: -74.0060, timezone: 'America/New_York'),
    'north_america',
  ),
};

/// In-memory stand-in for Supabase with sample circles. It applies the same
/// rules as `schema.sql` (window checks, On-Time vs Qada, minimum focus time,
/// one nudge per prayer) so the anti-cheat flow can be tried in a browser.
/// The focus timer is shortened to 20 seconds so the demo is quick to try.
class DemoBackend {
  DemoBackend() {
    _seed();
    // A friend finishes praying a little after you open the matrix, so the
    // "live" update is visible.
    Timer(const Duration(seconds: 25), () {
      final key = _k('f2', _todayOf('f2'), _currentPrayerOf('f2') ?? PrayerName.asr);
      final l = _logs[key];
      if (l != null && l.status == PrayerStatus.inProgress) {
        _logs[key] = _copy(l, status: _statusFor(l), completedAt: _now, focusVerified: true, focusSeconds: 330);
        _changes.add(null);
      }
    });
  }

  static const focusDuration = Duration(seconds: 20);
  static const me = 'demo-me';
  static const samplePhoto = 'demo/sample';

  final people = <String, DemoMember>{
    me: DemoMember('You', 'Kozhikode', demoCities['Kozhikode']!.$1)..onboarded = false,
    'f1': DemoMember('Ameen', 'Dubai', demoCities['Dubai']!.$1, method: 'dubai'),
    'f2': DemoMember('Fathima', 'Kochi', demoCities['Kochi']!.$1)..gender = 'female',
    'f3': DemoMember('Rashid', 'Thiruvananthapuram', demoCities['Thiruvananthapuram']!.$1),
    'f4': DemoMember('Shabna', 'Kannur', demoCities['Kannur']!.$1)..gender = 'female',
  };
  DemoMember get myself => people[me]!;

  /// Your private haid / nifas history (oldest first). Shabna is shown as
  /// excused so you can see what the circle sees ("Not shared").
  final periods = <ExcusedPeriod>[];
  final _othersExcused = <String>{'f4'};

  bool _excused(String user, PrayerWindow w) {
    if (user == me) return periods.any((p) => p.covers(w, myself.madhab, _now));
    return _othersExcused.contains(user);
  }

  Map<String, String> get names => {for (final e in people.entries) e.key: e.value.name};

  final _logs = <String, PrayerLog>{};
  final _nudged = <String>{};
  final _reactions = <String, Map<String, String>>{}; // logId -> user -> emoji
  final photos = <String, Uint8List>{};
  final _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;

  final circles = <Circle>[
    const Circle(id: 'c1', name: 'Family', inviteCode: '730264', requirePhoto: false, createdBy: 'f2'),
    const Circle(id: 'c2', name: 'Hostel Room 4', inviteCode: '482915', requirePhoto: false, createdBy: me),
  ];
  final members = <String, List<String>>{
    'c1': [me, 'f1', 'f2', 'f3', 'f4'],
    'c2': [me, 'f2', 'f3', 'f4'],
  };
  final streaks = <String, int>{me: 12, 'f1': 41, 'f2': 9, 'f3': 0, 'f4': 3};

  DateTime get _now => DateTime.now().toUtc();

  /// A member's local calendar date (Dubai and Kerala can differ around midnight).
  DateTime _todayOf(String user) => Zones.today(people[user]!.location.timezone);
  DateTime get _today => _todayOf(me);

  String _k(String user, DateTime d, PrayerName p) => '$user|${d.year}-${d.month}-${d.day}|${p.name}';

  List<PrayerWindow> windowsOf(String user, DateTime day) {
    final m = people[user]!;
    return PrayerCalculatorService(method: m.method, madhab: m.madhab, offsets: m.offsets).windowsFor(m.location, day);
  }

  /// Your windows (what `get_my_prayer_windows` returns).
  List<PrayerWindow> windows(DateTime day) => windowsOf(me, day);

  PrayerName? _currentPrayerOf(String user) {
    for (final w in windowsOf(user, _todayOf(user))) {
      if (w.isOpenAt(_now)) return w.prayer;
    }
    return null;
  }

  /// Uses the browser's location and time zone for "you" (works with Chrome
  /// DevTools → Sensors). Falls back to Kozhikode if location isn't shared.
  Future<void> locateMe(PrayerCalculatorService calc) async {
    String? zone;
    try {
      zone = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {}
    try {
      final loc = await calc.currentLocation().timeout(const Duration(seconds: 8));
      setMyPlace('Your location', loc); // method picked automatically from the region
      return;
    } catch (_) {}
    // No location: pick a sample city that matches the browser's time zone.
    final city = demoCities.entries.where((e) => e.value.$1.timezone == zone).firstOrNull?.key ?? 'Kozhikode';
    setMyPlace('$city (sample)', demoCities[city]!.$1);
  }

  /// Demo version of `set_my_location`: moves you and rebuilds your day.
  void setMyPlace(String place, UserLocation loc, {String? method, String? madhab}) {
    final m = myself
      ..place = place
      ..location = loc;
    if (method != null) {
      m.method = method;
    } else if (m.methodAuto) {
      m.method = methodForTimezone(loc.timezone);
    }
    if (madhab != null) m.madhab = madhab;
    _logs.removeWhere((k, _) => k.startsWith('$me|'));
    _seedUser(me);
    _changes.add(null);
  }

  void updateProfile(String name, String? gender, int? birthYear, String? mosque, String language, bool hide) {
    if (gender == 'male' && periods.any((p) => p.isOpen)) throw DemoRuleException('period_open');
    myself
      ..name = name.trim().isEmpty ? myself.name : name.trim()
      ..gender = gender
      ..birthYear = birthYear
      ..mosque = mosque
      ..language = language
      ..hideStatus = hide
      ..onboarded = true;
    _logs.removeWhere((k, _) => k.startsWith('$me|'));
    _seedUser(me);
    _changes.add(null);
  }

  /// The demo keeps your profile and haid/nifas history in this browser, so
  /// setup only shows on the first visit.
  Future<void> saveLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'demo.profile',
        jsonEncode({
          'name': myself.name,
          'gender': myself.gender,
          'birth_year': myself.birthYear,
          'mosque': myself.mosque,
          'language': myself.language,
          'hide': myself.hideStatus,
          'madhab': myself.madhab,
          'periods': [
            for (final p in periods)
              {'kind': p.kind, 'start': p.startedAt.toIso8601String(), 'end': p.endedAt?.toIso8601String()},
          ],
        }),
      );
    } catch (_) {}
  }

  Future<void> restoreLocal() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString('demo.profile');
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      myself
        ..name = j['name'] as String? ?? myself.name
        ..gender = j['gender'] as String?
        ..birthYear = j['birth_year'] as int?
        ..mosque = j['mosque'] as String?
        ..language = j['language'] as String? ?? 'en'
        ..hideStatus = j['hide'] as bool? ?? false
        ..madhab = j['madhab'] as String? ?? myself.madhab
        ..onboarded = true;
      periods
        ..clear()
        ..addAll([
          for (final (i, p) in (j['periods'] as List? ?? const []).indexed)
            ExcusedPeriod(
              id: 'p$i',
              kind: p['kind'] as String,
              startedAt: DateTime.parse(p['start'] as String),
              endedAt: p['end'] == null ? null : DateTime.parse(p['end'] as String),
            ),
        ]);
      _logs.removeWhere((k, _) => k.startsWith('$me|'));
      _seedUser(me);
    } catch (_) {}
  }

  /// Demo versions of `start_excused` / `end_excused`, same rules as the server.
  void startExcused(String kind) {
    if (myself.gender != 'female') throw DemoRuleException('not_applicable');
    if (periods.any((p) => p.isOpen && p.effectiveEnd(myself.madhab).isAfter(_now))) {
      throw DemoRuleException('period_open');
    }
    final last = periods.lastOrNull;
    if (kind == 'haid' &&
        last != null &&
        last.kind == 'haid' &&
        last.effectiveEnd(myself.madhab).isAfter(_now.subtract(const Duration(days: 15)))) {
      throw DemoRuleException('purity_gap');
    }
    periods.add(ExcusedPeriod(id: 'p${periods.length}', kind: kind, startedAt: _now));
    _changes.add(null);
  }

  void endExcused() {
    final i = periods.lastIndexWhere((p) => p.isOpen);
    if (i < 0) throw DemoRuleException('no_open_period');
    final p = periods[i];
    periods[i] = ExcusedPeriod(id: p.id, kind: p.kind, startedAt: p.startedAt, endedAt: _now);
    // Shafi'i: purity in Asr/Isha time makes Dhuhr/Maghrib due as well.
    if (myself.madhab == 'shafi') {
      final ws = windowsOf(me, _today);
      final open = ws.where((w) => w.isOpenAt(_now)).firstOrNull?.prayer;
      final also = open == PrayerName.asr
          ? PrayerName.dhuhr
          : open == PrayerName.isha
          ? PrayerName.maghrib
          : null;
      if (also != null) _logs.remove(_k(me, _today, also));
    }
    _changes.add(null);
  }

  /// Demo version of `set_prayer_settings` (no cooldown in the demo).
  void setSettings({required bool auto, required String method, required String madhab, required List<int> offsets}) {
    myself
      ..methodAuto = auto
      ..method = auto ? methodForTimezone(myself.location.timezone) : method
      ..madhab = madhab
      ..offsets = List.of(offsets);
    _logs.removeWhere((k, _) => k.startsWith('$me|'));
    _seedUser(me);
    _changes.add(null);
  }

  PrayerStatus _statusFor(PrayerLog l) => !l.startedAt!.isBefore(l.windowStart) && l.startedAt!.isBefore(l.windowEnd)
      ? PrayerStatus.onTime
      : PrayerStatus.qada;

  PrayerLog _copy(
    PrayerLog l, {
    PrayerStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? focusVerified,
    int? focusSeconds,
    String? photoPath,
  }) => PrayerLog(
    id: l.id,
    userId: l.userId,
    prayerDate: l.prayerDate,
    prayer: l.prayer,
    status: status ?? l.status,
    windowStart: l.windowStart,
    windowEnd: l.windowEnd,
    startedAt: startedAt ?? l.startedAt,
    completedAt: completedAt ?? l.completedAt,
    focusSeconds: focusSeconds ?? l.focusSeconds,
    focusVerified: focusVerified ?? l.focusVerified,
    photoPath: photoPath ?? l.photoPath,
    photoUploadedAt: photoPath != null ? _now : l.photoUploadedAt,
  );

  void _put(String user, DateTime day, PrayerWindow w, PrayerStatus s, {bool photo = false}) {
    final start = switch (s) {
      PrayerStatus.onTime => w.start.add(const Duration(minutes: 12)),
      PrayerStatus.qada => w.end.add(const Duration(minutes: 30)),
      PrayerStatus.inProgress => _now.subtract(const Duration(minutes: 2)),
      _ => null,
    };
    _logs[_k(user, day, w.prayer)] = PrayerLog(
      id: _k(user, day, w.prayer),
      userId: user,
      prayerDate: day,
      prayer: w.prayer,
      status: s,
      windowStart: w.start,
      windowEnd: w.end,
      startedAt: start,
      completedAt: s.isDone ? start!.add(const Duration(minutes: 6)) : null,
      focusSeconds: s.isDone ? 360 : null,
      focusVerified: s.isDone,
      photoPath: photo && s.isDone ? samplePhoto : null,
    );
  }

  // Pattern of finished prayers today (you start with yours mostly done).
  static const _pattern = <String, List<PrayerStatus>>{
    me: [PrayerStatus.onTime, PrayerStatus.onTime, PrayerStatus.qada, PrayerStatus.onTime, PrayerStatus.onTime],
    'f1': [PrayerStatus.onTime, PrayerStatus.onTime, PrayerStatus.onTime, PrayerStatus.onTime, PrayerStatus.onTime],
    'f2': [PrayerStatus.onTime, PrayerStatus.qada, PrayerStatus.onTime, PrayerStatus.onTime, PrayerStatus.onTime],
    'f3': [PrayerStatus.missed, PrayerStatus.onTime, PrayerStatus.qada, PrayerStatus.missed, PrayerStatus.onTime],
    'f4': [PrayerStatus.onTime, PrayerStatus.onTime, PrayerStatus.onTime, PrayerStatus.qada, PrayerStatus.onTime],
  };

  /// Seeds one member's yesterday and today, using *their* windows and date.
  void _seedUser(String u) {
    final today = _todayOf(u);
    final yesterday = today.subtract(const Duration(days: 1));
    for (final w in windowsOf(u, yesterday)) {
      _put(u, yesterday, w, u == 'f3' && w.prayer == PrayerName.fajr ? PrayerStatus.missed : PrayerStatus.onTime);
    }
    final ws = windowsOf(u, today);
    final lastEnded = ws.lastIndexWhere((x) => x.hasEndedAt(_now));
    for (var i = 0; i < ws.length; i++) {
      final w = ws[i];
      if (_excused(u, w)) {
        if (w.hasEndedAt(_now)) _put(u, today, w, PrayerStatus.excused);
        continue;
      }
      if (w.hasEndedAt(_now)) {
        // Leave your last finished prayer as Missed so "Log Qada" can be tried.
        final s = u == me && i == lastEnded ? PrayerStatus.missed : _pattern[u]![i];
        _put(u, today, w, s, photo: u == 'f1' || u == 'f4');
      } else if (w.isOpenAt(_now)) {
        if (u == 'f1') _put(u, today, w, PrayerStatus.onTime, photo: true);
        if (u == 'f2') _put(u, today, w, PrayerStatus.inProgress);
        // f3, f4 and you: still pending, so you can nudge them / pray now.
      }
    }
  }

  void _seed() {
    for (final u in people.keys) {
      _seedUser(u);
    }
    // Friends encouraging each other.
    for (final l in _logs.values.where((l) => l.prayerDate == _todayOf(l.userId) && l.status.isDone)) {
      final h = l.id.hashCode.abs();
      for (final u in people.keys.where((u) => u != l.userId && u != me)) {
        if ((h + u.hashCode) % 3 == 0) (_reactions[l.id] ??= {})[u] = reactionEmojis[h % reactionEmojis.length];
      }
    }
  }

  // ------------------------------------------------------------------ API used by SupabaseService
  List<PrayerLog> logsFor(String user, DateTime day) =>
      PrayerName.values.map((p) => _logs[_k(user, day, p)]).whereType<PrayerLog>().toList();

  Streak streakOf(String user) => Streak(
    currentDays: streaks[user] ?? 0,
    bestDays: (streaks[user] ?? 0) + 18,
    fajrCurrentDays: 5,
    fajrBestDays: 21,
  );

  PrayerLog startPrayer(PrayerName p, DateTime? qadaDate) {
    final day = qadaDate == null ? _today : DateTime(qadaDate.year, qadaDate.month, qadaDate.day);
    var w = windows(day).firstWhere((x) => x.prayer == p);
    var target = day;
    if (qadaDate == null && !w.isOpenAt(_now)) {
      // Isha after midnight belongs to yesterday.
      final y = _today.subtract(const Duration(days: 1));
      final yw = windows(y).firstWhere((x) => x.prayer == p);
      if (!yw.isOpenAt(_now)) throw DemoRuleException('outside_window');
      w = yw;
      target = y;
    }
    if (qadaDate != null && !w.hasEndedAt(_now)) throw DemoRuleException('window_not_closed');
    if (_excused(me, w)) throw DemoRuleException('excused_no_prayer');
    final existing = _logs[_k(me, target, p)];
    if (existing != null && existing.status.isDone) throw DemoRuleException('already_logged');
    final log = PrayerLog(
      id: _k(me, target, p),
      userId: me,
      prayerDate: target,
      prayer: p,
      status: PrayerStatus.inProgress,
      windowStart: w.start,
      windowEnd: w.end,
      startedAt: _now,
    );
    _logs[log.id] = log;
    _changes.add(null);
    return log;
  }

  PrayerLog completePrayer(String id) {
    final l = _logs[id];
    if (l == null || l.status != PrayerStatus.inProgress) throw DemoRuleException('not_in_progress');
    final secs = _now.difference(l.startedAt!).inSeconds;
    if (secs < focusDuration.inSeconds) {
      throw DemoRuleException('focus_too_short', '${focusDuration.inSeconds - secs} seconds remaining');
    }
    final done = _copy(l, status: _statusFor(l), completedAt: _now, focusVerified: true, focusSeconds: secs);
    _logs[id] = done;
    // Your circle notices and sends some love a few seconds later.
    Timer(const Duration(seconds: 4), () {
      (_reactions[id] ??= {})
        ..['f1'] = '🤲'
        ..['f4'] = '🔥';
      _changes.add(null);
    });
    _changes.add(null);
    return done;
  }

  void cancelPrayer(String id) {
    final l = _logs[id];
    if (l == null || l.status != PrayerStatus.inProgress) return;
    if (l.windowEnd.isAfter(_now)) {
      _logs.remove(id);
    } else {
      _logs[id] = PrayerLog(
        id: l.id,
        userId: l.userId,
        prayerDate: l.prayerDate,
        prayer: l.prayer,
        status: PrayerStatus.missed,
        windowStart: l.windowStart,
        windowEnd: l.windowEnd,
      );
    }
    _changes.add(null);
  }

  PrayerLog attachPhoto(PrayerLog log, Uint8List jpeg) {
    final path = 'demo/${log.id}';
    photos[path] = jpeg;
    final l = _copy(_logs[log.id]!, photoPath: path);
    _logs[log.id] = l;
    _changes.add(null);
    return l;
  }

  Circle createCircle(String name, bool requirePhoto) {
    final c = Circle(
      id: 'c${circles.length + 1}',
      name: name,
      inviteCode: (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString(),
      requirePhoto: requirePhoto,
      createdBy: me,
    );
    circles.add(c);
    members[c.id] = [me];
    return c;
  }

  /// 123456 → "Study Circle", whose owner approves joins (you wait).
  /// 654321 → "Masjid Youth", open circle (you join straight away).
  JoinResult joinCircle(String code) {
    if (code == '123456') {
      if (!myJoinRequests.contains('Study Circle')) myJoinRequests.add('Study Circle');
      return const JoinResult(joined: false, circleName: 'Study Circle');
    }
    if (code != '654321') throw DemoRuleException('invalid_code');
    const c = Circle(
      id: 'c-join',
      name: 'Masjid Youth',
      inviteCode: '654321',
      requirePhoto: false,
      createdBy: 'f3',
      approveJoins: false,
    );
    if (!circles.any((x) => x.id == c.id)) {
      circles.add(c);
      members[c.id] = [me, 'f1', 'f3'];
    }
    return JoinResult(joined: true, circleName: c.name);
  }

  // ------------------------------------------------------------ invite-only access (demo)
  /// In the demo you are the super admin. Two people are waiting for you.
  final accessUsers = <AdminUser>[
    AdminUser(
      id: 'p1',
      name: 'Sameer',
      email: 'sameer@example.com',
      status: AccessStatus.pending,
      isAdmin: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AdminUser(
      id: 'p2',
      name: 'Unknown',
      email: 'someone@example.com',
      status: AccessStatus.pending,
      isAdmin: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    AdminUser(
      id: me,
      name: 'You',
      email: 'you@example.com',
      status: AccessStatus.approved,
      isAdmin: true,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    for (final (id, n) in [('f1', 'Ameen'), ('f2', 'Fathima'), ('f3', 'Rashid'), ('f4', 'Shabna')])
      AdminUser(
        id: id,
        name: n,
        email: '${n.toLowerCase()}@example.com',
        status: AccessStatus.approved,
        isAdmin: false,
        createdAt: DateTime.now().subtract(const Duration(days: 50)),
        invitedWith: 'FAMILY26',
      ),
  ];
  final invites = <InviteCode>[
    InviteCode(
      code: 'FAMILY26',
      maxUses: 10,
      used: 4,
      expiresAt: DateTime.now().add(const Duration(days: 20)),
      note: 'Family group',
    ),
    InviteCode(
      code: 'K7MPQ2RA',
      maxUses: 1,
      used: 1,
      expiresAt: DateTime.now().add(const Duration(days: 3)),
      note: 'Umma',
    ),
  ];
  final joinRequests = <String, List<JoinRequest>>{
    'c2': [JoinRequest(userId: 'p3', name: 'Junaid', requestedAt: DateTime.now().subtract(const Duration(hours: 1)))],
  };
  final myJoinRequests = <String>[];

  void setAccess(String id, AccessStatus st) {
    final u = accessUsers.firstWhere((u) => u.id == id);
    if (u.isAdmin) throw DemoRuleException('cannot_change_admin');
    u.status = st;
    if (st != AccessStatus.approved) {
      for (final m in members.values) {
        m.remove(id);
      }
    }
    _changes.add(null);
  }

  void setAdmin(String id, bool on) {
    if (id == me && !on) throw DemoRuleException('cannot_change_admin');
    final u = accessUsers.firstWhere((u) => u.id == id);
    u.isAdmin = on;
    if (on) u.status = AccessStatus.approved;
  }

  InviteCode createInvite(int maxUses, int days, String? note) {
    const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final r = Random();
    final code = String.fromCharCodes(List.generate(8, (_) => alphabet.codeUnitAt(r.nextInt(alphabet.length))));
    final ic = InviteCode(
      code: code,
      maxUses: maxUses,
      used: 0,
      expiresAt: DateTime.now().add(Duration(days: days)),
      note: (note?.trim().isEmpty ?? true) ? null : note!.trim(),
    );
    invites.insert(0, ic);
    return ic;
  }

  void revokeInvite(String code) {
    final i = invites.indexWhere((c) => c.code == code);
    final c = invites[i];
    invites[i] = InviteCode(
      code: c.code,
      maxUses: c.maxUses,
      used: c.used,
      expiresAt: c.expiresAt,
      note: c.note,
      revokedAt: DateTime.now(),
    );
  }

  /// Only used by the "what a new person sees" preview.
  String redeem(String code) {
    final c = code.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    final i = invites.indexWhere((x) => x.code == c);
    if (i < 0 || invites[i].revokedAt != null) return 'invalid_invite';
    if (!invites[i].expiresAt.isAfter(DateTime.now())) return 'invite_expired';
    if (invites[i].used >= invites[i].maxUses) return 'invite_used_up';
    final x = invites[i];
    invites[i] = InviteCode(code: x.code, maxUses: x.maxUses, used: x.used + 1, expiresAt: x.expiresAt, note: x.note);
    return 'approved';
  }

  void answerJoin(String circleId, String userId, bool accept) {
    final list = joinRequests[circleId] ?? [];
    final r = list.firstWhere((r) => r.userId == userId, orElse: () => throw DemoRuleException('no_request'));
    list.remove(r);
    if (accept) {
      people.putIfAbsent(userId, () => DemoMember(r.name, 'Malappuram', demoCities['Kozhikode']!.$1));
      streaks.putIfAbsent(userId, () => 0);
      _seedUser(userId);
      members[circleId]!.add(userId);
    }
    _changes.add(null);
  }

  void removeMember(String circleId, String userId) {
    final c = circles.firstWhere((c) => c.id == circleId);
    if (c.createdBy != me) throw DemoRuleException('not_owner');
    if (userId == me) throw DemoRuleException('use_leave');
    members[circleId]!.remove(userId);
    _changes.add(null);
  }

  void setApproveJoins(String circleId, bool on) {
    final i = circles.indexWhere((c) => c.id == circleId);
    final c = circles[i];
    if (c.createdBy != me) throw DemoRuleException('not_owner');
    circles[i] = Circle(
      id: c.id,
      name: c.name,
      inviteCode: c.inviteCode,
      requirePhoto: c.requirePhoto,
      createdBy: c.createdBy,
      approveJoins: on,
    );
  }

  void leaveCircle(String id) {
    circles.removeWhere((c) => c.id == id);
    members.remove(id);
  }

  Circle updateCircle(String id, {String? name, bool? requirePhoto, bool regenerateCode = false}) {
    final i = circles.indexWhere((c) => c.id == id);
    final c = circles[i];
    final n = Circle(
      id: c.id,
      name: name ?? c.name,
      inviteCode: regenerateCode ? (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString() : c.inviteCode,
      requirePhoto: requirePhoto ?? c.requirePhoto,
      createdBy: c.createdBy,
      approveJoins: c.approveJoins,
    );
    circles[i] = n;
    return n;
  }

  List<MatrixRow> matrix(String circleId) {
    final rows = <MatrixRow>[];
    for (final u in members[circleId] ?? const <String>[]) {
      final m = people[u]!;
      final day = _todayOf(u);
      final row = MatrixRow(
        userId: u,
        displayName: m.name,
        streakDays: streaks[u] ?? 0,
        timezone: m.location.timezone,
        place: m.place,
      );
      for (final w in windowsOf(u, day)) {
        final l = _logs[_k(u, day, w.prayer)];
        final exc = (l?.status == PrayerStatus.excused) || (l == null && !w.start.isAfter(_now) && _excused(u, w));
        if (u != me && (m.hideStatus || exc)) {
          // The circle never learns why: a period looks the same as a privacy choice.
          row.cells[w.prayer] = MatrixCell(
            prayer: w.prayer,
            status: PrayerStatus.private,
            focusVerified: false,
            windowStart: w.start,
            windowEnd: w.end,
            canNudge: false,
            alreadyNudged: false,
          );
          continue;
        }
        final status = exc
            ? PrayerStatus.excused
            : l?.status ??
                  (w.isOpenAt(_now)
                      ? PrayerStatus.pending
                      : w.hasEndedAt(_now)
                      ? PrayerStatus.missed
                      : PrayerStatus.upcoming);
        final nudgeKey = '$u|${w.prayer.name}';
        // The real server only allows nudges in the last 20 minutes of a
        // window; the demo relaxes that so the button can be tried any time.
        row.cells[w.prayer] = MatrixCell(
          prayer: w.prayer,
          status: status,
          focusVerified: l?.focusVerified ?? false,
          photoPath: l?.photoPath,
          windowStart: w.start,
          windowEnd: w.end,
          canNudge: u != me && l == null && w.isOpenAt(_now) && !_nudged.contains(nudgeKey),
          alreadyNudged: _nudged.contains(nudgeKey),
          logId: l?.id,
          reactionCount: l == null ? 0 : (_reactions[l.id]?.length ?? 0),
          myReaction: l == null ? null : _reactions[l.id]?[me],
        );
      }
      rows.add(row);
    }
    return rows;
  }

  int circleFajrStreak(String circleId) => circleId == 'c1' ? 11 : 4;

  // ------------------------------------------------------------------ gamification
  /// Sample history for the 35-day heatmap: a believable pattern that gets
  /// better over time (older days are synthetic, recent ones are real logs).
  int _xpOn(String user, DateTime day) {
    final logs = logsFor(user, day);
    final xp = logs.fold<int>(0, (s, l) => s + xpForLog(l));
    final perfect = logs.where((l) => l.status == PrayerStatus.onTime).length == 5;
    return xp + (perfect ? perfectDayBonus : 0);
  }

  DayHistory _historyDay(DateTime d, int i) {
    final logs = logsFor(me, d);
    if (logs.isNotEmpty) {
      int c(PrayerStatus s) => logs.where((l) => l.status == s).length;
      return DayHistory(
        date: d,
        onTime: c(PrayerStatus.onTime),
        qada: c(PrayerStatus.qada),
        missed: c(PrayerStatus.missed),
      );
    }
    final onTime = i < 22 ? 5 : (i * 7 % 3 == 0 ? 3 : 4 + (i % 2));
    final qada = (5 - onTime).clamp(0, 5) ~/ 2;
    return DayHistory(date: d, onTime: onTime.clamp(0, 5), qada: qada, missed: 5 - onTime.clamp(0, 5) - qada);
  }

  Progress progress() {
    final history = [for (var i = 34; i >= 0; i--) _historyDay(_today.subtract(Duration(days: i)), i)];
    // Synthetic past XP + real XP from today/yesterday's logs.
    final past = history
        .take(33)
        .fold<int>(0, (s, h) => s + h.onTime * 13 + h.qada * 4 + (h.onTime == 5 ? perfectDayBonus : 0));
    final xp = past + _xpOn(me, _today) + _xpOn(me, _today.subtract(const Duration(days: 1)));
    final weekStart = _today.subtract(Duration(days: _today.weekday - 1));
    final weekXp = history
        .where((h) => !h.date.isBefore(weekStart))
        .fold<int>(0, (s, h) => s + h.onTime * 13 + h.qada * 4 + (h.onTime == 5 ? perfectDayBonus : 0));
    return Progress(
      xp: xp,
      level: levelForXp(xp),
      weekXp: weekXp,
      streak: streakOf(me),
      badges: const {'streak_3', 'streak_7', 'fajr_7', 'circle_fajr_7'},
      history: history,
      perPrayer: const {
        PrayerName.fajr: 83,
        PrayerName.dhuhr: 93,
        PrayerName.asr: 87,
        PrayerName.maghrib: 97,
        PrayerName.isha: 90,
      },
    );
  }

  List<LeaderboardEntry> leaderboard(String circleId) {
    final base = {me: 0, 'f1': 310, 'f2': 205, 'f3': 96, 'f4': 240};
    final entries = [
      for (final u in members[circleId] ?? const <String>[])
        LeaderboardEntry(
          userId: u,
          displayName: names[u]!,
          weekXp: u == me ? progress().weekXp : base[u] ?? 50,
          level: u == me ? progress().level : 3 + (base[u] ?? 0) ~/ 100,
          streakDays: streaks[u] ?? 0,
        ),
    ]..sort((a, b) => b.weekXp.compareTo(a.weekXp));
    return entries;
  }

  CircleQuest quest(String circleId) {
    final n = members[circleId]?.length ?? 1;
    final goal = (n * 35 * 0.8).ceil();
    final today = _logs.values
        .where((l) => l.prayerDate == _todayOf(l.userId) && l.status == PrayerStatus.onTime)
        .length;
    final weekStart = _today.subtract(Duration(days: _today.weekday - 1));
    return CircleQuest(
      title: 'Circle Quest: 80% on time this week',
      goal: goal,
      progress: (goal * 0.55).round() + today,
      endsAt: weekStart.add(const Duration(days: 7)),
    );
  }

  void react(String logId, String emoji) {
    final l = _logs[logId];
    if (l == null) throw DemoRuleException('not_found');
    if (l.userId == me) throw DemoRuleException('cannot_react_self');
    if (!l.status.isDone) throw DemoRuleException('not_completed');
    (_reactions[logId] ??= {})[me] = emoji;
    _changes.add(null);
  }

  void nudge(String receiver, PrayerName p) {
    final key = '$receiver|${p.name}';
    if (!_nudged.add(key)) throw DemoRuleException('already_nudged');
    _changes.add(null);
  }
}

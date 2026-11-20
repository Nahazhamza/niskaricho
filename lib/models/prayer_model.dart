import '../l10n/tr.dart';

// Prayer domain models. Mirrors the enums and tables in supabase/schema.sql.

/// The five daily prayers. `.name` matches the Postgres enum `prayer_name`.
enum PrayerName {
  fajr('Fajr', 'സുബ്ഹ്', 'ഫജ്ർ', 'الفجر'),
  dhuhr('Dhuhr', 'ളുഹർ', 'ളുഹർ', 'الظهر'),
  asr('Asr', 'അസർ', 'അസർ', 'العصر'),
  maghrib('Maghrib', 'മഗ്‌രിബ്', 'മഗ്‌രിബ്', 'المغرب'),
  isha('Isha', 'ഇശാ', 'ഇശാ', 'العشاء');

  const PrayerName(this.english, this.malayalam, this.malayalamAlt, this.arabic);

  final String arabic;

  /// The name in the app's language.
  String get label => switch (L10n.lang.value) {
    AppLang.en => english,
    AppLang.ml => malayalam,
    AppLang.ar => arabic,
  };

  final String english;

  /// Name as commonly said in Kerala (Fajr is usually called "Subh").
  final String malayalam;
  final String malayalamAlt;

  static PrayerName fromDb(String v) => PrayerName.values.byName(v);
}

/// Postgres enum `prayer_status`, plus two UI-only states computed by
/// `get_circle_matrix` (pending = window open, upcoming = not started).
enum PrayerStatus {
  onTime('on_time', '🟢', 'On-Time'),
  qada('qada', '🟡', 'Qada'),
  missed('missed', '🔴', 'Missed'),
  inProgress('in_progress', '🤲', 'Praying'),
  pending('pending', '⏳', 'Pending'),
  upcoming('upcoming', '·', 'Upcoming'),

  /// Not owed (haid / nifas): no qada, never breaks a streak. Only you see this.
  excused('excused', '🤍', 'Excused'),

  /// What the circle sees for an excused prayer or a member who hides their
  /// status. It never says why.
  private('private', '🤍', 'Not shared');

  const PrayerStatus(this.db, this.emoji, this._label);
  final String db;
  final String emoji;
  final String _label;

  /// In the app's language.
  String get label => tr(_label);

  static PrayerStatus fromDb(String? v) =>
      PrayerStatus.values.firstWhere((s) => s.db == v, orElse: () => PrayerStatus.upcoming);

  bool get isDone => this == onTime || this == qada;
}

/// A server-authoritative prayer window (from `get_my_prayer_windows`).
class PrayerWindow {
  const PrayerWindow({required this.prayer, required this.start, required this.end});

  final PrayerName prayer;
  final DateTime start; // UTC
  final DateTime end; // UTC

  bool isOpenAt(DateTime t) => !t.isBefore(start) && t.isBefore(end);
  bool hasEndedAt(DateTime t) => !t.isBefore(end);
  Duration remainingAt(DateTime t) => end.difference(t);

  factory PrayerWindow.fromJson(Map<String, dynamic> j) => PrayerWindow(
    prayer: PrayerName.fromDb(j['prayer'] as String),
    start: DateTime.parse(j['window_start'] as String).toUtc(),
    end: DateTime.parse(j['window_end'] as String).toUtc(),
  );
}

/// Row of `prayer_logs`. Clients can only read these; every write is an RPC.
class PrayerLog {
  const PrayerLog({
    required this.id,
    required this.userId,
    required this.prayerDate,
    required this.prayer,
    required this.status,
    required this.windowStart,
    required this.windowEnd,
    this.startedAt,
    this.completedAt,
    this.focusSeconds,
    this.focusVerified = false,
    this.photoPath,
    this.photoUploadedAt,
  });

  final String id;
  final String userId;
  final DateTime prayerDate;
  final PrayerName prayer;
  final PrayerStatus status;
  final DateTime windowStart;
  final DateTime windowEnd;
  final DateTime? startedAt; // SERVER clock
  final DateTime? completedAt; // SERVER clock
  final int? focusSeconds;
  final bool focusVerified;
  final String? photoPath;
  final DateTime? photoUploadedAt;

  bool get hasPhoto => photoPath != null;

  static DateTime? _ts(dynamic v) => v == null ? null : DateTime.parse(v as String).toUtc();

  factory PrayerLog.fromJson(Map<String, dynamic> j) => PrayerLog(
    id: j['id'] as String,
    userId: j['user_id'] as String,
    prayerDate: DateTime.parse(j['prayer_date'] as String),
    prayer: PrayerName.fromDb(j['prayer'] as String),
    status: PrayerStatus.fromDb(j['status'] as String),
    windowStart: _ts(j['window_start'])!,
    windowEnd: _ts(j['window_end'])!,
    startedAt: _ts(j['started_at']),
    completedAt: _ts(j['completed_at']),
    focusSeconds: j['focus_seconds'] as int?,
    focusVerified: (j['focus_verified'] as bool?) ?? false,
    photoPath: j['photo_path'] as String?,
    photoUploadedAt: _ts(j['photo_uploaded_at']),
  );
}

/// Streak row (`streaks` table).
class Streak {
  const Streak({this.currentDays = 0, this.bestDays = 0, this.fajrCurrentDays = 0, this.fajrBestDays = 0});

  final int currentDays;
  final int bestDays;
  final int fajrCurrentDays;
  final int fajrBestDays;

  factory Streak.fromJson(Map<String, dynamic> j) => Streak(
    currentDays: j['current_days'] as int? ?? 0,
    bestDays: j['best_days'] as int? ?? 0,
    fajrCurrentDays: j['fajr_current_days'] as int? ?? 0,
    fajrBestDays: j['fajr_best_days'] as int? ?? 0,
  );
}

/// Human-friendly errors for the exceptions raised by the SQL functions.
String describeServerError(String code) => switch (code) {
  'outside_window' => tr('This prayer is not in its time window right now.'),
  'window_not_closed' => tr('The window is still open — use Pray Now instead of Qada.'),
  'invalid_qada_date' => tr('Qada can only be logged for the last 7 days.'),
  'already_logged' => tr('Already logged. Alhamdulillah!'),
  'focus_too_short' => tr('Please complete at least 5 minutes of focus.'),
  'session_expired' => tr('Session was left open too long. Please start again.'),
  'location_cooldown' => tr('Location can only change once every 6 hours.'),
  'session_open' => tr('Finish your current prayer first.'),
  'invalid_code' => tr('That invite code does not exist.'),
  'too_many_attempts' => tr('Too many wrong codes. Try again in an hour.'),
  'already_nudged' => tr('You already nudged them for this prayer.'),
  'too_early_to_nudge' => tr('Nudges unlock in the last 20 minutes of the window.'),
  'already_praying_or_prayed' => tr('They have already started or finished this prayer.'),
  'photo_out_of_time' => tr('Photo must be taken right after the prayer.'),
  'cannot_react_self' => 'You can\'t react to your own prayer.',
  'not_completed' => tr('You can react once they have prayed.'),
  'location_required' => tr('Set your location first so prayer times can be calculated.'),
  'excused_no_prayer' => tr('You are excused from this prayer (haid/nifas). No qada is needed.'),
  'not_applicable' => tr('This option is for women only. Set your gender in Profile.'),
  'period_open' => tr('A period is already marked. End it first.'),
  'purity_gap' => tr(
    'Less than 15 days since your last period ended. This counts as istihada, so salah is still due: make wudu for each prayer.',
  ),
  'no_open_period' => tr('There is no period marked right now.'),
  'not_available' => 'This person can\'t be nudged right now.',
  'settings_cooldown' => tr('Prayer time settings can change once every 6 hours.'),
  'invalid_offsets' => tr('Offsets must be between -10 and +10 minutes.'),
  'not_approved' => tr('Your account is waiting for the admin to approve it.'),
  'access_denied' => tr('Access for this account is closed.'),
  'not_admin' => tr('Only the admin can do this.'),
  'cannot_change_admin' => tr('Admin accounts cannot be changed here.'),
  'invalid_invite' => tr('That invite code is not valid.'),
  'invite_expired' => tr('That invite code has expired. Ask for a new one.'),
  'invite_used_up' => tr('That invite code has already been used.'),
  'not_owner' => tr('Only the circle owner can do this.'),
  'no_request' => tr('This request was already answered.'),
  'use_leave' => tr('To remove yourself, use Leave circle.'),
  'cannot_remove_owner' => tr('The owner cannot be removed.'),
  _ => tr('Something went wrong ({code}).', {'code': code}),
};

/// A private haid / nifas period (`excused_periods`). Only the owner can read it.
class ExcusedPeriod {
  const ExcusedPeriod({required this.id, required this.kind, required this.startedAt, this.endedAt});
  final String id;
  final String kind; // 'haid' | 'nifas'
  final DateTime startedAt; // UTC
  final DateTime? endedAt; // UTC, null while ongoing

  /// Haid counts at most 15 days (Hanafi 10), nifas 60 (Hanafi 40); past that,
  /// bleeding is istihada and salah is due.
  static Duration maxFor(String kind, String madhab) => switch ((kind, madhab)) {
    ('haid', 'hanafi') => const Duration(days: 10),
    ('haid', _) => const Duration(days: 15),
    ('nifas', 'hanafi') => const Duration(days: 40),
    _ => const Duration(days: 60),
  };

  DateTime effectiveEnd(String madhab) {
    final cap = startedAt.add(maxFor(kind, madhab));
    final e = endedAt;
    return e == null || e.isAfter(cap) ? cap : e;
  }

  bool get isOpen => endedAt == null;

  /// Same rule as the server's `_excused_kind`: excused if bleeding began
  /// within 5 minutes of the prayer's start and lasted to within 1 minute of
  /// its end (otherwise the prayer is owed).
  bool covers(PrayerWindow w, String madhab, DateTime now) {
    final end = w.end.isAfter(now) ? now.add(const Duration(minutes: 1)) : w.end;
    return !startedAt.isAfter(w.start.add(const Duration(minutes: 5))) &&
        !effectiveEnd(madhab).isBefore(end.subtract(const Duration(minutes: 1)));
  }

  factory ExcusedPeriod.fromJson(Map<String, dynamic> j) => ExcusedPeriod(
    id: j['id'] as String,
    kind: j['kind'] as String,
    startedAt: DateTime.parse(j['started_at'] as String).toUtc(),
    endedAt: j['ended_at'] == null ? null : DateTime.parse(j['ended_at'] as String).toUtc(),
  );
}

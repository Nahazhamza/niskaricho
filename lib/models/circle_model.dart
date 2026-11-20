import 'prayer_model.dart';

/// A prayer circle (`circles` table).
class Circle {
  const Circle({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.requirePhoto,
    required this.createdBy,
    this.approveJoins = true,
  });

  final String id;
  final String name;
  final String inviteCode; // 6 digits
  final bool requirePhoto; // BeReal-style proof mode
  final String createdBy;

  /// The owner approves each new member (default on, invite-only phase).
  final bool approveJoins;

  factory Circle.fromJson(Map<String, dynamic> j) => Circle(
    id: j['id'] as String,
    name: j['name'] as String,
    inviteCode: (j['invite_code'] as String).trim(),
    requirePhoto: j['require_photo'] as bool? ?? false,
    createdBy: j['created_by'] as String,
    approveJoins: j['approve_joins'] as bool? ?? true,
  );
}

/// One cell of the live squad matrix (a member × a prayer), from
/// the `get_circle_matrix` RPC. Every status here is computed by the server.
class MatrixCell {
  const MatrixCell({
    required this.prayer,
    required this.status,
    required this.focusVerified,
    required this.windowStart,
    required this.windowEnd,
    required this.canNudge,
    required this.alreadyNudged,
    this.photoPath,
    this.logId,
    this.reactionCount = 0,
    this.myReaction,
  });

  final PrayerName prayer;
  final PrayerStatus status;
  final bool focusVerified;
  final String? photoPath;
  final DateTime windowStart;
  final DateTime windowEnd;
  final bool canNudge;
  final bool alreadyNudged;
  final String? logId;
  final int reactionCount;
  final String? myReaction;

  bool get hasPhoto => photoPath != null;
}

/// One member row of the matrix.
class MatrixRow {
  MatrixRow({
    required this.userId,
    required this.displayName,
    required this.streakDays,
    this.avatarUrl,
    this.timezone,
    this.place,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int streakDays;

  /// The member's own IANA time zone (from their profile). Their windows and
  /// times are shown in this zone, not the viewer's.
  final String? timezone;

  /// A city label (demo only; real profiles never expose location to peers).
  final String? place;
  final Map<PrayerName, MatrixCell> cells = {};

  int get onTimeCount => cells.values.where((c) => c.status == PrayerStatus.onTime).length;

  /// Groups the flat RPC result into one row per member.
  static List<MatrixRow> fromRpc(List<dynamic> rows) {
    final byUser = <String, MatrixRow>{};
    for (final raw in rows) {
      final j = raw as Map<String, dynamic>;
      final row = byUser.putIfAbsent(
        j['user_id'] as String,
        () => MatrixRow(
          userId: j['user_id'] as String,
          displayName: j['display_name'] as String,
          avatarUrl: j['avatar_url'] as String?,
          streakDays: j['streak_days'] as int? ?? 0,
          timezone: j['member_timezone'] as String?,
        ),
      );
      final prayer = PrayerName.fromDb(j['prayer'] as String);
      row.cells[prayer] = MatrixCell(
        prayer: prayer,
        status: PrayerStatus.fromDb(j['display_status'] as String),
        focusVerified: j['focus_verified'] as bool? ?? false,
        photoPath: j['photo_path'] as String?,
        windowStart: DateTime.parse(j['window_start'] as String).toUtc(),
        windowEnd: DateTime.parse(j['window_end'] as String).toUtc(),
        canNudge: j['can_nudge'] as bool? ?? false,
        alreadyNudged: j['already_nudged'] as bool? ?? false,
        logId: j['log_id'] as String?,
        reactionCount: j['reaction_count'] as int? ?? 0,
        myReaction: j['my_reaction'] as String?,
      );
    }
    return byUser.values.toList();
  }
}

/// Circle-wide completion for today: on-time cells / (members × 5).
double circleCompletion(List<MatrixRow> rows) {
  if (rows.isEmpty) return 0;
  final done = rows.fold<int>(0, (s, r) => s + r.onTimeCount);
  return done / (rows.length * PrayerName.values.length);
}

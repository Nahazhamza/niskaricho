/// Invite-only access (early phase): accounts, invite codes and circle join
/// requests. All rules are enforced by the server (schema.sql section 17).
library;

/// pending → waiting for an admin; approved → can use the app;
/// rejected / removed → blocked.
enum AccessStatus {
  pending,
  approved,
  rejected,
  removed;

  static AccessStatus parse(String? v) => AccessStatus.values.asNameMap()[v] ?? AccessStatus.approved;
}

class AdminUser {
  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.isAdmin,
    required this.createdAt,
    this.invitedWith,
  });

  final String id;
  final String name;
  final String email;
  AccessStatus status;
  bool isAdmin;
  final DateTime createdAt;
  final String? invitedWith;

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
    id: j['id'] as String,
    name: j['display_name'] as String? ?? '',
    email: j['email'] as String? ?? '',
    status: AccessStatus.parse(j['access_status'] as String?),
    isAdmin: j['is_admin'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
    invitedWith: j['invited_with'] as String?,
  );
}

class InviteCode {
  InviteCode({
    required this.code,
    required this.maxUses,
    required this.used,
    required this.expiresAt,
    this.revokedAt,
    this.note,
  });

  final String code; // 8 characters, no look-alike letters
  final int maxUses;
  final int used;
  final DateTime expiresAt;
  final DateTime? revokedAt;
  final String? note;

  bool usable(DateTime now) => revokedAt == null && expiresAt.isAfter(now) && used < maxUses;

  factory InviteCode.fromJson(Map<String, dynamic> j) => InviteCode(
    code: j['code'] as String,
    maxUses: (j['max_uses'] as num).toInt(),
    used: (j['used'] as num).toInt(),
    expiresAt: DateTime.parse(j['expires_at'] as String),
    revokedAt: j['revoked_at'] == null ? null : DateTime.parse(j['revoked_at'] as String),
    note: j['note'] as String?,
  );
}

class JoinRequest {
  const JoinRequest({required this.userId, required this.name, required this.requestedAt});
  final String userId;
  final String name;
  final DateTime requestedAt;

  factory JoinRequest.fromJson(Map<String, dynamic> j) => JoinRequest(
    userId: j['user_id'] as String,
    name: j['display_name'] as String? ?? '',
    requestedAt: DateTime.parse(j['requested_at'] as String),
  );
}

/// Result of entering a circle code: joined straight away, or waiting for the owner.
class JoinResult {
  const JoinResult({required this.joined, required this.circleName});
  final bool joined;
  final String circleName;
}

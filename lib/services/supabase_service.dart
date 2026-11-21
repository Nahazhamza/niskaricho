import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show ImageProvider, MemoryImage, AssetImage, NetworkImage, ValueNotifier;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/tr.dart';
import '../models/access_model.dart';
import '../models/circle_model.dart';
import '../models/prayer_model.dart';
import '../models/progress_model.dart';
import 'demo_backend.dart';
import 'prayer_calculator_service.dart';
import 'zones.dart';

/// Thrown when an RPC raises one of the schema's named exceptions
/// (e.g. `focus_too_short`). [code] is that name; [hint] is extra detail.
class ServerRuleException implements Exception {
  ServerRuleException(this.code, [this.hint]);
  final String code;
  final String? hint;
  String get message => describeServerError(code);
  @override
  String toString() => 'ServerRuleException($code${hint == null ? '' : ': $hint'})';
}

/// Cancels a realtime subscription.
typedef Unsubscribe = Future<void> Function();

/// Thin, typed wrapper around Supabase.
///
/// Anti-cheat note: this class never sends a timestamp or a status to the
/// server. It only says *what* the user wants to do ("start Asr", "complete
/// log X"); the database decides *when* it happened and *whether* it counts.
///
/// In demo mode ([kDemoMode]) every call is answered by [DemoBackend], an
/// in-memory copy of the same rules with sample data, so the app runs in a
/// browser without a Supabase project.
class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  final bool isDemo = kDemoMode;
  late final DemoBackend demo = DemoBackend();

  SupabaseClient get _db => Supabase.instance.client;
  String? get userId => isDemo ? DemoBackend.me : _db.auth.currentUser?.id;

  /// Device clock minus server clock. Subtract it to get "server now".
  /// A user who sets their phone clock forward gains nothing: the UI follows
  /// server time and the server checks everything again anyway.
  Duration clockSkew = Duration.zero;
  DateTime get serverNow => DateTime.now().toUtc().subtract(clockSkew);

  /// Your profile's time zone and method (set at start-up). Your own times
  /// are shown in this zone and "today" is your local date there, so a
  /// phone whose zone is wrong still shows the right prayer day.
  String? myTimezone;
  String myMethod = 'karachi';
  String myMadhab = 'shafi';
  bool myMethodAuto = true;

  /// Bumped when your place or prayer settings change; the shell rebuilds tabs.
  final settingsChanged = ValueNotifier<int>(0);
  List<int> myOffsets = const [0, 0, 0, 0, 0];
  UserLocation? myLocation;

  // Profile (set up on first open, editable in Journey → Profile).
  String myName = '';
  String? myGender; // 'male' | 'female'
  int? myBirthYear;
  String? myMosque;
  String myLanguage = 'ml';
  bool myHideStatus = false;
  bool onboarded = true;

  /// Invite-only phase: pending accounts wait for an admin (or an invite code).
  AccessStatus access = AccessStatus.approved;
  bool isAdmin = false;

  /// Your private haid / nifas history, newest first.
  List<ExcusedPeriod> myPeriods = const [];
  ExcusedPeriod? get openPeriod {
    final p = myPeriods.where((p) => p.isOpen).firstOrNull;
    if (p == null) return null;
    // Past the maximum it is istihada: no longer excused.
    return p.effectiveEnd(myMadhab).isAfter(serverNow) ? p : null;
  }

  bool isExcused(PrayerWindow w) => myPeriods.any((p) => p.covers(w, myMadhab, serverNow));

  /// Copies a profile row (from get_my_profile / demo) into the fields above.
  void applyProfile(Map<String, dynamic> p) {
    if (p['latitude'] != null) {
      myLocation = UserLocation(
        latitude: (p['latitude'] as num).toDouble(),
        longitude: (p['longitude'] as num).toDouble(),
        timezone: p['timezone'] as String,
      );
    }
    myTimezone = p['timezone'] as String? ?? myTimezone;
    myMethod = p['calc_method'] as String? ?? myMethod;
    myMadhab = p['asr_madhab'] as String? ?? myMadhab;
    myMethodAuto = p['method_auto'] as bool? ?? myMethodAuto;
    myName = p['display_name'] as String? ?? myName;
    myGender = p['gender'] as String?;
    myBirthYear = (p['birth_year'] as num?)?.toInt();
    myMosque = p['home_mosque'] as String?;
    myLanguage = p['language'] as String? ?? myLanguage;
    myHideStatus = p['hide_status'] as bool? ?? myHideStatus;
    onboarded = p['onboarded'] as bool? ?? onboarded;
    access = AccessStatus.parse(p['access_status'] as String?);
    isAdmin = p['is_admin'] as bool? ?? false;
    final o = p['minute_offsets'];
    if (o is List && o.length == 5) myOffsets = [for (final x in o) (x as num).toInt()];
  }

  /// A calculator with your current settings (for previews and notifications).
  PrayerCalculatorService myCalculator({String? method, String? madhab, List<int>? offsets}) =>
      PrayerCalculatorService(method: method ?? myMethod, madhab: madhab ?? myMadhab, offsets: offsets ?? myOffsets);
  DateTime toMyZone(DateTime instant) => Zones.wall(instant, myTimezone);
  String get myPlaceLabel =>
      isDemo ? tr(demo.myself.place) : (myTimezone ?? tr('Your location')).split('/').last.replaceAll('_', ' ');
  DateTime get myToday => Zones.today(myTimezone, serverNow);

  /// Minimum focus time (the server enforces 5 min; the demo uses 20 s).
  Duration get minFocus => isDemo ? DemoBackend.focusDuration : const Duration(minutes: 5);

  // ---------------------------------------------------------------- auth
  /// Sign in or sign up. A new account with a valid invite code is approved at once (see handle_new_user).
  Future<void> sendEmailOtp(String email, {String? inviteCode}) => _db.auth.signInWithOtp(
    email: email,
    shouldCreateUser: true,
    data: (inviteCode?.isNotEmpty ?? false) ? {'invite_code': inviteCode} : null,
  );

  /// 1-click Google OAuth sign-in.
  Future<void> signInWithGoogle({String? inviteCode}) async {
    if (isDemo) return;
    await _db.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.niskaricho://login-callback/',
      queryParams: (inviteCode?.isNotEmpty ?? false) ? {'invite_code': inviteCode!} : null,
    );
  }

  Future<void> verifyEmailOtp(String email, String code) =>
      _db.auth.verifyOTP(email: email, token: code, type: OtpType.email);

  Future<void> signOut() => _db.auth.signOut();

  /// Deletes your account and all your data on the server (store requirement).
  Future<void> deleteMyAccount() async {
    if (isDemo) return;
    await _rpc('delete_my_account');
    await _db.auth.signOut();
  }

  // ---------------------------------------------------------------- helpers
  Future<T> _rpc<T>(String fn, [Map<String, dynamic>? params]) async {
    try {
      return await _db.rpc(fn, params: params) as T;
    } on PostgrestException catch (e) {
      throw ServerRuleException(e.message, e.hint);
    }
  }

  /// Runs a demo call, converting its rule errors into [ServerRuleException].
  Future<T> _demo<T>(T Function() f) async {
    await Future<void>.delayed(const Duration(milliseconds: 150)); // feel like a network call
    try {
      return f();
    } on DemoRuleException catch (e) {
      throw ServerRuleException(e.code, e.hint);
    }
  }

  // ---------------------------------------------------------------- profile
  Future<Map<String, dynamic>> myProfile() async {
    if (isDemo) {
      final m = demo.myself;
      return {
        'id': DemoBackend.me,
        'display_name': m.name,
        'latitude': m.location.latitude,
        'longitude': m.location.longitude,
        'timezone': m.location.timezone,
        'calc_method': m.method,
        'asr_madhab': m.madhab,
        'method_auto': m.methodAuto,
        'minute_offsets': m.offsets,
        'place': m.place,
        'gender': m.gender,
        'birth_year': m.birthYear,
        'home_mosque': m.mosque,
        'language': m.language,
        'hide_status': m.hideStatus,
        'onboarded': m.onboarded,
        'access_status': 'approved',
        'is_admin': true,
      };
    }
    return _rpc<Map<String, dynamic>>('get_my_profile');
  }

  Future<void> updateDisplayName(String name) async {
    if (isDemo) return;
    await _db.from('profiles').update({'display_name': name}).eq('id', userId!);
  }

  Future<void> setMyLocation(UserLocation loc, {String? method, String? madhab, String? place}) async {
    if (isDemo) {
      demo.setMyPlace(place ?? demo.myself.place, loc, method: method, madhab: madhab);
      applyProfile(await myProfile());
      return;
    }
    await _rpc('set_my_location', {
      'p_lat': loc.latitude,
      'p_lng': loc.longitude,
      'p_timezone': loc.timezone,
      'p_method': method,
      'p_madhab': madhab,
    });
  }

  /// Saves the profile (name, gender, birth year, mosque, language, privacy).
  Future<void> updateProfile({
    required String name,
    String? gender,
    int? birthYear,
    String? mosque,
    required String language,
    required bool hideStatus,
  }) async {
    if (isDemo) {
      await _demo(() => demo.updateProfile(name, gender, birthYear, mosque, language, hideStatus));
      await demo.saveLocal();
    } else {
      await _rpc('update_my_profile', {
        'p_display_name': name,
        'p_gender': gender,
        'p_birth_year': birthYear,
        'p_home_mosque': mosque,
        'p_language': language,
        'p_hide_status': hideStatus,
      });
    }
    applyProfile(await myProfile());
    settingsChanged.value++;
  }

  Future<void> loadMyPeriods() async {
    if (isDemo) {
      myPeriods = List.of(demo.periods.reversed);
      return;
    }
    final rows = await _db.from('excused_periods').select().order('started_at', ascending: false).limit(24);
    myPeriods = [for (final r in rows) ExcusedPeriod.fromJson(r)];
  }

  /// Marks the start of haid or nifas (women only; limits checked on the server).
  Future<void> startExcused(String kind) async {
    if (isDemo) {
      await _demo(() => demo.startExcused(kind));
      await demo.saveLocal();
    } else {
      await _rpc('start_excused', {'p_kind': kind});
    }
    await loadMyPeriods();
    settingsChanged.value++;
  }

  Future<void> endExcused() async {
    if (isDemo) {
      await _demo(demo.endExcused);
      await demo.saveLocal();
    } else {
      await _rpc('end_excused');
    }
    await loadMyPeriods();
    settingsChanged.value++;
  }

  /// Method, Asr madhab and mosque offsets (rate-limited on the server).
  Future<void> savePrayerSettings({
    required bool auto,
    required String method,
    required String madhab,
    required List<int> offsets,
  }) async {
    if (isDemo) {
      await _demo(() => demo.setSettings(auto: auto, method: method, madhab: madhab, offsets: offsets));
    } else {
      await _rpc('set_prayer_settings', {
        'p_method_auto': auto,
        'p_method': method,
        'p_madhab': madhab,
        'p_offsets': offsets,
      });
    }
    applyProfile(await myProfile());
  }

  /// Server-authoritative windows for a local date (null = today).
  /// Also re-measures the clock skew from the server's own `now()`.
  Future<List<PrayerWindow>> fetchMyWindows([DateTime? localDate]) async {
    if (isDemo) return _demo(() => demo.windows(localDate ?? myToday));
    final requestedAt = DateTime.now().toUtc();
    final rows = await _rpc<List<dynamic>>('get_my_prayer_windows', {
      'p_date': localDate == null ? null : _date(localDate),
    });
    if (rows.isNotEmpty) {
      final server = DateTime.parse((rows.first as Map)['server_now'] as String).toUtc();
      final rtt = DateTime.now().toUtc().difference(requestedAt);
      clockSkew = requestedAt.add(rtt ~/ 2).difference(server);
    }
    return rows.map((r) => PrayerWindow.fromJson(r as Map<String, dynamic>)).toList();
  }

  // ---------------------------------------------------------------- prayer logs
  Future<List<PrayerLog>> myLogsFor(DateTime localDate) async {
    if (isDemo) {
      return _demo(() => demo.logsFor(DemoBackend.me, DateTime(localDate.year, localDate.month, localDate.day)));
    }
    final rows = await _db.from('prayer_logs').select().eq('user_id', userId!).eq('prayer_date', _date(localDate));
    return rows.map(PrayerLog.fromJson).toList();
  }

  /// "Pray Now" (live window only) or Qada for a past [qadaDate].
  Future<PrayerLog> startPrayer(PrayerName p, {DateTime? qadaDate}) async {
    if (isDemo) return _demo(() => demo.startPrayer(p, qadaDate));
    final row = await _rpc<Map<String, dynamic>>('start_prayer', {
      'p_prayer': p.name,
      'p_prayer_date': qadaDate == null ? null : _date(qadaDate),
    });
    return PrayerLog.fromJson(row);
  }

  Future<PrayerLog> completePrayer(String logId) async {
    if (isDemo) return _demo(() => demo.completePrayer(logId));
    return PrayerLog.fromJson(await _rpc<Map<String, dynamic>>('complete_prayer', {'p_log_id': logId}));
  }

  Future<void> cancelPrayer(String logId) async {
    if (isDemo) return _demo(() => demo.cancelPrayer(logId));
    await _rpc('cancel_prayer', {'p_log_id': logId});
  }

  Future<Streak> myStreak() async {
    if (isDemo) return _demo(() => demo.streakOf(DemoBackend.me));
    final row = await _db.from('streaks').select().eq('user_id', userId!).maybeSingle();
    return row == null ? const Streak() : Streak.fromJson(row);
  }

  // ---------------------------------------------------------------- photo proof
  /// Uploads a JPEG to `prayer-proofs/<uid>/...` (insert-only bucket), then asks
  /// the server to attach it. The server accepts it only if the storage
  /// object was created between session start and completion + 10 min.
  Future<PrayerLog> uploadPhotoProof(PrayerLog log, Uint8List jpeg) async {
    if (isDemo) return _demo(() => demo.attachPhoto(log, jpeg));
    final path = '$userId/${_date(log.prayerDate)}_${log.prayer.name}_${DateTime.now().microsecondsSinceEpoch}.jpg';
    await _db.storage
        .from('prayer-proofs')
        .uploadBinary(path, jpeg, fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false));
    final row = await _rpc<Map<String, dynamic>>('attach_photo_proof', {'p_log_id': log.id, 'p_path': path});
    return PrayerLog.fromJson(row);
  }

  /// An image for a stored proof (signed URL; demo uses memory / a sample).
  Future<ImageProvider> photoImage(String path) async {
    if (isDemo) {
      final bytes = demo.photos[path];
      return bytes != null ? MemoryImage(bytes) : const AssetImage('assets/demo/sample_proof.jpg');
    }
    return NetworkImage(await _db.storage.from('prayer-proofs').createSignedUrl(path, 3600));
  }

  // ---------------------------------------------------------------- circles
  Future<List<Circle>> myCircles() async {
    if (isDemo) return _demo(() => List.of(demo.circles));
    final rows = await _db
        .from('circles')
        .select('*, circle_members!inner(user_id)')
        .eq('circle_members.user_id', userId!)
        .order('created_at');
    return rows.map(Circle.fromJson).toList();
  }

  Future<Circle> createCircle(String name, {bool requirePhoto = false}) async {
    if (isDemo) return _demo(() => demo.createCircle(name, requirePhoto));
    return Circle.fromJson(
      await _rpc<Map<String, dynamic>>('create_circle', {'p_name': name, 'p_require_photo': requirePhoto}),
    );
  }

  /// Joins straight away, or (if the owner approves joins) sends a request.
  Future<JoinResult> joinCircle(String code) async {
    if (isDemo) return _demo(() => demo.joinCircle(code));
    final r = await _rpc<Map<String, dynamic>>('join_circle', {'p_code': code});
    final status = r['status'] as String;
    if (status == 'invalid_code') throw ServerRuleException('invalid_code');
    return JoinResult(joined: status == 'joined', circleName: (r['circle'] as Map)['name'] as String);
  }

  /// Names of circles you asked to join that are still waiting for the owner.
  Future<List<String>> myJoinRequests() async {
    if (isDemo) return List.of(demo.myJoinRequests);
    final rows = await _rpc<List<dynamic>>('my_join_requests');
    return [for (final r in rows) (r as Map)['name'] as String];
  }

  Future<List<JoinRequest>> joinRequests(String circleId) async {
    if (isDemo) return List.of(demo.joinRequests[circleId] ?? const <JoinRequest>[]);
    final rows = await _rpc<List<dynamic>>('get_circle_join_requests', {'p_circle': circleId});
    return [for (final r in rows) JoinRequest.fromJson(r as Map<String, dynamic>)];
  }

  Future<void> answerJoinRequest(String circleId, String userId, bool accept) async {
    if (isDemo) return _demo(() => demo.answerJoin(circleId, userId, accept));
    await _rpc('answer_join_request', {'p_circle': circleId, 'p_user': userId, 'p_accept': accept});
  }

  Future<void> removeMember(String circleId, String userId) async {
    if (isDemo) return _demo(() => demo.removeMember(circleId, userId));
    await _rpc('remove_circle_member', {'p_circle': circleId, 'p_user': userId});
  }

  Future<void> setApproveJoins(String circleId, bool on) async {
    if (isDemo) return _demo(() => demo.setApproveJoins(circleId, on));
    await _rpc('set_circle_approve_joins', {'p_circle': circleId, 'p_on': on});
  }

  // ---------------------------------------------------------------- invite-only access
  /// Returns 'approved' or why the code did not work.
  Future<String> redeemInvite(String code) async {
    if (isDemo) return _demo(() => demo.redeem(code));
    final r = await _rpc<String>('redeem_invite', {'p_code': code});
    if (r == 'approved') applyProfile(await myProfile());
    return r;
  }

  Future<List<AdminUser>> adminUsers() async {
    if (isDemo) {
      return _demo(
        () => [
          for (final u in demo.accessUsers)
            u.id == DemoBackend.me
                ? AdminUser(
                    id: u.id,
                    name: demo.myself.name,
                    email: u.email,
                    status: u.status,
                    isAdmin: true,
                    createdAt: u.createdAt,
                  )
                : u,
        ],
      );
    }
    final rows = await _rpc<List<dynamic>>('admin_list_users');
    return [for (final r in rows) AdminUser.fromJson(r as Map<String, dynamic>)];
  }

  Future<void> adminSetAccess(String userId, AccessStatus status) async {
    if (isDemo) return _demo(() => demo.setAccess(userId, status));
    await _rpc('admin_set_access', {'p_user': userId, 'p_status': status.name});
  }

  Future<void> adminSetAdmin(String userId, bool on) async {
    if (isDemo) return _demo(() => demo.setAdmin(userId, on));
    await _rpc('admin_set_admin', {'p_user': userId, 'p_admin': on});
  }

  Future<List<InviteCode>> adminInvites() async {
    if (isDemo) return _demo(() => List.of(demo.invites));
    final rows = await _rpc<List<dynamic>>('admin_list_invites');
    return [for (final r in rows) InviteCode.fromJson(r as Map<String, dynamic>)];
  }

  Future<InviteCode> adminCreateInvite({required int maxUses, required int days, String? note}) async {
    if (isDemo) return _demo(() => demo.createInvite(maxUses, days, note));
    return InviteCode.fromJson(
      await _rpc<Map<String, dynamic>>('admin_create_invite', {
        'p_max_uses': maxUses,
        'p_valid_days': days,
        'p_note': note,
      }),
    );
  }

  Future<void> adminRevokeInvite(String code) async {
    if (isDemo) return _demo(() => demo.revokeInvite(code));
    await _rpc('admin_revoke_invite', {'p_code': code});
  }

  Future<void> leaveCircle(String circleId) async {
    if (isDemo) return _demo(() => demo.leaveCircle(circleId));
    await _rpc('leave_circle', {'p_circle': circleId});
  }

  Future<Circle> updateCircle(String circleId, {String? name, bool? requirePhoto, bool regenerateCode = false}) async {
    if (isDemo) {
      return _demo(
        () => demo.updateCircle(circleId, name: name, requirePhoto: requirePhoto, regenerateCode: regenerateCode),
      );
    }
    return Circle.fromJson(
      await _rpc<Map<String, dynamic>>('update_circle', {
        'p_circle': circleId,
        'p_name': name,
        'p_require_photo': requirePhoto,
        'p_regenerate_code': regenerateCode,
      }),
    );
  }

  Future<bool> anyCircleRequiresPhoto() async => (await myCircles()).any((c) => c.requirePhoto);

  // ---------------------------------------------------------------- matrix + nudges
  Future<List<MatrixRow>> circleMatrix(String circleId) async {
    if (isDemo) return _demo(() => demo.matrix(circleId));
    return MatrixRow.fromRpc(await _rpc<List<dynamic>>('get_circle_matrix', {'p_circle': circleId}));
  }

  /// Consecutive days on which every member prayed Fajr on time.
  Future<int> circleFajrStreak(String circleId) async {
    if (isDemo) return _demo(() => demo.circleFajrStreak(circleId));
    final row = await _db.from('circle_streaks').select('full_fajr_current').eq('circle_id', circleId).maybeSingle();
    return row?['full_fajr_current'] as int? ?? 0;
  }

  // ---------------------------------------------------------------- gamification
  Future<Progress> myProgress() async {
    if (isDemo) return _demo(demo.progress);
    return Progress.fromJson(await _rpc<Map<String, dynamic>>('get_my_progress'));
  }

  Future<List<LeaderboardEntry>> leaderboard(String circleId) async {
    if (isDemo) return _demo(() => demo.leaderboard(circleId));
    final rows = await _rpc<List<dynamic>>('get_circle_leaderboard', {'p_circle': circleId});
    return [for (final r in rows) LeaderboardEntry.fromJson(r as Map<String, dynamic>)];
  }

  Future<CircleQuest> circleQuest(String circleId) async {
    if (isDemo) return _demo(() => demo.quest(circleId));
    return CircleQuest.fromJson(await _rpc<Map<String, dynamic>>('get_circle_quest', {'p_circle': circleId}));
  }

  /// Encourage a friend's completed prayer with one of [reactionEmojis].
  Future<void> react(String logId, String emoji) async {
    if (isDemo) return _demo(() => demo.react(logId, emoji));
    await _rpc('react_to_log', {'p_log_id': logId, 'p_emoji': emoji});
  }

  Future<void> sendNudge(String circleId, String receiverId, PrayerName p) async {
    if (isDemo) return _demo(() => demo.nudge(receiverId, p));
    await _rpc('send_nudge', {'p_circle': circleId, 'p_receiver': receiverId, 'p_prayer': p.name});
  }

  /// Realtime: fires whenever any visible prayer log changes (RLS limits this
  /// to the user's circle peers), or membership changes. Debounced.
  Unsubscribe watchCircle(String circleId, void Function() onChange) {
    Timer? debounce;
    void ping() {
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 400), onChange);
    }

    if (isDemo) {
      final sub = demo.changes.listen((_) => ping());
      return sub.cancel;
    }
    final ch = _db
        .channel('circle:$circleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'prayer_logs',
          callback: (_) => ping(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'circle_members',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'circle_id', value: circleId),
          callback: (_) => ping(),
        )
        .subscribe();
    return () => _db.removeChannel(ch);
  }

  /// Realtime: nudges addressed to me.
  Unsubscribe watchMyNudges(void Function(PrayerName prayer, String senderId) onNudge) {
    if (isDemo) return () async {};
    final ch = _db
        .channel('nudges:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'nudges',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'receiver_id', value: userId!),
          callback: (payload) => onNudge(
            PrayerName.fromDb(payload.newRecord['prayer'] as String),
            payload.newRecord['sender_id'] as String,
          ),
        )
        .subscribe();
    return () => _db.removeChannel(ch);
  }

  Future<String> displayNameOf(String uid) async {
    if (isDemo) return demo.names[uid] ?? 'A friend';
    final row = await _db.from('profiles').select('display_name').eq('id', uid).maybeSingle();
    return row?['display_name'] as String? ?? 'A friend';
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/copy.dart';
import '../l10n/tr.dart';
import '../models/prayer_model.dart';

/// Local notifications: exact Adhan alerts, 20-minute expiry warnings and
/// in-app nudges (delivered over Supabase Realtime).
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static AndroidNotificationDetails get _adhanChannel => AndroidNotificationDetails(
    'adhan',
    tr('Adhan times'),
    channelDescription: tr('When each prayer time starts'),
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.reminder,
  );
  static AndroidNotificationDetails get _warningChannel => AndroidNotificationDetails(
    'expiry',
    tr('Time ending'),
    channelDescription: tr('20 minutes before a prayer time ends'),
    importance: Importance.max,
    priority: Priority.max,
    category: AndroidNotificationCategory.reminder,
  );
  static AndroidNotificationDetails get _nudgeChannel => AndroidNotificationDetails(
    'nudge',
    tr('Reminders from your circle'),
    channelDescription: tr('When someone in your circle reminds you to pray'),
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.social,
  );
  static const _darwin = DarwinNotificationDetails(presentSound: true, presentBanner: true);

  Future<void> init(String timezone) async {
    if (kIsWeb) return; // scheduled local notifications are not supported on web
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(timezone));
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    _ready = true;
  }

  // IDs: day offset (0/1) * 100 + prayer index * 10 + kind (0 adhan, 1 warning)
  int _id(int dayOffset, PrayerName p, int kind) => dayOffset * 100 + p.index * 10 + kind;

  /// Re-schedules Adhan + expiry warnings for today and tomorrow.
  /// Call on app start, after location changes, and after each check-in.
  Future<void> scheduleDays(List<List<PrayerWindow>> days, {Set<PrayerName> alreadyPrayedToday = const {}}) async {
    if (!_ready) return;
    await _plugin.cancelAllPendingNotifications();
    final now = DateTime.now().toUtc();
    for (var d = 0; d < days.length; d++) {
      for (final w in days[d]) {
        if (w.start.isAfter(now)) {
          final m = AppCopy.adhan(w.prayer);
          await _schedule(_id(d, w.prayer, 0), w.start, m.title, m.body, _adhanChannel);
        }
        final warnAt = w.end.subtract(const Duration(minutes: 20));
        final prayed = d == 0 && alreadyPrayedToday.contains(w.prayer);
        if (!prayed && warnAt.isAfter(now)) {
          final m = AppCopy.expiryWarning(w.prayer);
          await _schedule(_id(d, w.prayer, 1), warnAt, m.title, m.body, _warningChannel);
        }
      }
    }
  }

  /// Drop the "20 minutes left" warning once a prayer is logged.
  Future<void> cancelWarning(PrayerName p) async {
    if (_ready) await _plugin.cancel(id: _id(0, p, 1));
  }

  Future<void> _schedule(int id, DateTime atUtc, String title, String body, AndroidNotificationDetails ch) =>
      _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(atUtc, tz.local),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: ch, iOS: _darwin),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

  /// Shown immediately when a friend's nudge arrives over Realtime.
  Future<void> showNudge(PrayerName p, String fromName) async {
    if (!_ready) return;
    final m = AppCopy.nudge(p, fromName);
    return _plugin.show(
      id: 900 + p.index,
      title: m.title,
      body: m.body,
      notificationDetails: NotificationDetails(android: _nudgeChannel, iOS: _darwin),
    );
  }
}

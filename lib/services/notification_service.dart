import 'dart:async';

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
  final List<Timer> _webTimers = [];
  bool _ready = false;
  bool get isReady => _ready;

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
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(timezone));
    } catch (_) {}

    if (_ready) return;

    if (kIsWeb) {
      await _plugin.initialize(
        settings: const InitializationSettings(),
      );
      _ready = true;
      return;
    }

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

  /// Requests permission from the user explicitly (e.g. from settings button).
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      final webImpl = _plugin.resolvePlatformSpecificImplementation<WebFlutterLocalNotificationsPlugin>();
      final granted = await webImpl?.requestNotificationsPermission();
      return granted ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final aGranted = await android?.requestNotificationsPermission() ?? true;
    await android?.requestExactAlarmsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final iGranted = await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? true;
    return aGranted && iGranted;
  }

  // IDs: day offset (0/1) * 100 + prayer index * 10 + kind (0 adhan, 1 warning)
  int _id(int dayOffset, PrayerName p, int kind) => dayOffset * 100 + p.index * 10 + kind;

  /// Re-schedules Adhan + expiry warnings for today and tomorrow.
  /// Call on app start, after location changes, and after each check-in.
  Future<void> scheduleDays(List<List<PrayerWindow>> days, {Set<PrayerName> alreadyPrayedToday = const {}}) async {
    if (!_ready) return;

    if (kIsWeb) {
      for (final t in _webTimers) {
        t.cancel();
      }
      _webTimers.clear();

      final now = DateTime.now().toUtc();
      for (var d = 0; d < days.length; d++) {
        for (final w in days[d]) {
          if (w.start.isAfter(now)) {
            final diff = w.start.difference(now);
            final m = AppCopy.adhan(w.prayer);
            _webTimers.add(Timer(diff, () {
              _showImmediate(_id(d, w.prayer, 0), m.title, m.body, _adhanChannel);
            }));
          }
          final warnAt = w.end.subtract(const Duration(minutes: 20));
          final prayed = d == 0 && alreadyPrayedToday.contains(w.prayer);
          if (!prayed && warnAt.isAfter(now)) {
            final diff = warnAt.difference(now);
            final m = AppCopy.expiryWarning(w.prayer);
            _webTimers.add(Timer(diff, () {
              _showImmediate(_id(d, w.prayer, 1), m.title, m.body, _warningChannel);
            }));
          }
        }
      }
      return;
    }

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

  Future<void> _schedule(int id, DateTime atUtc, String title, String body, AndroidNotificationDetails ch) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(atUtc, tz.local),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: ch, iOS: _darwin),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id: id,
          scheduledDate: tz.TZDateTime.from(atUtc, tz.local),
          title: title,
          body: body,
          notificationDetails: NotificationDetails(android: ch, iOS: _darwin),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {}
    }
  }

  Future<void> _showImmediate(int id, String title, String body, AndroidNotificationDetails ch) async {
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: ch, iOS: _darwin),
      );
    } catch (_) {}
  }

  /// Send an immediate test notification to confirm prayer alerts work.
  Future<void> testNotification() async {
    if (!_ready) await init('UTC');
    final m = AppCopy.adhan(PrayerName.fajr);
    await _showImmediate(
      999,
      tr('Test Prayer Alert: {title}', {'title': m.title}),
      tr('Notifications are active! You will be reminded at every prayer window.'),
      _adhanChannel,
    );
  }

  /// Shown immediately when a friend's nudge arrives over Realtime.
  Future<void> showNudge(PrayerName p, String fromName) async {
    if (!_ready) return;
    final m = AppCopy.nudge(p, fromName);
    return _showImmediate(
      900 + p.index,
      m.title,
      m.body,
      _nudgeChannel,
    );
  }
}

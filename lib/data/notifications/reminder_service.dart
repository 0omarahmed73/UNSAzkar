import 'package:azkar_new_app/data/prayer/prayer_service.dart';
import 'package:flutter/foundation.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Daily morning/evening adhkar reminders via local notifications.
///
/// Best-effort delivery: uses inexact scheduling (no exact-alarm permission),
/// so the OS may shift times; reminders are lost on reboot (no boot
/// receiver in P0) and under aggressive battery savers. The UI states this.
///
/// Holds a process-wide [current] instance created in `main()`; null when
/// the plugin is unavailable (tests, unsupported platforms) — the Settings
/// screen disables reminder controls in that case instead of faking them.
class ReminderService {
  ReminderService._(this._plugin);

  static ReminderService? current;

  final FlutterLocalNotificationsPlugin _plugin;

  static const int _morningId = 100;
  static const int _eveningId = 101;
  // v2: Android never raises an existing channel's importance, so the old
  // 'adhkar_daily' (default importance) stays silent/collapsed on many phones.
  static const String _channelId = 'adhkar_daily_v2';
  static const String _channelName = 'تذكير الأذكار';
  static const String _channelDesc = 'تذكير يومي بأذكار الصباح والمساء';
  static const String _prayerChannelId = 'prayer_times';
  static const String _prayerChannelName = 'مواقيت الصلاة';
  static const String _prayerChannelDesc = 'تذكير بمواعيد الصلوات';

  /// Initializes timezones + plugin. Throws on unsupported platforms;
  /// callers must catch and leave [current] null.
  static Future<ReminderService> create() async {
    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    const prayerChannel = AndroidNotificationChannel(
      _prayerChannelId,
      _prayerChannelName,
      description: _prayerChannelDesc,
      importance: Importance.high,
    );
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(channel);
    await android?.createNotificationChannel(prayerChannel);
    return ReminderService._(plugin);
  }

  /// Requests notification permission. Returns true when notifications can
  /// be shown. Never throws.
  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidOk = await android?.requestNotificationsPermission();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iosOk = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return (androidOk ?? true) && (iosOk ?? true);
    } catch (_) {
      return false;
    }
  }

  /// True when the OS currently allows this app to post notifications.
  /// Returns null when status can't be determined on this platform.
  Future<bool?> notificationsEnabled() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidEnabled = await android?.areNotificationsEnabled();
      if (androidEnabled != null) return androidEnabled;
      // iOS/macOS plugin has no direct query in this package surface.
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Cancels only the adhkar ids, then schedules the enabled daily
  /// reminders from [settings]. Malformed times are skipped, never crash.
  /// Prayer notifications use their own id range and are never touched here.
  Future<void> syncFromSettings(SettingsStore settings) async {
    await cancelIds([_morningId, _eveningId]);
    if (!settings.remindersEnabled) return;
    final morning = parseTime(settings.reminderMorning);
    final evening = parseTime(settings.reminderEvening);
    if (morning != null) {
      await _scheduleDaily(
        id: _morningId,
        hour: morning.$1,
        minute: morning.$2,
        title: 'أذكار الصباح',
        body: 'ابدأ يومك بقراءة أذكار الصباح',
      );
    }
    if (evening != null) {
      await _scheduleDaily(
        id: _eveningId,
        hour: evening.$1,
        minute: evening.$2,
        title: 'أذكار المساء',
        body: 'ابدأ ليلتك بقراءة أذكار المساء',
      );
    }
  }

  Future<void> cancelIds(List<int> ids) async {
    for (final id in ids) {
      try {
        await _plugin.cancel(id);
      } catch (_) {}
    }
  }

  /// Recomputes today's prayer notifications from [settings] and replaces
  /// them. No location or calculation failure → cancelled, never fabricated.
  Future<void> syncPrayerFromSettings(SettingsStore settings) async {
    await cancelIds([
      for (var i = 0; i < PrayerKind.values.length; i++) 200 + i,
      for (var i = 0; i < PrayerKind.values.length; i++) 300 + i,
    ]);
    final lat = settings.prayerLat;
    final lng = settings.prayerLng;
    if (lat == null || lng == null) return;
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    late DailyPrayers today;
    late DailyPrayers tomorrow;
    try {
      today = PrayerService.calculate(
        lat: lat,
        lng: lng,
        date: day,
        method: settings.method,
        madhab: settings.madhab,
      );
      tomorrow = PrayerService.calculate(
        lat: lat,
        lng: lng,
        date: day.add(const Duration(days: 1)),
        method: settings.method,
        madhab: settings.madhab,
      );
    } catch (_) {
      return;
    }
    await syncPrayerReminders(PrayerService.prayerJobs(
      today: today,
      tomorrow: tomorrow,
      now: now,
      enabled: settings.prayerReminders,
    ));
  }

  /// Pending scheduled notifications for diagnostics UI. Never throws;
  /// returns an empty list when the plugin is unavailable.
  Future<List<Map<String, dynamic>>> pendingNotificationRequests() async {
    try {
      final list = await _plugin.pendingNotificationRequests();
      return [
        for (final n in list) {'id': n.id, 'title': n.title, 'body': n.body}
      ];
    } catch (_) {
      return [];
    }
  }

  /// Schedules a one-shot test notification after [delay] (default 60s)
  /// so users can verify delivery. Returns the fire time, or null when
  /// scheduling failed.
  Future<DateTime?> scheduleTestNotification(
      [Duration delay = const Duration(seconds: 60)]) async {
    try {
      final at = tz.TZDateTime.now(tz.local).add(delay);
      await _plugin.zonedSchedule(
        999,
        'تذكير تجريبي',
        'إذا رأيت هذا الإشعار فالتنبيهات تعمل على جهازك.',
        at,
        const NotificationDetails(
          android: AndroidNotificationDetails(
              _prayerChannelId, _prayerChannelName,
              channelDescription: _prayerChannelDesc),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return at;
    } catch (_) {
      return null;
    }
  }

  Future<void> syncPrayerReminders(List<PrayerNotificationJob> jobs) async {
    await cancelIds([
      for (var i = 0; i < PrayerKind.values.length; i++) 200 + i,
      for (var i = 0; i < PrayerKind.values.length; i++) 300 + i,
    ]);
    for (final job in jobs) {
      try {
        await _plugin.zonedSchedule(
          job.id,
          job.title,
          job.body,
          tz.TZDateTime.from(job.at, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
                _prayerChannelId, _prayerChannelName,
                channelDescription: _prayerChannelDesc),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('Prayer reminder schedule failed (id ${job.id}): $e');
      }
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var at =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (at.isBefore(now)) at = at.add(const Duration(days: 1));
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        at,
        const NotificationDetails(
          android: AndroidNotificationDetails(_channelId, _channelName,
              channelDescription: _channelDesc),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e, st) {
      debugPrint('Reminder schedule failed (id $id): $e\n$st');
    }
  }

  /// Parses `HH:MM` (24h). Null for null/malformed input.
  static (int, int)? parseTime(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return (h, m);
  }
}

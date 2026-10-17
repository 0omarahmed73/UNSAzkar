import 'package:azkar_new_app/data/notifications/reminder_service.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'test_helpers.dart';

/// Records raw channel traffic of the REAL Android plugin implementation.
/// This exercises production code paths (plugin → platform impl → channel
/// encoding), not a hand-written fake.
class _ChannelRecorder {
  final calls = <({String method, Map<String, dynamic> args})>[];

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('dexterous.com/flutter/local_notifications'),
            (call) async {
      final args = call.arguments is Map
          ? Map<String, dynamic>.from(call.arguments as Map)
          : <String, dynamic>{};
      calls.add((method: call.method, args: args));
      if (call.method == 'pendingNotificationRequests') {
        return <Map<String, Object?>>[];
      }
      if (call.method == 'initialize' ||
          call.method == 'requestNotificationsPermission') {
        return true;
      }
      return null;
    });
  }
}

void main() {
  late _ChannelRecorder rec;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await mockPathProvider();
    tz.initializeTimeZones();
  });

  setUp(() {
    // Real Android implementation + recorded channel traffic.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    rec = _ChannelRecorder()..install();
    ReminderService.current = null;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });
  });

  Future<void> makeService() async {
    ReminderService.current = await ReminderService.create();
  }

  test('zoned schedules land in the future, never the past', () async {
    await makeService();
    final box = GetStorage('notifFuture');
    await box.erase();
    final settings = SettingsStore(box);
    await settings.load();
    await settings.setReminderMorning('00:00');
    await settings.setReminderEvening('23:59');
    await settings.setRemindersEnabled(true);
    await ReminderService.current!.syncFromSettings(settings);

    final zoned = rec.calls.where((c) => c.method == 'zonedSchedule').toList();
    expect(zoned, isNotEmpty);
    final now = DateTime.now().subtract(const Duration(seconds: 5));
    for (final c in zoned) {
      expect(c.args['id'], isNotNull);
      final scheduled = DateTime.parse(c.args['scheduledDateTime'] as String);
      expect(scheduled.isAfter(now), isTrue,
          reason: 'scheduled time must be in the future');
    }
  });

  test('pendingNotificationRequests is exposed for diagnostics', () async {
    await makeService();
    final pending =
        await ReminderService.current!.pendingNotificationRequests();
    expect(pending, isEmpty);
  });

  test('disabling reminders cancels the adhkar ids, nothing else', () async {
    await makeService();
    final box = GetStorage('notifCancel');
    await box.erase();
    final settings = SettingsStore(box);
    await settings.load();
    await settings.setReminderMorning('07:00');
    await settings.setRemindersEnabled(true);
    await ReminderService.current!.syncFromSettings(settings);
    rec.calls.clear();

    await settings.setRemindersEnabled(false);
    await ReminderService.current!.syncFromSettings(settings);

    final cancelled = rec.calls
        .where((c) => c.method == 'cancel')
        .map((c) => c.args['id'] as int)
        .toSet();
    expect(cancelled, containsAll([100, 101]));
    expect(cancelled.any((id) => id >= 200 && id < 400), isFalse);
    expect(rec.calls.any((c) => c.method == 'zonedSchedule'), isFalse);
  });

  test('scheduleTestNotification returns a future timestamp', () async {
    await makeService();
    final at = await ReminderService.current!
        .scheduleTestNotification(const Duration(seconds: 60));
    expect(at, isNotNull);
    expect(at!.isAfter(DateTime.now()), isTrue);
    final zoned = rec.calls.where((c) => c.method == 'zonedSchedule').toList();
    expect(zoned.length, 1);
    expect(zoned.first.args['id'], 999);
  });
}

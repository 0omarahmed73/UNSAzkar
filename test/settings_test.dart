import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/notifications/reminder_service.dart';
import 'package:azkar_new_app/data/prayer/prayer_service.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/design/app_theme.dart';
import 'package:azkar_new_app/pages/SettingsPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

class _FakeReminderService implements ReminderService {
  _FakeReminderService(this._result);

  final DateTime? _result;
  Duration? lastDelay;
  bool? enabled = true;

  @override
  Future<void> cancelIds(List<int> ids) async {}

  @override
  Future<List<Map<String, dynamic>>> pendingNotificationRequests() async => [];

  @override
  Future<bool?> notificationsEnabled() async => enabled;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<DateTime?> scheduleTestNotification(
      [Duration delay = const Duration(seconds: 60)]) async {
    lastDelay = delay;
    return _result;
  }

  @override
  Future<void> syncFromSettings(SettingsStore settings) async {}

  @override
  Future<void> syncPrayerFromSettings(SettingsStore settings) async {}

  @override
  Future<void> syncPrayerReminders(List<PrayerNotificationJob> jobs) async {}
}

void main() {
  // Fixture I/O in real async (see home_test.dart): never inside bodies.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await mockPathProvider();
  });

  setUp(() async {
    await GetStorage.init();
    Get.reset();
    ReminderService.current = null;
    final box = GetStorage();
    await box.erase();
    Get.put(SettingsStore(box)..load());
    Get.put(Controller());
  });
  test('reminder time parsing accepts HH:MM, rejects garbage', () {
    expect(ReminderService.parseTime('07:00'), (7, 0));
    expect(ReminderService.parseTime('19:30'), (19, 30));
    expect(ReminderService.parseTime(null), isNull);
    expect(ReminderService.parseTime(''), isNull);
    expect(ReminderService.parseTime('7am'), isNull);
    expect(ReminderService.parseTime('24:00'), isNull);
    expect(ReminderService.parseTime('12:60'), isNull);
  });

  test('reminder preferences persist and clear', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await mockPathProvider();
    await GetStorage.init('settingsTest');
    final box = GetStorage('settingsTest');
    await box.erase();
    final s = SettingsStore(box);
    await s.load();
    expect(s.remindersEnabled, isFalse);
    expect(s.reminderMorning, isNull);

    await s.setRemindersEnabled(true);
    await s.setReminderMorning('07:00');
    await s.setReminderEvening('19:00');

    final s2 = SettingsStore(box);
    await s2.load();
    expect(s2.remindersEnabled, isTrue);
    expect(s2.reminderMorning, '07:00');
    expect(s2.reminderEvening, '19:00');

    await s2.setReminderMorning(null);
    final s3 = SettingsStore(box);
    await s3.load();
    expect(s3.reminderMorning, isNull);
  });

  testWidgets(
      'settings renders all sections; reminders gated off without plugin',
      (t) async {
    ReminderService.current = null;

    await t.pumpWidget(
        MaterialApp(theme: buildLightTheme(), home: const SettingsPage()));
    await t.pumpAndSettle();

    expect(find.text('المظهر'), findsOneWidget);
    expect(find.text('الاسم'), findsOneWidget);
    expect(find.text('القراءة'), findsOneWidget);
    await dragIntoView(t, find.text('إرسال إشعار تجريبي'));
    expect(find.text('مواقيت الصلاة'), findsWidgets);
    expect(find.text('إعدادات المواقيت والتنبيهات'), findsOneWidget);
    await dragIntoView(t, find.text('البيانات'));
    expect(find.text('البيانات'), findsOneWidget);
    await dragIntoView(t, find.text('عن المحتوى'));
    expect(find.text('عن المحتوى'), findsOneWidget);
    expect(find.text('التنبيهات غير متاحة على هذا الجهاز.'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('test-notification button explains unavailability without plugin',
      (t) async {
    ReminderService.current = null;

    await t.pumpWidget(
        MaterialApp(theme: buildLightTheme(), home: const SettingsPage()));
    await t.pumpAndSettle();
    final tile = find.widgetWithText(ListTile, 'إرسال إشعار تجريبي');
    await dragIntoView(t, tile);
    final onTap = t.widget<ListTile>(tile).onTap;
    expect(onTap, isNotNull);
    onTap!.call();
    await t.pumpAndSettle();

    expect(find.textContaining('غير متاحة'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('test-notification button schedules when service exists',
      (t) async {
    final fake =
        _FakeReminderService(DateTime.now().add(const Duration(seconds: 60)));
    ReminderService.current = fake;

    await t.pumpWidget(
        MaterialApp(theme: buildLightTheme(), home: const SettingsPage()));
    await t.pumpAndSettle();
    final tile = find.widgetWithText(ListTile, 'إرسال إشعار تجريبي');
    await dragIntoView(t, tile);
    final onTap = t.widget<ListTile>(tile).onTap;
    expect(onTap, isNotNull);
    onTap!.call();
    await t.pumpAndSettle();

    expect(fake.lastDelay, const Duration(seconds: 60));
    expect(find.text('تمت جدولة تنبيه تجريبي بعد دقيقة.'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('test-notification button shows failure when scheduling fails',
      (t) async {
    final fake = _FakeReminderService(null);
    ReminderService.current = fake;

    await t.pumpWidget(
        MaterialApp(theme: buildLightTheme(), home: const SettingsPage()));
    await t.pumpAndSettle();
    final tile = find.widgetWithText(ListTile, 'إرسال إشعار تجريبي');
    await dragIntoView(t, tile);
    final onTap = t.widget<ListTile>(tile).onTap;
    expect(onTap, isNotNull);
    onTap!.call();
    await t.pumpAndSettle();

    expect(fake.lastDelay, const Duration(seconds: 60));
    expect(find.textContaining('تعذر إرسال التنبيه التجريبي'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}

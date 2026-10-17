import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/prayer/prayer_service.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/data/repositories/azkar_repository.dart';
import 'package:azkar_new_app/design/app_theme.dart';
import 'package:azkar_new_app/pages/PrayerTimesPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await mockPathProvider();
  });

  setUp(() async {
    await GetStorage.init();
    Get.reset();
    final box = GetStorage();
    await box.erase();
    Get.put(AzkarRepository());
    Get.put(SettingsStore(box)..load());
    Get.put(ProgressStore(box)..load());
    Get.put(Controller());
  });

  Widget frame(Widget child) => MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: child),
      );

  testWidgets('shows all six times and the next prayer when located',
      (t) async {
    final settings = Get.find<SettingsStore>();
    await settings.setPrayerLocation(30.0444, 31.2357, 'القاهرة، مصر');

    await t.pumpWidget(frame(const PrayerTimesPage()));
    await t.pumpAndSettle();

    expect(find.text('القاهرة، مصر'), findsWidgets);
    expect(find.textContaining('الصلاة القادمة'), findsOneWidget);
    for (final label in [
      'الفجر',
      'الشروق',
      'الظهر',
      'العصر',
      'المغرب',
      'العشاء'
    ]) {
      await dragIntoView(t, find.text(label));
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('without location shows the picker prompt, never times',
      (t) async {
    await t.pumpWidget(frame(const PrayerTimesPage()));
    await t.pumpAndSettle();

    expect(find.text('اختر موقعك أولاً'), findsOneWidget);
    expect(find.text('الفجر'), findsNothing);
    expect(find.text('استخدام موقع الجهاز'), findsOneWidget);
  });

  testWidgets('device-location failure explains itself in Arabic', (t) async {
    await t.pumpWidget(frame(const PrayerTimesPage()));
    await t.pumpAndSettle();

    await t.tap(find.text('استخدام موقع الجهاز'));
    await t.pumpAndSettle();
    // Geolocator channel mocked as service-disabled (see test_helpers).
    expect(find.text('خدمة الموقع متوقفة على الجهاز'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('city picker stores the location and renders times', (t) async {
    await t.pumpWidget(frame(const PrayerTimesPage()));
    await t.pumpAndSettle();

    await dragIntoView(t, find.text('من قائمة المدن'));
    await t.tap(find.text('من قائمة المدن'));
    await t.pumpAndSettle();
    await dragIntoView(t, find.text('مكة المكرمة، السعودية'));
    await t.tap(find.text('مكة المكرمة، السعودية'));
    await t.pumpAndSettle();

    expect(find.text('مكة المكرمة، السعودية'), findsWidgets);
    expect(find.text('الفجر'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('changing method recalculates and persists', (t) async {
    final settings = Get.find<SettingsStore>();
    await settings.setPrayerLocation(30.0444, 31.2357, 'القاهرة، مصر');

    await t.pumpWidget(frame(const PrayerTimesPage()));
    await t.pumpAndSettle();

    await dragIntoView(t, find.text('طريقة الحساب'));
    await t.tap(find.text('الهيئة المصرية العامة للمساحة'));
    await t.pumpAndSettle();
    await t.tap(find.text('رابطة العالم الإسلامي').last);
    await t.pumpAndSettle();

    expect(settings.method, PrayerMethod.muslimWorldLeague);
    expect(find.text('رابطة العالم الإسلامي'), findsWidgets);
    expect(t.takeException(), isNull);
  });
}

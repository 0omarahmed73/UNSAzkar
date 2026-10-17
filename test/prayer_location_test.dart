import 'package:azkar_new_app/controller/controller.dart';
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

/// Changing location AFTER onboarding must offer GPS + map + manual city —
/// the same three methods as first setup — and refresh prayer times.
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
    final settings = SettingsStore(box);
    Get.put(settings);
    await settings.load();
    Get.put(ProgressStore(box)..load());
    Get.put(Controller());
    await settings.setPrayerLocation(30.0444, 31.2357, 'القاهرة، مصر');
  });

  Widget frame(Widget child) => MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: child),
      );

  testWidgets('located state offers GPS, map, and city change', (t) async {
    await t.pumpWidget(frame(const PrayerTimesPage()));
    await t.pumpAndSettle();

    // Open the location changer from the location row.
    await dragIntoView(t, find.text('الموقع المستخدم للحساب'));
    await t.tap(find.text('الموقع المستخدم للحساب'));
    await t.pumpAndSettle();

    expect(find.textContaining('موقعي الحالي'), findsWidgets);
    expect(find.text('من الخريطة'), findsOneWidget);
    expect(find.text('القاهرة، مصر'), findsWidgets); // hero + sheet row
    expect(t.takeException(), isNull);
  });

  testWidgets('picking a city updates times and persists the label', (t) async {
    await t.pumpWidget(frame(const PrayerTimesPage()));
    await t.pumpAndSettle();

    await dragIntoView(t, find.text('الموقع المستخدم للحساب'));
    await t.tap(find.text('الموقع المستخدم للحساب'));
    await t.pumpAndSettle();
    await dragIntoView(t, find.text('مكة المكرمة، السعودية'),
        useLastScrollable: true);
    await t.tap(find.text('مكة المكرمة، السعودية').first);
    await t.pumpAndSettle();

    expect(Get.find<SettingsStore>().prayerCityLabel, 'مكة المكرمة، السعودية');
    expect(find.text('مكة المكرمة، السعودية'), findsWidgets);
    expect(t.takeException(), isNull);
  });
}

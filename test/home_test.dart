import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/data/repositories/azkar_repository.dart';
import 'package:azkar_new_app/design/app_theme.dart';
import 'package:azkar_new_app/pages/HomePage.dart';
import 'package:azkar_new_app/pages/PrayerTimesPage.dart';
import 'package:azkar_new_app/pages/PrayerTimesPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

void main() {
  // Fixture I/O runs here (real async). Inside testWidgets (FakeAsync)
  // even temp-dir creation can stall, so seeds must not live in bodies.
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

  testWidgets('home renders greeting, routine, shortcuts (RTL)', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: HomeScreen(setPageIndex: (_) {})),
      routes: {PrayerTimesPage.id: (_) => const PrayerTimesPage()},
    ));
    await t.pumpAndSettle();
    await dismissNotifPrompt(t);

    expect(find.text('ورد اليوم'), findsOneWidget);
    expect(find.text('وصول سريع'), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsWidgets);
    expect(find.text('أذكار المساء'), findsWidgets);
    expect(find.text('أذكار النوم'), findsOneWidget);
    expect(find.text('خاتم التسبيح'), findsOneWidget);
    // Prayer card: no location in this fixture → setup CTA.
    expect(find.text('حدد موقعك لعرض مواقيت الصلاة'), findsOneWidget);
    // Below the fold in the 800x600 test viewport; verse/hadith length is
    // random per run, so drag until built instead of fixed offsets.
    await dragIntoView(t, find.text('آية اليوم'));
    expect(find.text('آية اليوم'), findsOneWidget);
    await dragIntoView(t, find.text('حديث اليوم'));
    expect(find.text('حديث اليوم'), findsOneWidget);
    // Empty bookmarks → no "continue reading" section yet.
    expect(find.text('تابع القراءة'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('home prayer card shows the next prayer when located', (t) async {
    await Get.find<SettingsStore>()
        .setPrayerLocation(30.0444, 31.2357, 'القاهرة، مصر');
    await t.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: HomeScreen(setPageIndex: (_) {})),
      routes: {PrayerTimesPage.id: (_) => const PrayerTimesPage()},
    ));
    await t.pumpAndSettle();
    await dismissNotifPrompt(t);

    expect(find.textContaining('الصلاة القادمة'), findsOneWidget);
    await t.tap(find.textContaining('الصلاة القادمة'));
    await t.pumpAndSettle();
    // Card navigates to the full prayer screen.
    expect(find.text('مواعيد اليوم'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}

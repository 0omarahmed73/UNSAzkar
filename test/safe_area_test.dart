import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/notifications/reminder_service.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/data/repositories/azkar_repository.dart';
import 'package:azkar_new_app/design/app_theme.dart';
import 'package:azkar_new_app/pages/AzkarCategoriesPage.dart';
import 'package:azkar_new_app/pages/AzkarPage.dart';
import 'package:azkar_new_app/pages/HomePage.dart';
import 'package:azkar_new_app/pages/PrayersPage.dart';
import 'package:azkar_new_app/pages/SettingsPage.dart';
import 'package:azkar_new_app/pages/TasbeehRingPage.dart';
import 'package:azkar_new_app/pages/ThankingAllahPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

/// Bottom content must stay clear of Android system UI: every scrollable
/// screen reserves the system bottom inset, and the last section scrolls
/// fully into view without errors.
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
    ReminderService.current = null;
  });

  Widget frame(Widget page) => MaterialApp(
        theme: buildLightTheme(),
        home: MediaQuery(
          data: const MediaQueryData(viewPadding: EdgeInsets.only(bottom: 48)),
          child: page,
        ),
      );

  Future<void> expectBottomOk(WidgetTester t, Finder last, String label) async {
    await dragIntoView(t, last, maxDrags: 12);
    expect(last, findsWidgets, reason: label);
    final box = t.getBottomRight(last.first);
    expect(box.dy, lessThanOrEqualTo(600.0), reason: label);
    expect(t.takeException(), isNull, reason: label);
  }

  double listBottomPadding(WidgetTester t) {
    final lists = find.byType(ListView).evaluate();
    expect(lists, isNotEmpty);
    var maxBottom = 0.0;
    for (final e in lists) {
      final padding = (e.widget as ListView).padding;
      if (padding is EdgeInsets) {
        maxBottom = maxBottom > padding.bottom ? maxBottom : padding.bottom;
      }
    }
    return maxBottom;
  }

  testWidgets('home reserves system inset and reaches the end', (t) async {
    await t.pumpWidget(frame(Scaffold(body: HomeScreen(setPageIndex: (_) {}))));
    await t.pumpAndSettle();
    await dismissNotifPrompt(t);
    expect(listBottomPadding(t), greaterThanOrEqualTo(48.0));
    await expectBottomOk(t, find.text('حديث اليوم'), 'home-end');
  });

  testWidgets('azkar list reserves system inset and scrolls fully', (t) async {
    await t.pumpWidget(frame(MaterialApp(
      theme: buildLightTheme(),
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => AzkarPage(),
        settings: const RouteSettings(arguments: 'أذكار الصباح'),
      ),
    )));
    await t.pumpAndSettle();
    expect(listBottomPadding(t), greaterThanOrEqualTo(48.0));
    await dragIntoView(t, find.byType(ListView), maxDrags: 1);
    expect(t.takeException(), isNull);
  });

  testWidgets('tasbeeh reserves system inset and reaches history', (t) async {
    await t.pumpWidget(frame(Scaffold(body: TasbeehRingPage())));
    await t.pumpAndSettle();
    expect(listBottomPadding(t), greaterThanOrEqualTo(48.0));
    await expectBottomOk(t, find.text('الجلسات السابقة'), 'tasbeeh-history');
  });

  testWidgets('settings reserves system inset and reaches about', (t) async {
    await t.pumpWidget(frame(Scaffold(body: const SettingsPage())));
    await t.pumpAndSettle();
    expect(listBottomPadding(t), greaterThanOrEqualTo(48.0));
    await expectBottomOk(t, find.text('عن المحتوى'), 'settings-end');
  });

  testWidgets('dua screen reserves inset and reaches etiquette card',
      (t) async {
    await t.pumpWidget(frame(Scaffold(body: PrayersPage())));
    await t.pumpAndSettle();
    expect(listBottomPadding(t), greaterThanOrEqualTo(48.0));
    await expectBottomOk(t, find.textContaining('آداب الدعاء'), 'dua-end');
  });

  testWidgets('categories reserve inset and reach the last category',
      (t) async {
    await t.pumpWidget(frame(Scaffold(body: AzkarCategoriesPage())));
    await t.pumpAndSettle();
    expect(listBottomPadding(t), greaterThanOrEqualTo(48.0));
    await expectBottomOk(t, find.text('سنن الجمعة'), 'categories-end');
  });

  testWidgets('blessings screen reserves inset', (t) async {
    await t.pumpWidget(frame(Scaffold(body: ThankingAllahPage())));
    await t.pumpAndSettle();
    expect(listBottomPadding(t), greaterThanOrEqualTo(48.0));
    await expectBottomOk(t, find.text('إضافة'), 'thanks-end');
  });
}

import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/models/tasbeeh_session.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/design/app_theme.dart';
import 'package:azkar_new_app/pages/TasbeehRingPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

Future<void> seedTasbeeh() async {
  await GetStorage.init();
  Get.reset();
  final box = GetStorage();
  await box.erase();
  Get.put(SettingsStore(box)..load());
  Get.put(ProgressStore(box)..load());
  Get.put(Controller());
}

void main() {
  // Fixture I/O in real async (see home_test.dart): never inside bodies.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await mockPathProvider();
  });

  setUp(seedTasbeeh);

  test('session completes exactly at target, reset clears', () {
    final s = TasbeehSession(id: 'x', dhikrName: 'تسبيح', target: 3);
    expect(s.isComplete, isFalse);
    s.increment();
    s.increment();
    expect(s.isComplete, isFalse);
    s.increment();
    expect(s.isComplete, isTrue);
    expect(s.completedAt, isNotNull);
    s.reset();
    expect(s.count, 0);
    expect(s.isComplete, isFalse);
  });

  testWidgets('big button counts up and survives rebuild', (t) async {
    await t.pumpWidget(
        MaterialApp(theme: buildLightTheme(), home: TasbeehRingPage()));
    await t.pumpAndSettle();
    expect(find.text('0 / 33'), findsOneWidget);
    await t.tap(find.byIcon(Icons.touch_app_outlined));
    await t.pumpAndSettle();
    expect(find.text('1 / 33'), findsOneWidget);
  });

  testWidgets('counter works with haptics disabled', (t) async {
    await Get.find<SettingsStore>().setHaptics(false);
    await t.pumpWidget(
        MaterialApp(theme: buildLightTheme(), home: TasbeehRingPage()));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.touch_app_outlined));
    await t.pumpAndSettle();
    expect(find.text('1 / 33'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('reset asks for confirmation; cancel keeps the count', (t) async {
    await t.pumpWidget(
        MaterialApp(theme: buildLightTheme(), home: TasbeehRingPage()));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.touch_app_outlined));
    await t.pumpAndSettle();
    await t.tap(find.textContaining('تصفير'));
    await t.pumpAndSettle();
    expect(find.text('تصفير العداد؟'), findsOneWidget);
    await t.tap(find.text('تراجع'));
    await t.pumpAndSettle();
    expect(find.text('1 / 33'), findsOneWidget);
  });

  testWidgets('confirming reset archives the session into history', (t) async {
    await t.pumpWidget(
        MaterialApp(theme: buildLightTheme(), home: TasbeehRingPage()));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.touch_app_outlined));
    await t.pumpAndSettle();
    await t.tap(find.textContaining('تصفير'));
    await t.pumpAndSettle();
    await t.tap(find.text('تصفير وأرشفة'));
    await t.pumpAndSettle();
    expect(find.text('0 / 33'), findsOneWidget);
    // History lives below the fold: drag the outer list into view.
    await t.drag(find.byType(ListView), const Offset(0, -800));
    await t.pumpAndSettle();
    expect(find.text('1 / 33'), findsOneWidget); // history entry
  });
}

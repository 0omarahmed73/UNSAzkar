import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/data/repositories/azkar_repository.dart';
import 'package:azkar_new_app/design/app_theme.dart';
import 'package:azkar_new_app/pages/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

/// First-launch notification prompt: shown once, explains why in Arabic,
/// never nags again. ReminderService is null in tests (plugin unavailable),
/// so the dialog must degrade gracefully — no crash, no fake enable.
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

  testWidgets('first launch shows the one-time notification prompt', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: HomeScreen(setPageIndex: (_) {})),
    ));
    await t.pumpAndSettle();

    expect(find.text('تفعيل التذكير اليومي؟'), findsOneWidget);
    expect(find.text('لاحقًا'), findsOneWidget);
  });

  testWidgets('dismissing records the choice and never asks again', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: HomeScreen(setPageIndex: (_) {})),
    ));
    await t.pumpAndSettle();
    await t.tap(find.text('لاحقًا'));
    await t.pumpAndSettle();

    expect(Get.find<SettingsStore>().notifPromptShown, isTrue);

    // Rebuild (simulated restart of the widget tree): no second prompt.
    await t.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: HomeScreen(setPageIndex: (_) {})),
    ));
    await t.pumpAndSettle();
    expect(find.text('تفعيل التذكير اليومي؟'), findsNothing);
    expect(t.takeException(), isNull);
  });

  test('prompt flag round-trips and backs up', () async {
    final box = GetStorage();
    final s = SettingsStore(box);
    await s.load();
    expect(s.notifPromptShown, isFalse);
    await s.setNotifPromptShown(true);
    final s2 = SettingsStore(box);
    await s2.load();
    expect(s2.notifPromptShown, isTrue);
    expect(s2.toJson()['notifPromptShown'], isTrue);
    expect(await s2.applyJson({'notifPromptShown': true}), isNull);
    expect(s2.notifPromptShown, isTrue);
  });
}

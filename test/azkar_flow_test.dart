import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/data/repositories/azkar_repository.dart';
import 'package:azkar_new_app/design/app_theme.dart';
import 'package:azkar_new_app/pages/AzkarPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

Future<void> seedTestDeps() async {
  await GetStorage.init();
  Get.reset();
  final box = GetStorage();
  await box.erase();
  Get.put(AzkarRepository());
  Get.put(SettingsStore(box)..load());
  Get.put(ProgressStore(box)..load());
  Get.put(Controller());
}

Widget azkarHarness(String args) => MaterialApp(
      theme: buildLightTheme(),
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => AzkarPage(),
        settings: RouteSettings(arguments: args),
      ),
    );

void main() {
  // Fixture I/O in real async (see home_test.dart): never inside bodies.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await mockPathProvider();
  });

  setUp(seedTestDeps);

  test('type strings map to stable category keys', () {
    expect(categoryKeyForType('أذكار الصباح'), 'morning');
    expect(categoryKeyForType('أذكار المساء'), 'evening');
    expect(categoryKeyForType('أذكار النوم'), 'sleep');
    expect(categoryKeyForType('سنن الجمعة'), 'friday');
    expect(categoryKeyForType('أدعية قرآنية'), 'quranDuaa');
    expect(categoryKeyForType('nope'), isNull);
    expect(categoryKeyForType(null), isNull);
  });

  testWidgets('morning list renders items with repeat pills', (t) async {
    await t.pumpWidget(azkarHarness('أذكار الصباح'));
    await t.pumpAndSettle();
    expect(find.text('أذكار الصباح'), findsOneWidget);
    // First morning dhikr (Ayat al-Kursi) present.
    expect(find.textContaining('الكرسي'), findsWidgets);
    expect(find.textContaining('المتبقي'), findsWidgets);
  });

  testWidgets('tapping a dhikr decrements and persists', (t) async {
    final repo = Get.find<AzkarRepository>();
    final progress = Get.find<ProgressStore>();
    final first = repo.items('evening')[0];
    await t.pumpWidget(azkarHarness('أذكار المساء'));
    await t.pumpAndSettle();
    expect(find.text(first.arabicText), findsOneWidget);
    expect(progress.remaining(first.id), isNull); // untouched → full count

    // Tap the first card in the list (AppBar buttons excluded).
    final cards = find.descendant(
        of: find.byType(ListView), matching: find.byType(InkWell));
    await t.tap(cards.first);
    await t.pumpAndSettle();

    // Completed 1x item hides itself and the count persists in the store.
    expect(find.text(first.arabicText), findsNothing);
    expect(progress.remaining(first.id), 0);

    // Rebuild from the same box: progress survived.
    await t.pumpWidget(azkarHarness('أذكار المساء'));
    await t.pumpAndSettle();
    expect(find.text(first.arabicText), findsNothing);
    expect(progress.remaining(first.id), 0);
  });

  testWidgets('unknown args show a safe fallback, never a crash', (t) async {
    await t.pumpWidget(azkarHarness('فئة غير موجودة'));
    await t.pumpAndSettle();
    expect(find.text('اختر فئة من الأذكار'), findsOneWidget);
  });

  testWidgets('text size controls re-render without overflow', (t) async {
    await t.pumpWidget(azkarHarness('أذكار الصباح'));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.text_increase));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
}

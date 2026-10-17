import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/prefs/custom_azkar_store.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/data/repositories/azkar_repository.dart';
import 'package:azkar_new_app/design/app_theme.dart';
import 'package:azkar_new_app/pages/CustomAzkarPage.dart';
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
    final customs = CustomAzkarStore(box);
    await customs.load();
    Get.put(customs);
    Get.put(AzkarRepository(customs: customs));
    Get.put(SettingsStore(box)..load());
    Get.put(ProgressStore(box)..load());
    Get.put(Controller());
  });

  Widget harness() => MaterialApp(
        theme: buildLightTheme(),
        routes: {
          CustomAzkarPage.id: (_) => const CustomAzkarPage(),
          CustomAzkarEditorPage.id: (_) => const CustomAzkarEditorPage(),
        },
        home: const Scaffold(body: CustomAzkarPage()),
      );

  testWidgets('empty shelf explains and offers adding', (t) async {
    await t.pumpWidget(harness());
    await t.pumpAndSettle();
    expect(find.text('إدارة الأذكار'), findsOneWidget);
    expect(find.text('لا توجد أذكار مخصصة بعد'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('adding a custom dhikr end to end', (t) async {
    await t.pumpWidget(harness());
    await t.pumpAndSettle();

    await t.tap(find.byTooltip('إضافة ذكر'));
    await t.pumpAndSettle();
    expect(find.text('ذكر جديد'), findsOneWidget);

    await t.enterText(find.byKey(const ValueKey('customText')), 'دعائي الخاص');
    // Default repeat is 1; bump twice to reach 3. Morning is pre-selected.
    await t.tap(find.byTooltip('زيادة التكرار'));
    await t.tap(find.byTooltip('زيادة التكرار'));
    await t.pumpAndSettle();
    expect(find.text('أذكار الصباح'), findsOneWidget);
    await t.tap(find.text('حفظ'));
    await t.pumpAndSettle();

    expect(find.text('دعائي الخاص'), findsOneWidget);
    expect(Get.find<CustomAzkarStore>().customs.length, 1);
    expect(Get.find<CustomAzkarStore>().customs.first.repeatTotal, 3);
    expect(t.takeException(), isNull);
  });

  testWidgets('blank text is rejected, not saved', (t) async {
    await t.pumpWidget(harness());
    await t.pumpAndSettle();

    await t.tap(find.byTooltip('إضافة ذكر'));
    await t.pumpAndSettle();
    await t.tap(find.text('حفظ'));
    await t.pumpAndSettle();

    expect(find.text('اكتب نص الذكر أولاً'), findsOneWidget);
    expect(Get.find<CustomAzkarStore>().customs, isEmpty);
    expect(t.takeException(), isNull);
  });

  testWidgets('deleting asks for confirmation', (t) async {
    final store = Get.find<CustomAzkarStore>();
    await store.add(text: 'للحذف', repeat: 2, categories: ['morning']);

    await t.pumpWidget(harness());
    await t.pumpAndSettle();

    await t.tap(find.byIcon(Icons.delete_outline));
    await t.pumpAndSettle();
    expect(find.text('حذف هذا الذكر؟'), findsOneWidget);
    // Cancel first: nothing lost.
    await t.tap(find.text('تراجع'));
    await t.pumpAndSettle();
    expect(store.customs.length, 1);
    // Confirm this time.
    await t.tap(find.byIcon(Icons.delete_outline));
    await t.pumpAndSettle();
    await t.tap(find.text('حذف'));
    await t.pumpAndSettle();
    expect(store.customs, isEmpty);
    expect(t.takeException(), isNull);
  });
}

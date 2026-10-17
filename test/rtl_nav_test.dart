import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/data/repositories/azkar_repository.dart';
import 'package:azkar_new_app/design/app_theme.dart';
import 'package:azkar_new_app/pages/HomePage.dart';
import 'package:azkar_new_app/pages/TasbeehRingPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

/// RTL navigation contract: tabs run right→left as
/// الرئيسية، الأذكار، الدعاء، عنا — and the header title sits right.
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

  testWidgets('bottom tabs read right-to-left in the required order',
      (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(),
      ),
    ));
    await t.pumpAndSettle();
    await dismissNotifPrompt(t);

    final bar = t.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    final labels = bar.items.map((i) => (i.label ?? '').trim()).toList();
    // Logical (left-to-right array) order must mirror the visual order:
    // with RTL layout, items[0] renders at the right edge.
    expect(labels, ['الرئيسية', 'الأذكار', 'السبحة', 'المكتبة']);
    expect(bar.currentIndex, 0);
  });

  testWidgets('tapping each tab opens its destination', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      routes: {
        TasbeehRingPage.id: (_) => TasbeehRingPage(),
      },
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(),
      ),
    ));
    await t.pumpAndSettle();
    await dismissNotifPrompt(t);

    // الأذكار tab (index 1) opens the categories list.
    await t.tap(find.text('الأذكار'));
    await t.pumpAndSettle();
    expect(find.text('تصنيفات الأذكار'), findsOneWidget);

    // المكتبة tab (index 3) opens the dua screen.
    await t.tap(find.text('المكتبة'));
    await t.pumpAndSettle();
    expect(find.text('أدعية قرآنية'), findsOneWidget);

    // السبحة opens the counter as its own screen.
    await t.tap(find.text('السبحة'));
    await t.pumpAndSettle();
    expect(find.text('خاتم التسبيح'), findsWidgets);
    await t.pageBack();
    await t.pumpAndSettle();

    // Back to الرئيسية (index 0).
    await t.tap(find.text('الرئيسية'));
    await t.pumpAndSettle();
    expect(find.text('ورد اليوم'), findsOneWidget);
  });

  testWidgets('header title sits on the right in RTL', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(),
      ),
    ));
    await t.pumpAndSettle();
    await dismissNotifPrompt(t);

    final title = t.getTopLeft(find.text('أُنس'));
    final settings = t.getTopLeft(find.byIcon(Icons.settings_outlined));
    // In RTL, "right" means larger dx... title must be right of actions.
    expect(title.dx, greaterThan(settings.dx));
    expect(t.takeException(), isNull);
  });
}

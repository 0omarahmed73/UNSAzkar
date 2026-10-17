import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/data/repositories/azkar_repository.dart';
import 'package:azkar_new_app/design/app_theme.dart';
import 'package:azkar_new_app/pages/HomePage.dart';
import 'package:azkar_new_app/pages/ThankingAllahPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

/// شكر النعم must be reachable and functional — it silently lost its
/// navigation entry and became a dead route.
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

  testWidgets('شكر النعم opens from the Dua tab and keeps entries', (t) async {
    await t.pumpWidget(GetMaterialApp(
      theme: buildLightTheme(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(),
      ),
      routes: {
        ThankingAllahPage.id: (_) => ThankingAllahPage(),
      },
    ));
    await t.pumpAndSettle();
    await dismissNotifPrompt(t);

    // الدعاء tab → entry card → شكر النعم page.
    await t.tap(find.text('المكتبة'));
    await t.pumpAndSettle();
    expect(find.text('شكر النعم'), findsOneWidget);
    await t.tap(find.text('شكر النعم'));
    await t.pumpAndSettle();
    expect(find.textContaining('الحافظ الجالب'), findsOneWidget);

    // Add a blessing; it renders immediately.
    await t.tap(find.text('إضافة'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField), 'نعمة الاختبار');
    final dialogAdd = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(ElevatedButton, 'إضافة'),
    );
    await t.tap(dialogAdd);
    await t.pumpAndSettle();
    expect(find.text('نعمة الاختبار'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}

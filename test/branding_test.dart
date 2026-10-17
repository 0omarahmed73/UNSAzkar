import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/data/repositories/azkar_repository.dart';
import 'package:azkar_new_app/design/app_theme.dart';
import 'package:azkar_new_app/pages/AboutUsPage.dart';
import 'package:azkar_new_app/pages/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

/// Approved branding: أُنس | UNS, tagline رفيق يومك. The old name must be
/// gone from every user-visible surface (technical ids stay untouched).
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

  testWidgets('home shows أُنس, not the old name', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: HomePage(),
        ),
      ),
    );
    await t.pumpAndSettle();
    await dismissNotifPrompt(t);
    expect(find.text('أُنس'), findsOneWidget);
    expect(find.text('أذكار المسلم'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('about page carries the UNS tagline رفيق يومك', (t) async {
    await t.pumpWidget(
      MaterialApp(theme: buildLightTheme(), home: const AboutUsPage()),
    );
    await t.pumpAndSettle();
    expect(find.text('رفيق يومك'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}

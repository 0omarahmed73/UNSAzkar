import 'package:azkar_new_app/components/zikr_item.dart';
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

Widget azkarMotionHarness(String args, {bool reducedMotion = false}) =>
    MaterialApp(
      theme: buildLightTheme(),
      builder: reducedMotion
          ? (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              )
          : null,
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => AzkarPage(),
        settings: RouteSettings(arguments: args),
      ),
    );

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

  testWidgets('rapid taps register every count exactly', (t) async {
    await t.pumpWidget(azkarMotionHarness('أذكار الصباح'));
    await t.pumpAndSettle();
    final progress = Get.find<ProgressStore>();

    // Model rapid tapping: one frame runs between taps, no settling.
    Future<void> tapFirst() => t.tap(find
        .descendant(of: find.byType(ListView), matching: find.byType(InkWell))
        .first);
    // Complete the first 1x card and let its fade finish.
    await tapFirst();
    await t.pumpAndSettle();
    expect(progress.remaining('morning:00'), 0);
    // Three rapid taps on the next (3x) card.
    await tapFirst();
    await t.pump(const Duration(milliseconds: 16));
    await tapFirst();
    await t.pump(const Duration(milliseconds: 16));
    await tapFirst();
    await t.pumpAndSettle();

    expect(progress.remaining('morning:01'), 0);
    expect(t.takeException(), isNull);
  });

  testWidgets('completed card fades out instead of vanishing instantly',
      (t) async {
    await t.pumpWidget(azkarMotionHarness('أذكار الصباح'));
    await t.pumpAndSettle();
    final firstId = Get.find<AzkarRepository>().items('morning')[0].id;
    final fading =
        find.byWidgetPredicate((w) => w is AnimatedOpacity && w.opacity == 0.0);

    await t.tap(find
        .descendant(of: find.byType(ListView), matching: find.byType(InkWell))
        .first);
    // Mid-animation: the completed card is still mounted, fading out.
    await t.pump(const Duration(milliseconds: 100));
    expect(fading, findsOneWidget);
    expect(Get.find<ProgressStore>().remaining(firstId), 0);
    // After the fade: unmounted without layout errors.
    await t.pumpAndSettle();
    expect(fading, findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('reduced motion removes completed cards immediately', (t) async {
    await t.pumpWidget(azkarMotionHarness('أذكار الصباح', reducedMotion: true));
    await t.pumpAndSettle();
    final firstId = Get.find<AzkarRepository>().items('morning')[0].id;
    final fading =
        find.byWidgetPredicate((w) => w is AnimatedOpacity && w.opacity == 0.0);

    await t.tap(find
        .descendant(of: find.byType(ListView), matching: find.byType(InkWell))
        .first);
    await t.pump();
    // No fade-out plays: count stored and card unmounted right away.
    expect(Get.find<ProgressStore>().remaining(firstId), 0);
    expect(fading, findsNothing);
    expect(t.takeException(), isNull);
  });
}

import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/models/tasbeeh_session.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/design/app_theme.dart';
import 'package:azkar_new_app/pages/TasbeehRingPage.dart';
import 'package:azkar_new_app/services/haptics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

const _boxName = 'haptics_test_box';

class _FakeHaptics implements HapticsService {
  int lightCalls = 0;
  int heavyCalls = 0;

  @override
  Future<void> heavyImpact() async => heavyCalls++;

  @override
  Future<void> lightImpact() async => lightCalls++;

  @override
  Future<bool> canVibrate() async => true;
}

Future<void> _seedTasbeeh({required int target, required bool haptics}) async {
  Get.reset();
  final box = GetStorage(_boxName);
  await box.erase();
  final settings = Get.put(SettingsStore(box)..load());
  final progress = Get.put(ProgressStore(box)..load());
  Get.put(Controller());
  progress.activeTasbeeh =
      TasbeehSession(id: 't1', dhikrName: 'سبحان الله', target: target);
  await progress.saveTasbeeh();
  await settings.setHaptics(haptics);
}

Widget _tasbeehHarness() =>
    MaterialApp(theme: buildLightTheme(), home: TasbeehRingPage());

Future<void> _pump(WidgetTester t, [int ms = 220]) async {
  await t.pump();
  await t.pump(Duration(milliseconds: ms));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await mockPathProvider();
    await GetStorage.init(_boxName);
  });

  late HapticsService original;
  late _FakeHaptics fake;

  setUp(() {
    original = HapticsService.instance;
    fake = _FakeHaptics();
    HapticsService.instance = fake;
  });

  tearDown(() {
    HapticsService.instance = original;
  });

  testWidgets('tasbeeh tap does not invoke haptic when disabled', (t) async {
    await _seedTasbeeh(target: 2, haptics: false);
    await t.pumpWidget(_tasbeehHarness());
    await _pump(t, 250);

    await t.tap(find.byIcon(Icons.touch_app_outlined));
    await _pump(t, 250);

    expect(find.text('1 / 2'), findsOneWidget);
    expect(fake.lightCalls, 0);
    expect(fake.heavyCalls, 0);
  });

  testWidgets('tasbeeh completion invokes one light + one heavy haptic',
      (t) async {
    await _seedTasbeeh(target: 1, haptics: true);
    await t.pumpWidget(_tasbeehHarness());
    await _pump(t, 250);

    await t.tap(find.byIcon(Icons.touch_app_outlined));
    await _pump(t, 250);

    expect(find.text('1 / 1'), findsOneWidget);
    expect(fake.lightCalls, 1);
    expect(fake.heavyCalls, 1);
  });
}

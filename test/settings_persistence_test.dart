import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

/// Restart persistence: what a full process restart must restore.
/// A "restart" here = brand-new store + controller over the same box.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await mockPathProvider();
  });

  test('display name round-trips across a simulated restart', () async {
    await GetStorage.init('persistName');
    final box = GetStorage('persistName');
    await box.erase();

    final s1 = SettingsStore(box);
    await s1.load();
    expect(s1.userName, isNull);
    await s1.setUserName('عبد الله');

    // Simulated restart: fresh instances, same backing box.
    final s2 = SettingsStore(box);
    await s2.load();
    expect(s2.userName, 'عبد الله');

    await s2.setUserName(null);
    final s3 = SettingsStore(box);
    await s3.load();
    expect(s3.userName, isNull);
  });

  test('theme mode round-trips across a simulated restart', () async {
    await GetStorage.init('persistTheme');
    final box = GetStorage('persistTheme');
    await box.erase();

    final s1 = SettingsStore(box);
    await s1.load();
    await s1.setThemeMode('amoled');

    final s2 = SettingsStore(box);
    await s2.load();
    expect(s2.themeMode, 'amoled');
  });

  test('system theme mode persists and is accepted', () async {
    await GetStorage.init('persistSystem');
    final box = GetStorage('persistSystem');
    await box.erase();

    final s1 = SettingsStore(box);
    await s1.load();
    await s1.setThemeMode('system');

    final s2 = SettingsStore(box);
    await s2.load();
    expect(s2.themeMode, 'system');
  });

  test('corrupt or unknown stored theme falls back to light, never dark',
      () async {
    await GetStorage.init('persistCorrupt');
    final box = GetStorage('persistCorrupt');
    await box.erase();
    await box.write('v2.themeMode', 'midnight-neon');
    await box.write('theme', 'amoled-dark');

    final s = SettingsStore(box);
    await s.load();
    expect(s.themeMode, 'light');
  });

  test('controller restores stored mode on init (restart path)', () async {
    await GetStorage.init();
    Get.reset();
    final box = GetStorage();
    await box.erase();
    await box.write('theme', 'dark');
    await box.write('v2.themeMode', 'dark');

    final c = Controller();
    c.onInit();
    expect(c.mode.value, 'dark');
    Get.delete<Controller>(force: true);
  });

  test('controller restore() applies v2 system mode after restart', () async {
    await GetStorage.init();
    Get.reset();
    final box = GetStorage();
    await box.erase();
    await box.write('theme', 'light');
    await box.write('v2.themeMode', 'system');

    final c = Controller();
    c.onInit();
    expect(c.mode.value, 'light');
    c.restore();
    expect(c.mode.value, 'system');
    Get.delete<Controller>(force: true);
  });

  test('controller falls back to light on unknown stored value', () async {
    await GetStorage.init();
    Get.reset();
    final box = GetStorage();
    await box.erase();
    await box.write('theme', 'neon');

    final c = Controller();
    c.onInit();
    expect(c.mode.value, 'light');
    Get.delete<Controller>(force: true);
  });
}

import 'package:azkar_new_app/data/backup_service.dart';
import 'package:azkar_new_app/data/prayer/prayer_service.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

/// Prayer preferences persistence + backup/restore must never silently
/// discard theme, name, location, or calculation settings.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await mockPathProvider();
  });

  Future<(SettingsStore, ProgressStore)> fresh(String name) async {
    await GetStorage.init(name);
    final box = GetStorage(name);
    await box.erase();
    final s = SettingsStore(box);
    final p = ProgressStore(box);
    await s.load();
    await p.load();
    return (s, p);
  }

  test('prayer prefs round-trip across a simulated restart', () async {
    final (s1, _) = await fresh('prayerPrefs');
    await s1.setPrayerMethod(PrayerMethod.ummAlQura);
    await s1.setPrayerMadhab(PrayerMadhab.hanafi);
    await s1.setPrayerLocation(21.4225, 39.8262, 'مكة المكرمة');
    await s1.setPrayerReminder(PrayerKind.fajr, true);

    final (s2, _) = await fresh('prayerPrefs2');
    // different box → defaults, proving isolation of the test itself
    expect(s2.method, PrayerMethod.egyptian);

    final box = GetStorage('prayerPrefs');
    final s3 = SettingsStore(box);
    await s3.load();
    expect(s3.method, PrayerMethod.ummAlQura);
    expect(s3.madhab, PrayerMadhab.hanafi);
    expect(s3.prayerLat, 21.4225);
    expect(s3.prayerCityLabel, 'مكة المكرمة');
    expect(s3.prayerReminder(PrayerKind.fajr), isTrue);
    expect(s3.prayerReminder(PrayerKind.dhuhr), isFalse);
  });

  test('unknown method/madhab keys fall back safely', () async {
    await GetStorage.init('prayerFallback');
    final box = GetStorage('prayerFallback');
    await box.erase();
    await box.write('v2.prayerMethod', 'atlantis');
    await box.write('v2.prayerMadhab', 'maliki');
    final s = SettingsStore(box);
    await s.load();
    expect(s.method, PrayerMethod.egyptian);
    expect(s.madhab, PrayerMadhab.shafi);
  });

  test('backup round-trips theme, name, location, and calc prefs', () async {
    final (s1, p1) = await fresh('backupFull');
    await s1.setThemeMode('amoled');
    await s1.setUserName('عبد الله');
    await s1.setPrayerMethod(PrayerMethod.karachi);
    await s1.setPrayerMadhab(PrayerMadhab.hanafi);
    await s1.setPrayerLocation(24.7136, 46.6753, 'الرياض');
    await s1.setReminderMorning('06:30');
    await p1.toggleBookmark('morning:00');

    final data = BackupService.exportData(settings: s1, progress: p1);

    final (s2, p2) = await fresh('backupRestore');
    final error =
        await BackupService.importData(settings: s2, progress: p2, data: data);
    expect(error, isNull);
    expect(s2.themeMode, 'amoled');
    expect(s2.userName, 'عبد الله');
    expect(s2.method, PrayerMethod.karachi);
    expect(s2.madhab, PrayerMadhab.hanafi);
    expect(s2.prayerLat, 24.7136);
    expect(s2.prayerCityLabel, 'الرياض');
    expect(s2.reminderMorning, '06:30');
    expect(p2.isBookmarked('morning:00'), isTrue);
  });

  test('corrupt backup returns an error and touches nothing', () async {
    final (s, p) = await fresh('backupCorrupt');
    await s.setUserName('keep-me');
    for (final bad in [
      'not-a-map',
      {'version': 999},
      {'version': 3, 'settings': 'nope', 'progress': {}}
    ]) {
      expect(
          await BackupService.importData(settings: s, progress: p, data: bad),
          isNotNull);
    }
    expect(s.userName, 'keep-me');
    expect(p.bookmarks, isEmpty);
  });
}

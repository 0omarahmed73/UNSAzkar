import 'package:azkar_new_app/data/backup_service.dart';
import 'package:azkar_new_app/data/prefs/custom_azkar_store.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/data/repositories/azkar_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await mockPathProvider();
  });

  Future<CustomAzkarStore> fresh(String name) async {
    await GetStorage.init(name);
    final box = GetStorage(name);
    await box.erase();
    final s = CustomAzkarStore(box);
    await s.load();
    return s;
  }

  test('create validates text and repetition count', () async {
    final s = await fresh('customCreate');
    expect(
        await s.add(text: '   ', repeat: 3, categories: ['morning']), isNull);
    expect(
        await s.add(text: 'ذكر', repeat: 0, categories: ['morning']), isNull);
    expect(await s.add(text: 'ذكر', repeat: 1001, categories: ['morning']),
        isNull);
    expect(await s.add(text: 'ذكر', repeat: 3, categories: []), isNull);
    final created = await s.add(
        text: 'سُبْحَانَ اللهِ وَبِحَمْدِهِ',
        repeat: 100,
        virtue: 'فضل عظيم',
        categories: ['morning', 'evening']);
    expect(created, isNotNull);
    expect(created!.id, startsWith('custom:'));
    expect(s.customs.length, 1);
  });

  test('custom entry appears in assigned categories and the custom shelf',
      () async {
    final s = await fresh('customAssign');
    final c =
        (await s.add(text: 'ذكري الخاص', repeat: 7, categories: ['morning']))!;
    final repo = AzkarRepository(customs: s);
    expect(repo.items('morning').map((e) => e.id), contains(c.id));
    expect(repo.items('evening').map((e) => e.id), isNot(contains(c.id)));
    expect(repo.items('custom').map((e) => e.id), contains(c.id));
    expect(repo.byId(c.id)!.arabicText, 'ذكري الخاص');
    // Bundled content untouched: same count as a repo without customs.
    expect(repo.items('morning').length,
        AzkarRepository().items('morning').length + 1);
  });

  test('edit updates text, repeat, and assignment', () async {
    final s = await fresh('customEdit');
    final c = (await s.add(text: 'قديم', repeat: 1, categories: ['morning']))!;
    expect(await s.update(c.id, text: 'جديد', repeat: 5), isTrue);
    expect(await s.update(c.id, categories: ['evening']), isTrue);
    expect(await s.update('custom:nope', text: 'x'), isFalse);
    expect(await s.update(c.id, text: '  '), isFalse);

    final repo = AzkarRepository(customs: s);
    expect(repo.byId(c.id)!.arabicText, 'جديد');
    expect(repo.byId(c.id)!.repeatTotal, 5);
    expect(repo.items('morning').map((e) => e.id), isNot(contains(c.id)));
    expect(repo.items('evening').map((e) => e.id), contains(c.id));
  });

  test('delete removes from every category', () async {
    final s = await fresh('customDelete');
    final c = (await s
        .add(text: 'مؤقت', repeat: 2, categories: ['morning', 'evening']))!;
    await s.remove(c.id);
    expect(s.customs, isEmpty);
    final repo = AzkarRepository(customs: s);
    expect(repo.byId(c.id), isNull);
  });

  test('reorder changes custom shelf order and persists', () async {
    final s = await fresh('customReorder');
    final a = (await s.add(text: 'أ', repeat: 1, categories: ['custom']))!;
    final b = (await s.add(text: 'ب', repeat: 1, categories: ['custom']))!;
    await s.reorder([b.id, a.id]);
    expect(s.customs.map((e) => e.id).toList(), [b.id, a.id]);

    final s2 = CustomAzkarStore(GetStorage('customReorder'));
    await s2.load();
    expect(s2.customs.map((e) => e.id).toList(), [b.id, a.id]);
  });

  test('restore defaults clears customs but never bundled content', () async {
    final s = await fresh('customRestore');
    await s.add(text: 'x', repeat: 1, categories: ['morning']);
    final before = AzkarRepository().items('morning').length;
    await s.restoreDefaults();
    expect(s.customs, isEmpty);
    expect(AzkarRepository(customs: s).items('morning').length, before);
  });

  test('backup round-trips customs', () async {
    final s = await fresh('customBackup');
    await s.add(text: 'محفوظ', repeat: 3, categories: ['evening']);
    final data = s.toJson();
    final s2 = await fresh('customRestore2');
    expect(s2.importJson({'nope': 1}), isNotNull);
    expect(s2.importJson(data), isNull);
    expect(s2.customs.length, 1);
    expect(s2.customs.first.arabicText, 'محفوظ');
    expect(s2.importJson('garbage'), isNotNull);
  });

  test('full backup carries customs and restores them', () async {
    await GetStorage.init('fullBackupA');
    final boxA = GetStorage('fullBackupA');
    await boxA.erase();
    final settingsA = SettingsStore(boxA)..load();
    final progressA = ProgressStore(boxA)..load();
    final customsA = CustomAzkarStore(boxA);
    await customsA.load();
    await customsA.add(text: 'وردي الخاص', repeat: 5, categories: ['morning']);

    final data = BackupService.exportData(
        settings: settingsA, progress: progressA, customs: customsA);

    await GetStorage.init('fullBackupB');
    final boxB = GetStorage('fullBackupB');
    await boxB.erase();
    final settingsB = SettingsStore(boxB)..load();
    final progressB = ProgressStore(boxB)..load();
    final customsB = CustomAzkarStore(boxB);
    await customsB.load();
    final error = await BackupService.importData(
        settings: settingsB,
        progress: progressB,
        customs: customsB,
        data: data);
    expect(error, isNull);
    expect(customsB.customs.length, 1);
    expect(customsB.customs.first.arabicText, 'وردي الخاص');

    // Corrupt customs section rolls everything back.
    final bad = Map<String, dynamic>.from(data as Map);
    bad['customs'] = {'version': 1, 'items': 'nope'};
    final before = customsB.customs.length;
    expect(
        await BackupService.importData(
            settings: settingsB,
            progress: progressB,
            customs: customsB,
            data: bad),
        isNotNull);
    expect(customsB.customs.length, before);
  });
}

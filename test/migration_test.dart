import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

Future<GetStorage> freshBox(String name) async {
  await mockPathProvider();
  await GetStorage.init(name);
  final box = GetStorage(name);
  await box.erase();
  return box;
}

void main() {
  test('legacy v1 storage migrates without loss or crash', () async {
    final box = await freshBox('migV1');
    await box.write('theme', 'dark');
    await box.write('blesses', [
      {'id': 0, 'name': 'سمعي', 'done': true},
    ]);

    final settings = SettingsStore(box);
    await settings.load();
    expect(settings.themeMode, 'dark');

    // Legacy keys preserved verbatim.
    expect(box.read('theme'), 'dark');
    expect((box.read('blesses') as List).length, 1);
  });

  test('fresh install gets sane defaults', () async {
    final box = await freshBox('migFresh');
    final settings = SettingsStore(box);
    await settings.load();
    expect(settings.themeMode, 'light');
    expect(settings.textScale, 1.0);

    final progress = ProgressStore(box);
    await progress.load();
    expect(progress.bookmarks, isEmpty);
  });

  test('bookmarks and remaining counts persist across store instances',
      () async {
    final box = await freshBox('migPersist');
    final p1 = ProgressStore(box);
    await p1.load();
    await p1.toggleBookmark('morning:00');
    await p1.setRemaining('morning:00', 2);

    final p2 = ProgressStore(box);
    await p2.load();
    expect(p2.isBookmarked('morning:00'), isTrue);
    expect(p2.remaining('morning:00'), 2);
  });

  test('corrupt import returns an error string, never throws', () async {
    final box = await freshBox('migCorrupt');
    final progress = ProgressStore(box);
    await progress.load();
    expect(progress.importData('not-a-map'), isNotNull);
    expect(progress.importData({'version': 999}), isNotNull);
    expect(progress.importData({'version': 2, 'bookmarks': 'nope'}), isNotNull);
    // State untouched by failed imports.
    expect(progress.bookmarks, isEmpty);
  });

  test('export/import round-trip preserves data', () async {
    final box = await freshBox('migRound');
    final p1 = ProgressStore(box);
    await p1.load();
    await p1.toggleBookmark('evening:03');
    await p1.setRemaining('evening:03', 1);
    final data = p1.exportData();

    final box2 = await freshBox('migRound2');
    final p2 = ProgressStore(box2);
    await p2.load();
    expect(p2.importData(data), isNull);
    expect(p2.isBookmarked('evening:03'), isTrue);
    expect(p2.remaining('evening:03'), 1);
  });
}

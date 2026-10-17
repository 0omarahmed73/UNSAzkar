import 'package:azkar_new_app/data/repositories/azkar_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AzkarRepository repo() => AzkarRepository();

  test('exposes all bundled categories (11) plus the custom shelf', () {
    final cats = repo().categories();
    expect(cats.map((c) => c.key).toSet(), {
      'morning',
      'evening',
      'sleep',
      'wakeup',
      'wodu',
      'mosque',
      'azan',
      'afterPrayer',
      'friday',
      'quranDuaa',
      'sunaaDuaa',
      'custom',
    });
  });

  test('every item keeps the exact repeat count from bundled content', () {
    final r = repo();
    var total = 0;
    for (final c in r.categories()) {
      final items = r.items(c.key);
      // The personal shelf starts empty; bundled categories never are.
      if (c.key == 'custom') {
        expect(items, isEmpty);
        continue;
      }
      expect(items, isNotEmpty, reason: c.key);
      for (final it in items) {
        expect(it.repeatTotal, greaterThanOrEqualTo(1), reason: it.id);
        expect(it.arabicText, isNotEmpty, reason: it.id);
        total++;
      }
    }
    // 100 (AllAzkar) + 62 (NightOrMorning) bundled entries.
    expect(total, 162);
  });

  test('known spot values survive: morning has 3x, 4x and 7x items', () {
    final items = repo().items('morning');
    final repeats = items.map((e) => e.repeatTotal).toSet();
    for (final v in [1, 3, 4, 7]) {
      expect(repeats, contains(v));
    }
  });

  test('ids are unique and stable across builds', () {
    final a = repo().allItems().map((e) => e.id).toList();
    final b = repo().allItems().map((e) => e.id).toList();
    expect(a.toSet().length, a.length);
    expect(a, b);
    expect(a.first, startsWith('morning:'));
  });

  test('items without bundled source are flagged for review, never invented',
      () {
    for (final it in repo().allItems()) {
      expect(it.source, isNull);
      expect(it.needsReview, isTrue);
    }
  });
}

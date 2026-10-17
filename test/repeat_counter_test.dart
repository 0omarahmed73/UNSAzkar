import 'package:azkar_new_app/logic/repeat_counter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts with remaining == total', () {
    expect(RepeatCounter(total: 3).remaining, 3);
  });

  test('three taps complete a total-3 item; fourth tap is a no-op', () {
    final c = RepeatCounter(total: 3);
    expect(c.tap(), isFalse);
    expect(c.tap(), isFalse);
    expect(c.tap(), isTrue);
    expect(c.isComplete, isTrue);
    expect(c.tap(), isTrue);
    expect(c.remaining, 0);
  });

  test('preserves source repeat values incl. 7 and 34', () {
    for (final t in [1, 3, 4, 7, 33, 34, 100]) {
      final c = RepeatCounter(total: t);
      for (var i = 0; i < t; i++) c.tap();
      expect(c.isComplete, isTrue, reason: 'total=$t');
    }
  });

  test('reset restores remaining', () {
    final c = RepeatCounter(total: 3)
      ..tap()
      ..tap();
    c.reset();
    expect(c.remaining, 3);
    expect(c.isComplete, isFalse);
  });

  test('total < 1 throws', () {
    expect(() => RepeatCounter(total: 0), throwsArgumentError);
  });
}

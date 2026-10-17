import 'package:azkar_new_app/logic/daily_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fraction 2/5 == 0.4', () {
    expect(DailyProgress(completed: 2, total: 5).fraction, closeTo(0.4, 1e-9));
  });

  test('zero total yields 0 fraction, not NaN', () {
    expect(DailyProgress(completed: 0, total: 0).fraction, 0);
  });

  test('same calendar day does not roll over; next day does', () {
    final day1 = DateTime(2026, 10, 17, 8);
    final day1Evening = DateTime(2026, 10, 17, 22);
    final day2 = DateTime(2026, 10, 18, 6);
    expect(DailyProgress.shouldRollover(day1, day1Evening), isFalse);
    expect(DailyProgress.shouldRollover(day1, day2), isTrue);
    expect(DailyProgress.shouldRollover(null, day1), isTrue);
  });
}

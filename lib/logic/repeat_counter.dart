/// Repetition counter for a single dhikr item.
///
/// Pure Dart (no Flutter imports) so it is unit-testable.
/// [total] is the required repetition count from bundled content (1/3/4/7/34…).
class RepeatCounter {
  RepeatCounter({required this.total}) : remaining = total {
    if (total < 1) throw ArgumentError.value(total, 'total', 'must be >= 1');
  }

  final int total;
  int remaining;

  bool get isComplete => remaining <= 0;

  /// Registers one recitation. Returns true if this tap completed the item.
  /// Further taps after completion are no-ops returning true.
  bool tap() {
    if (isComplete) return true;
    remaining--;
    return isComplete;
  }

  void reset() => remaining = total;
}

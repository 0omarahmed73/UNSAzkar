/// Daily routine progress with date-boundary rollover.
///
/// Pure Dart. Callers pass "today" explicitly so tests control time.
class DailyProgress {
  DailyProgress({required this.completed, required this.total});

  int completed;
  final int total;

  double get fraction => total == 0 ? 0 : completed / total;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns true when a new day started (caller should reset progress).
  static bool shouldRollover(DateTime? lastOpen, DateTime today) {
    if (lastOpen == null) return true;
    return !isSameDay(lastOpen, today);
  }
}

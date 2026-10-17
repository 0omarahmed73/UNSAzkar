/// A tasbeeh session: one dhikr counted toward a target.
///
/// Persisted in [ProgressStore]; completed sessions append to history.

class TasbeehSession {
  TasbeehSession({
    required this.id,
    required this.dhikrName,
    required this.target,
    this.count = 0,
    DateTime? startedAt,
    this.completedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  final String id;
  final String dhikrName;
  final int target;
  int count;
  final DateTime startedAt;
  DateTime? completedAt;

  bool get isComplete => count >= target;

  void increment() {
    count++;
    if (isComplete) completedAt ??= DateTime.now();
  }

  void reset() {
    count = 0;
    completedAt = null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dhikrName': dhikrName,
        'target': target,
        'count': count,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory TasbeehSession.fromJson(Map<String, dynamic> json) => TasbeehSession(
        id: json['id'] as String,
        dhikrName: json['dhikrName'] as String,
        target: (json['target'] as num).toInt(),
        count: (json['count'] as num?)?.toInt() ?? 0,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
      );
}

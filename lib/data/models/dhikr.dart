/// Stable data models for adhkar content.
///
/// Identity is the string [DhikrItem.id] (`<categoryKey>:<index>`), never a
/// list position, so progress/bookmarks survive content edits. Bundled
/// Arabic text is carried verbatim; [source] stays null when the bundle has
/// no attribution (flagged via [needsReview], never invented).

class AzkarCategory {
  const AzkarCategory({
    required this.key,
    required this.name,
    required this.icon,
  });

  /// Stable key, e.g. `morning`. Persisted in bookmarks/progress.
  final String key;

  /// Arabic display name, taken from the existing app strings.
  final String name;

  /// Material icon name hint for the UI (not persisted).
  final String icon;
}

class DhikrItem {
  const DhikrItem({
    required this.id,
    required this.categoryId,
    required this.arabicText,
    required this.repeatTotal,
    this.virtue = '',
    this.source,
    this.needsReview = true,
  });

  final String id;
  final String categoryId;
  final String arabicText;
  final int repeatTotal;

  /// The `bless` field from bundled content (virtue/reward note).
  final String virtue;
  final String? source;
  final bool needsReview;

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'arabicText': arabicText,
        'repeatTotal': repeatTotal,
        'virtue': virtue,
      };
}

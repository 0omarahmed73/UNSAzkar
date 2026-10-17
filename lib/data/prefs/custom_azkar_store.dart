import 'package:get_storage/get_storage.dart';

/// A user-created dhikr. Ids are namespaced `custom:<uuid>` so they can
/// never collide with bundled stable ids (`<category>:<index>`).
class CustomDhikr {
  const CustomDhikr({
    required this.id,
    required this.arabicText,
    required this.repeatTotal,
    this.virtue = '',
    this.categories = const ['custom'],
    this.sortOrder = 0,
  });

  final String id;
  final String arabicText;
  final int repeatTotal;
  final String virtue;

  /// Assigned built-in collections: subset of {morning, evening}.
  /// The personal shelf ('custom') always contains every custom dhikr.
  final List<String> categories;
  final int sortOrder;

  CustomDhikr copyWith({
    String? arabicText,
    int? repeatTotal,
    String? virtue,
    List<String>? categories,
    int? sortOrder,
  }) =>
      CustomDhikr(
        id: id,
        arabicText: arabicText ?? this.arabicText,
        repeatTotal: repeatTotal ?? this.repeatTotal,
        virtue: virtue ?? this.virtue,
        categories: categories ?? this.categories,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'arabicText': arabicText,
        'repeatTotal': repeatTotal,
        'virtue': virtue,
        'categories': List<String>.from(categories),
        'sortOrder': sortOrder,
      };

  factory CustomDhikr.fromJson(Map<String, dynamic> json) => CustomDhikr(
        id: json['id'] as String,
        arabicText: (json['arabicText'] ?? '').toString(),
        repeatTotal: (json['repeatTotal'] as num?)?.toInt() ?? 1,
        virtue: (json['virtue'] ?? '').toString(),
        categories: (json['categories'] as List?)
                ?.map((e) => e.toString())
                .where((c) => c == 'morning' || c == 'evening')
                .toList() ??
            const [],
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );
}

/// User customizations layer. Bundled content is NEVER rewritten here:
/// additions live under `v2.customAzkar` and the repository merges them
/// read-only at display time. Survives upgrades (new key, old data kept).
class CustomAzkarStore {
  CustomAzkarStore(this._box);

  final GetStorage _box;

  static const String keyCustomAzkar = 'v2.customAzkar';
  static const int maxRepeat = 1000;

  final List<CustomDhikr> _items = [];

  List<CustomDhikr> get customs {
    final sorted = List<CustomDhikr>.from(_items)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return List.unmodifiable(sorted);
  }

  Future<void> load() async {
    _items.clear();
    final raw = _box.read(keyCustomAzkar);
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          try {
            final item = CustomDhikr.fromJson(Map<String, dynamic>.from(e));
            if (item.arabicText.trim().isNotEmpty) {
              _items.add(item);
            }
          } catch (_) {
            // Skip one corrupt entry, keep the rest.
          }
        }
      }
    }
  }

  Future<void> _save() =>
      _box.write(keyCustomAzkar, _items.map((e) => e.toJson()).toList());

  int _nextOrder() => _items.isEmpty
      ? 0
      : _items.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

  /// Creates a custom dhikr. Returns null (nothing stored) on invalid
  /// input: blank text, repeat outside 1..1000, or no valid assignment.
  Future<CustomDhikr?> add({
    required String text,
    required int repeat,
    String virtue = '',
    required List<String> categories,
  }) async {
    final t = text.trim();
    final requested = categories
        .where((c) => c == 'morning' || c == 'evening' || c == 'custom')
        .toList();
    if (t.isEmpty || repeat < 1 || repeat > maxRepeat || requested.isEmpty) {
      return null;
    }
    // Only built-in assignments persist; the personal shelf is implicit.
    final cats =
        requested.where((c) => c == 'morning' || c == 'evening').toList();
    final item = CustomDhikr(
      id: 'custom:${DateTime.now().microsecondsSinceEpoch}-${_items.length}',
      arabicText: t,
      repeatTotal: repeat,
      virtue: virtue.trim(),
      categories: cats,
      sortOrder: _nextOrder(),
    );
    _items.add(item);
    await _save();
    return item;
  }

  /// Updates a custom dhikr. Returns false when missing or invalid.
  Future<bool> update(
    String id, {
    String? text,
    int? repeat,
    String? virtue,
    List<String>? categories,
  }) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return false;
    var next = _items[i];
    if (text != null) {
      if (text.trim().isEmpty) return false;
      next = next.copyWith(arabicText: text.trim());
    }
    if (repeat != null) {
      if (repeat < 1 || repeat > maxRepeat) return false;
      next = next.copyWith(repeatTotal: repeat);
    }
    if (virtue != null) next = next.copyWith(virtue: virtue.trim());
    if (categories != null) {
      final valid = categories
          .where((c) => c == 'morning' || c == 'evening' || c == 'custom')
          .toList();
      if (valid.isEmpty) return false;
      final cats =
          valid.where((c) => c == 'morning' || c == 'evening').toList();
      next = next.copyWith(categories: cats);
    }
    _items[i] = next;
    await _save();
    return true;
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _save();
  }

  /// Reorders the personal shelf; unknown ids are ignored.
  Future<void> reorder(List<String> idsInOrder) async {
    final byId = {for (final e in _items) e.id: e};
    var order = 0;
    for (final id in idsInOrder) {
      final item = byId.remove(id);
      if (item != null) {
        final idx = _items.indexOf(item);
        _items[idx] = item.copyWith(sortOrder: order++);
      }
    }
    for (final item in byId.values) {
      final idx = _items.indexOf(item);
      _items[idx] = item.copyWith(sortOrder: order++);
    }
    await _save();
  }

  /// Deletes all user customs. Bundled content is untouched by design.
  Future<void> restoreDefaults() async {
    _items.clear();
    await _box.remove(keyCustomAzkar);
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'items': _items.map((e) => e.toJson()).toList(),
      };

  /// Validates and imports. Returns an error string on failure (state
  /// untouched), null on success. Never throws.
  String? importJson(dynamic data) {
    try {
      if (data is! Map || data['version'] != 1) return 'unsupported backup';
      final raw = data['items'];
      if (raw is! List) return 'malformed backup';
      final parsed = <CustomDhikr>[];
      for (final e in raw) {
        if (e is! Map) return 'malformed backup';
        final item = CustomDhikr.fromJson(Map<String, dynamic>.from(e));
        if (item.arabicText.trim().isEmpty) return 'malformed backup';
        if (item.repeatTotal < 1 || item.repeatTotal > maxRepeat) {
          return 'malformed backup';
        }
        parsed.add(item);
      }
      _items
        ..clear()
        ..addAll(parsed);
      _save();
      return null;
    } catch (_) {
      return 'unreadable backup';
    }
  }
}

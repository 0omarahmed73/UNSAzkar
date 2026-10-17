import 'package:azkar_new_app/data/models/tasbeeh_session.dart';
import 'package:get_storage/get_storage.dart';

/// Mutable user data: per-item remaining counts, bookmarks, tasbeeh state,
/// last-open day. Keyed by stable dhikr ids — never list positions.
///
/// Migration: legacy `blesses` (ThankingAllahPage) is owned by its old
/// screen and left untouched; this store only reads it never. New keys are
/// namespaced `v2.*` so a fresh install and an upgrade never collide.
class ProgressStore {
  ProgressStore(this._box);

  final GetStorage _box;

  static const int exportVersion = 2;
  static const String keyRemaining = 'v2.remaining';
  static const String keyBookmarks = 'v2.bookmarks';
  static const String keyLastOpenDay = 'v2.lastOpenDay';
  static const String keyTasbeeh = 'v2.tasbeeh';
  static const String keyTasbeehHistory = 'v2.tasbeehHistory';

  Map<String, int> _remaining = {};
  Set<String> _bookmarks = {};
  TasbeehSession? activeTasbeeh;
  List<TasbeehSession> tasbeehHistory = [];

  List<String> get bookmarks => _bookmarks.toList()..sort();

  Future<void> load() async {
    final rawRem = _box.read(keyRemaining);
    if (rawRem is Map) {
      _remaining = rawRem
          .map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
    }
    final rawBm = _box.read(keyBookmarks);
    if (rawBm is List) _bookmarks = rawBm.map((e) => e.toString()).toSet();

    final rawT = _box.read(keyTasbeeh);
    if (rawT is Map<String, dynamic>) {
      activeTasbeeh = TasbeehSession.fromJson(Map<String, dynamic>.from(rawT));
    } else if (rawT is Map) {
      activeTasbeeh = TasbeehSession.fromJson(Map<String, dynamic>.from(rawT));
    }
    final rawH = _box.read(keyTasbeehHistory);
    if (rawH is List) {
      tasbeehHistory = rawH
          .whereType<Map>()
          .map((m) => TasbeehSession.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
  }

  Future<void> _saveRemaining() => _box.write(keyRemaining, _remaining);
  Future<void> _saveBookmarks() =>
      _box.write(keyBookmarks, _bookmarks.toList());

  /// Remaining repetitions for [itemId]; null means untouched (full count).
  int? remaining(String itemId) => _remaining[itemId];

  Future<void> setRemaining(String itemId, int value) async {
    _remaining[itemId] = value;
    await _saveRemaining();
  }

  Future<void> clearRemaining(String itemId) async {
    _remaining.remove(itemId);
    await _saveRemaining();
  }

  bool isBookmarked(String itemId) => _bookmarks.contains(itemId);

  Future<void> toggleBookmark(String itemId) async {
    if (!_bookmarks.remove(itemId)) _bookmarks.add(itemId);
    await _saveBookmarks();
  }

  Future<void> saveTasbeeh() async {
    final t = activeTasbeeh;
    if (t == null) {
      await _box.remove(keyTasbeeh);
    } else {
      await _box.write(keyTasbeeh, t.toJson());
    }
  }

  /// Archives the active session into history (called on confirmed reset or
  /// target change) and clears it.
  Future<void> archiveTasbeeh() async {
    final t = activeTasbeeh;
    if (t != null) {
      tasbeehHistory = [...tasbeehHistory, t];
      await _box.write(
          keyTasbeehHistory, tasbeehHistory.map((e) => e.toJson()).toList());
      activeTasbeeh = null;
      await _box.remove(keyTasbeeh);
    }
  }

  Map<String, dynamic> exportData() => {
        'version': exportVersion,
        'remaining': Map<String, int>.from(_remaining),
        'bookmarks': _bookmarks.toList(),
        'tasbeehHistory': tasbeehHistory.map((e) => e.toJson()).toList(),
      };

  /// Validates and imports an export map. Returns an error message on
  /// failure (state untouched), null on success. Never throws.
  String? importData(dynamic data) {
    try {
      if (data is! Map) return 'not a backup object';
      if (data['version'] != exportVersion) return 'unsupported version';
      final rem = data['remaining'];
      final bm = data['bookmarks'];
      if (rem is! Map || bm is! List) return 'malformed backup';
      final remParsed = <String, int>{};
      for (final e in rem.entries) {
        final v = e.value;
        if (v is! num) return 'malformed remaining counts';
        remParsed[e.key.toString()] = v.toInt();
      }
      final bmParsed = bm.map((e) => e.toString()).toSet();
      final histRaw = data['tasbeehHistory'];
      final hist = <TasbeehSession>[];
      if (histRaw is List) {
        for (final m in histRaw) {
          if (m is! Map) return 'malformed history';
          hist.add(TasbeehSession.fromJson(Map<String, dynamic>.from(m)));
        }
      }
      _remaining = remParsed;
      _bookmarks = bmParsed;
      tasbeehHistory = hist;
      _saveRemaining();
      _saveBookmarks();
      _box.write(keyTasbeehHistory, hist.map((e) => e.toJson()).toList());
      return null;
    } catch (_) {
      return 'unreadable backup';
    }
  }
}

import 'package:azkar_new_app/data/models/dhikr.dart';
import 'package:azkar_new_app/data/prefs/custom_azkar_store.dart';
import 'package:azkar_new_app/services/AllAzkar.dart';
import 'package:azkar_new_app/services/NightOrMorning.dart';

/// Read-only repository over the bundled content, merged with the user's
/// own customs (overlay — bundled lists are never rewritten).
///
/// Maps the legacy `List<Map>` bundles to id-stable [DhikrItem]s without
/// editing a single Arabic string. No persistence here — that is the stores'
/// job.
class AzkarRepository {
  AzkarRepository(
      {AllAzkar? all, NightOrMorning? dayNight, CustomAzkarStore? customs})
      : _all = all ?? AllAzkar(),
        _dayNight = dayNight ?? NightOrMorning(),
        _customs = customs;

  final AllAzkar _all;
  final NightOrMorning _dayNight;
  final CustomAzkarStore? _customs;

  static const List<AzkarCategory> _categories = [
    AzkarCategory(key: 'morning', name: 'أذكار الصباح', icon: 'sunny'),
    AzkarCategory(key: 'evening', name: 'أذكار المساء', icon: 'nightlight'),
    AzkarCategory(key: 'sleep', name: 'أذكار النوم', icon: 'bed'),
    AzkarCategory(
        key: 'wakeup', name: 'أذكار الاستيقاظ من النوم', icon: 'wakeup'),
    AzkarCategory(key: 'wodu', name: 'أذكار الوضوء', icon: 'water'),
    AzkarCategory(
        key: 'mosque', name: 'أذكار الذهاب الى المسجد', icon: 'mosque'),
    AzkarCategory(key: 'azan', name: 'أذكار الأذان', icon: 'volume'),
    AzkarCategory(key: 'afterPrayer', name: 'أذكار بعد الصلاة', icon: 'prayer'),
    AzkarCategory(key: 'friday', name: 'سنن الجمعة', icon: 'people'),
    AzkarCategory(key: 'quranDuaa', name: 'أدعية قرآنية', icon: 'book'),
    AzkarCategory(key: 'sunaaDuaa', name: 'أدعية نبوية', icon: 'people'),
    AzkarCategory(key: 'custom', name: 'أذكاري المخصصة', icon: 'edit_note'),
  ];

  List<AzkarCategory> categories() => List.unmodifiable(_categories);

  List<DhikrItem> items(String categoryKey) {
    final raw = _rawFor(categoryKey);
    final bundled = List.generate(raw.length, (i) {
      final m = raw[i];
      return DhikrItem(
        id: '$categoryKey:${i.toString().padLeft(2, '0')}',
        categoryId: categoryKey,
        arabicText: (m['zekr'] ?? '').toString(),
        repeatTotal: _asInt(m['repeat'], 1),
        virtue: (m['bless'] ?? '').toString(),
        source: null,
        needsReview: true,
      );
    });
    // User customs assigned here (or every custom on the personal shelf).
    final customs = _customs?.customs.where(
        (c) => categoryKey == 'custom' || c.categories.contains(categoryKey));
    if (customs == null || customs.isEmpty) return bundled;
    return [
      ...bundled,
      ...customs.map((c) => DhikrItem(
            id: c.id,
            categoryId: categoryKey,
            arabicText: c.arabicText,
            repeatTotal: c.repeatTotal,
            virtue: c.virtue,
            source: null,
            needsReview: true,
          )),
    ];
  }

  List<DhikrItem> allItems() =>
      _categories.expand((c) => items(c.key)).toList();

  /// Finds one item by stable id (`<categoryKey>:<index>` or
  /// `custom:<uuid>`), or null.
  DhikrItem? byId(String id) {
    if (id.startsWith('custom:')) {
      final customs = _customs?.customs;
      if (customs == null) return null;
      for (final c in customs) {
        if (c.id == id) {
          return DhikrItem(
            id: c.id,
            categoryId: 'custom',
            arabicText: c.arabicText,
            repeatTotal: c.repeatTotal,
            virtue: c.virtue,
            source: null,
            needsReview: true,
          );
        }
      }
      return null;
    }
    final sep = id.lastIndexOf(':');
    if (sep < 0) return null;
    final key = id.substring(0, sep);
    final idx = int.tryParse(id.substring(sep + 1));
    if (idx == null) return null;
    final list = items(key);
    if (idx < 0 || idx >= list.length) return null;
    return list[idx];
  }

  String categoryName(String key) => _categories
      .firstWhere((c) => c.key == key,
          orElse: () => const AzkarCategory(key: '', name: '', icon: ''))
      .name;

  List<Map> _rawFor(String key) {
    switch (key) {
      case 'morning':
        return _dayNight.morning;
      case 'evening':
        return _dayNight.night;
      case 'sleep':
        return _all.sleep;
      case 'wakeup':
        return _all.wakeup;
      case 'wodu':
        return _all.wodu;
      case 'mosque':
        return _all.mosque;
      case 'azan':
        return _all.azan;
      case 'afterPrayer':
        return _all.afterPrayZekrList;
      case 'friday':
        return _all.gomaaSunn;
      case 'quranDuaa':
        return _all.quranDuaa;
      case 'sunaaDuaa':
        return _all.sunaaDuaa;
      default:
        return const [];
    }
  }

  static int _asInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }
}

import 'dart:async';

import 'package:azkar_new_app/components/zikr_item.dart';
import 'package:azkar_new_app/data/models/dhikr.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/data/repositories/azkar_repository.dart';
import 'package:azkar_new_app/design/components.dart';
import 'package:azkar_new_app/pages/CustomAzkarPage.dart';
import 'package:azkar_new_app/services/copy_to_clipboard.dart';
import 'package:azkar_new_app/services/haptics_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Maps the legacy navigation argument (Arabic category name, as passed by
/// the v1 home screen) to a repository category key.
String? categoryKeyForType(String? type) {
  switch (type) {
    case 'أذكار الصباح':
      return 'morning';
    case 'أذكار المساء':
      return 'evening';
    case 'أذكار النوم':
      return 'sleep';
    case 'أذكار الاستيقاظ من النوم':
      return 'wakeup';
    case 'أذكار الوضوء':
      return 'wodu';
    case 'أذكار الذهاب الى المسجد':
      return 'mosque';
    case 'أذكار الأذان':
      return 'azan';
    case 'سنن الجمعة':
      return 'friday';
    case 'أذكار بعد الصلاة':
      return 'afterPrayer';
    case 'أدعية قرآنية':
      return 'quranDuaa';
    case 'أدعية نبوية':
      return 'sunaaDuaa';
    case 'أذكاري المخصصة':
      return 'custom';
    default:
      return null;
  }
}

class AzkarPage extends StatefulWidget {
  AzkarPage({super.key});
  static String id = 'AzkarPage';

  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage> {
  bool _loaded = false;
  String? _categoryKey;
  String _categoryName = '';
  List<DhikrItem> _items = [];
  final Map<String, int> _remaining = {};
  bool _bookmarksOnly = false;

  /// Items playing their completion fade-out: still mounted (opacity → 0)
  /// but already counted done, so layout collapses smoothly.
  final Set<String> _fadingOut = {};

  AzkarRepository get _repo => Get.find<AzkarRepository>();
  ProgressStore get _progress => Get.find<ProgressStore>();
  SettingsStore get _settings => Get.find<SettingsStore>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    _categoryKey = categoryKeyForType(args is String ? args : null);
    if (_categoryKey == null) {
      setState(() {});
      return;
    }
    _categoryName =
        _repo.categories().firstWhere((c) => c.key == _categoryKey).name;
    _items = _repo.items(_categoryKey!);
    for (final it in _items) {
      _remaining[it.id] = _progress.remaining(it.id) ?? it.repeatTotal;
    }
    setState(() {});
  }

  int _rem(DhikrItem it) => _remaining[it.id] ?? it.repeatTotal;
  bool get _allDone =>
      _items.isNotEmpty &&
      _items.every((it) => _rem(it) <= 0) &&
      _fadingOut.isEmpty;
  int get _doneCount => _items.where((it) => _rem(it) <= 0).length;

  bool _visible(DhikrItem it) => _rem(it) > 0 || _fadingOut.contains(it.id);
  bool _fading(DhikrItem it) => _rem(it) <= 0 && _fadingOut.contains(it.id);

  Future<void> _onTap(DhikrItem it) async {
    final rem = _rem(it);
    if (rem <= 0 || _fadingOut.contains(it.id)) return;
    if (_settings.haptics) {
      unawaited(HapticsService.instance.lightImpact().catchError((_) {
        // Unsupported device/channel — counting must not fail.
      }));
    }
    // UI updates synchronously first — the counter never waits for disk.
    final reduced = MediaQuery.disableAnimationsOf(context);
    setState(() {
      _remaining[it.id] = rem - 1;
      if (rem - 1 <= 0 && !reduced) _fadingOut.add(it.id);
    });
    await _progress.setRemaining(it.id, rem - 1);
    if (rem - 1 <= 0 && !reduced && mounted) {
      // Let the fade-out finish before unmounting the card.
      await Future.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;
      setState(() => _fadingOut.remove(it.id));
    }
  }

  Future<void> _onBookmark(DhikrItem it) async {
    await _progress.toggleBookmark(it.id);
    setState(() {});
  }

  void _onCopy(DhikrItem it) {
    CopyService().copyToClipboardService(
      Theme.of(context).colorScheme.onSurface,
      it.arabicText,
    );
  }

  Future<void> _resetAll() async {
    for (final it in _items) {
      await _progress.clearRemaining(it.id);
      _remaining[it.id] = it.repeatTotal;
    }
    _fadingOut.clear();
    setState(() {});
  }

  Future<void> _changeTextScale(double delta) async {
    final next = (_settings.textScale + delta).clamp(0.8, 1.6).toDouble();
    await _settings.setTextScale(next);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _categoryKey == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الأذكار')),
        body: AppEmptyState(
          icon: Icons.menu_book_outlined,
          title: 'اختر فئة من الأذكار',
          subtitle: 'افتح تبويب الأذكار ثم اختر الفئة التي تريد قراءتها.',
          actionLabel: 'رجوع',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final visible = _bookmarksOnly
        ? _items.where((it) => _progress.isBookmarked(it.id)).toList()
        : _items;
    final visibleItems = [
      for (final it in visible)
        if (_visible(it)) it
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_categoryName),
        centerTitle: true,
        actions: [
          if (_categoryKey == 'custom')
            IconButton(
              tooltip: 'إدارة الأذكار',
              onPressed: () async {
                await Navigator.pushNamed(context, CustomAzkarPage.id);
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.edit_note_outlined),
            ),
          IconButton(
            tooltip: 'تكبير الخط',
            onPressed: () => _changeTextScale(0.1),
            icon: const Icon(Icons.text_increase),
          ),
          IconButton(
            tooltip: 'تصغير الخط',
            onPressed: () => _changeTextScale(-0.1),
            icon: const Icon(Icons.text_decrease),
          ),
          IconButton(
            tooltip: _bookmarksOnly ? 'عرض الكل' : 'المحفوظات فقط',
            onPressed: () => setState(() => _bookmarksOnly = !_bookmarksOnly),
            icon: Icon(
              _bookmarksOnly ? Icons.bookmark : Icons.bookmark_border,
            ),
          ),
        ],
      ),
      body: _allDone
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 72),
                    const SizedBox(height: 16),
                    const Text(
                      'تم الانتهاء بنجاح , جزاكم الله خيراً',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GoldButton(label: 'إعادة من جديد', onTap: _resetAll),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: pageInsets(context),
              itemCount: 1 + (visibleItems.isEmpty ? 1 : visibleItems.length),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Text(
                            '$_doneCount / ${_items.length}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: _items.isEmpty
                                    ? 0
                                    : _doneCount / _items.length,
                                minHeight: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (visibleItems.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.bookmark_border,
                    title: 'لا توجد عناصر محفوظة هنا',
                    subtitle: 'اضغط على علامة الحفظ في أي ذكر لإضافته.',
                  );
                }

                final it = visibleItems[index - 1];
                return AnimatedOpacity(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  opacity: _fading(it) ? 0.0 : 1.0,
                  child: ZikrItem(
                    text: it.arabicText,
                    remaining: _rem(it),
                    total: it.repeatTotal,
                    bookmarked: _progress.isBookmarked(it.id),
                    textScale: _settings.textScale,
                    virtue: it.virtue,
                    onTap: () => _onTap(it),
                    onBookmark: () => _onBookmark(it),
                    onCopy: () => _onCopy(it),
                  ),
                );
              },
            ),
    );
  }
}

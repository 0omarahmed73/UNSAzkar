import 'dart:async';

import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/notifications/reminder_service.dart';
import 'package:azkar_new_app/data/prayer/prayer_service.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/data/repositories/azkar_repository.dart';
import 'package:azkar_new_app/pages/PrayerTimesPage.dart';
import 'package:azkar_new_app/design/components.dart';
import 'package:azkar_new_app/design/quran_text.dart';
import 'package:azkar_new_app/design/tokens.dart';
import 'package:azkar_new_app/pages/AzkarPage.dart';
import 'package:azkar_new_app/pages/AzkarCategoriesPage.dart'; // Import AzkarCategoriesPage
import 'package:azkar_new_app/pages/PrayersPage.dart'; // Import PrayersPage
import 'package:azkar_new_app/pages/SettingsPage.dart';
import 'package:azkar_new_app/pages/TasbeehRingPage.dart';
import 'package:azkar_new_app/services/get_random_hadith.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran/quran.dart';

class HomePage extends StatefulWidget {
  static String id = 'HomePage';
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Controller is registered once in main() before first frame.

  // Variable to track which page is currently displayed
  // Tabs run right→left: الرئيسية، الأذكار، الدعاء، عنا.
  int currentPageIndex = 0; // Default to HomeScreen

  void setPageIndex(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget body;
    switch (currentPageIndex) {
      case 0:
        body = HomeScreen(setPageIndex: setPageIndex);
        break;
      case 1:
        body = AzkarCategoriesPage();
        break;
      case 3:
        body = PrayersPage();
        break;
      default:
        body = HomeScreen(setPageIndex: setPageIndex);
    }

    return Scaffold(
      appBar: AppBar(
        // RTL: first child renders at the right → title right, actions left.
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('أُنس'),
            Row(
              children: [
                const _ThemeModeButton(),
                IconButton(
                  tooltip: 'الإعدادات',
                  onPressed: () =>
                      Navigator.pushNamed(context, SettingsPage.id),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensure icons are always visible
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'الأذكار'),
          BottomNavigationBarItem(
            icon: Icon(Icons.touch_app_outlined),
            label: 'السبحة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_library_outlined),
            label: 'المكتبة',
          ),
        ],
        currentIndex: currentPageIndex,
        selectedItemColor: scheme.primary,
        onTap: (index) {
          // السبحة opens the counter full-screen (it keeps its own scaffold)
          // and leaves the current tab selected.
          if (index == 2) {
            Navigator.pushNamed(context, TasbeehRingPage.id);
            return;
          }
          setState(() {
            currentPageIndex = index;
          });
        },
      ),
    );
  }
}

/// App-bar button cycling light → dark → amoled → system.
class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton();

  @override
  Widget build(BuildContext context) {
    final Controller controller = Get.find<Controller>();
    return Obx(() {
      final mode = controller.mode.value;
      return IconButton(
        tooltip: 'تبديل المظهر',
        onPressed: controller.cycleMode,
        icon: Icon(
          mode == 'light'
              ? Icons.sunny
              : mode == 'dark'
                  ? Icons.nights_stay
                  : mode == 'amoled'
                      ? Icons.dark_mode
                      : Icons.brightness_auto,
        ),
      );
    });
  }
}

class HomeScreen extends StatefulWidget {
  final Function(int) setPageIndex;

  HomeScreen({required this.setPageIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AzkarRepository get _repo => Get.find<AzkarRepository>();
  ProgressStore get _progress => Get.find<ProgressStore>();
  SettingsStore get _settings => Get.find<SettingsStore>();

  // Picked once per screen instance. Previously these were recomputed in
  // build(), so every rebuild (tab switch, progress change, theme toggle)
  // re-parsed the hadith dataset on the UI thread -> janky transitions.
  late final RandomVerse _verse = RandomVerse();
  String? _hadith;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePromptNotifications();
      // Load after the first frame so route/tab transitions never wait on it.
      if (mounted) setState(() => _hadith = getRandomHadith());
    });
  }

  /// One-time first-launch explanation for daily reminders. Shown at most
  /// once ever; never nags. If the notification plugin is unavailable the
  /// dialog still explains and dismisses gracefully without enabling.
  Future<void> _maybePromptNotifications() async {
    if (!mounted) return;
    if (_settings.notifPromptShown) return;
    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تفعيل التذكير اليومي؟',
          textDirection: TextDirection.rtl,
        ),
        content: const Text(
          'يمكن للتطبيق تذكيرك بأذكار الصباح والمساء في الأوقات التي تختارها من الإعدادات. يمكنك تغيير ذلك في أي وقت.',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('لاحقًا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تفعيل'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    await _settings.setNotifPromptShown(true);
    if (enable != true) return;
    final svc = ReminderService.current;
    if (svc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'التنبيهات غير متاحة على هذا الجهاز.',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
      return;
    }
    final ok = await svc.requestPermission();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر الحصول على إذن التنبيهات — فعّله من إعدادات النظام.',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
      return;
    }
    if (_settings.reminderMorning == null) {
      await _settings.setReminderMorning('07:00');
    }
    if (_settings.reminderEvening == null) {
      await _settings.setReminderEvening('19:00');
    }
    await _settings.setRemindersEnabled(true);
    await svc.syncFromSettings(_settings);
  }

  /// Greeting, personalized when the user saved a display name.
  String get _greetingTitle {
    final name = _settings.userName;
    if (name == null || name.isEmpty) return _greeting;
    return '$_greeting، $name';
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) return 'صباح الخير';
    if (hour >= 12 && hour < 17) return 'طاب يومك';
    if (hour >= 17 && hour < 22) return 'مساء الخير';
    return 'ليلة طيبة';
  }

  /// Morning + evening routine progress from persisted remaining counts.
  ({int done, int total}) _routineProgress() {
    var done = 0, total = 0;
    for (final key in ['morning', 'evening']) {
      for (final it in _repo.items(key)) {
        total++;
        if ((_progress.remaining(it.id) ?? it.repeatTotal) <= 0) done++;
      }
    }
    return (done: done, total: total);
  }

  void _openCategory(String name) {
    Navigator.pushNamed(context, AzkarPage.id, arguments: name);
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    final isMorning = now.hour >= 4 && now.hour <= 16;
    String arguments = isMorning ? 'أذكار الصباح' : 'أذكار المساء';
    final routine = _routineProgress();
    final bookmarks = _progress.bookmarks.take(3).toList();

    return ListView(
      padding: pageInsets(context),
      children: [
        BrandFade(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs, AppSpacing.sm, AppSpacing.xs, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _greetingTitle,
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'السلام عليكم ورحمة الله وبركاته',
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                _RoutineRing(done: routine.done, total: routine.total),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ورد اليوم',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        arguments,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      GoldButton(
                        label:
                            routine.done == 0 ? 'ابدأ القراءة' : 'أكمل القراءة',
                        onTap: () => _openCategory(arguments),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _HomePrayerCard(),
        const AppSectionHeader(title: 'وصول سريع'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.6,
          children: [
            HomeShortcut(
              label: 'أذكار الصباح',
              icon: Icons.sunny,
              onTap: () => _openCategory('أذكار الصباح'),
            ),
            HomeShortcut(
              label: 'أذكار المساء',
              icon: Icons.nightlight,
              onTap: () => _openCategory('أذكار المساء'),
            ),
            HomeShortcut(
              label: 'أذكار النوم',
              icon: Icons.bed,
              onTap: () => _openCategory('أذكار النوم'),
            ),
            HomeShortcut(
              label: 'خاتم التسبيح',
              icon: Icons.touch_app_outlined,
              onTap: () => Navigator.pushNamed(context, TasbeehRingPage.id),
            ),
          ],
        ),
        if (bookmarks.isNotEmpty) ...[
          AppSectionHeader(
            title: 'تابع القراءة',
            action: TextButton(
              onPressed: () => widget.setPageIndex(1),
              child: const Text('كل الأذكار'),
            ),
          ),
          for (final id in bookmarks)
            Card(
              child: ListTile(
                trailing: const Icon(Icons.bookmark, size: 20),
                title: Text(
                  _repo.byId(id)?.arabicText ?? id,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _repo.byId(id) == null
                      ? ''
                      : _repo.categoryName(_repo.byId(id)!.categoryId),
                ),
                onTap: () => _openCategory(
                  _repo.byId(id) == null
                      ? 'أذكار الصباح'
                      : _repo.categoryName(_repo.byId(id)!.categoryId),
                ),
              ),
            ),
        ],
        const AppSectionHeader(title: 'آية اليوم'),
        _VerseCard(verse: _verse),
        const AppSectionHeader(title: 'حديث اليوم'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              (_hadith ?? '').replaceAll('<p>', '').replaceAll('</p>', ''),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.9),
            ),
          ),
        ),
      ],
    );
  }
}

/// Daily verse card: bundled offline text (package:quran, Uthmani
/// orthography preserved verbatim) with surah attribution and the
/// package-provided end-of-verse marker. No network, no modification.
class _VerseCard extends StatelessWidget {
  const _VerseCard({required this.verse});

  final RandomVerse verse;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سورة ${getSurahNameArabic(verse.surahNumber)}',
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  'آية ${verse.verseNumber}',
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            QuranText(
              '${verse.verse} ${getVerseEndSymbol(verse.verseNumber)}',
              fontSize: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact next-prayer card for the dashboard. Owns a 30s ticker so the
/// countdown never rebuilds the home screen. Without a saved location it
/// shows a setup CTA instead of fabricated times.
class _HomePrayerCard extends StatefulWidget {
  const _HomePrayerCard();

  @override
  State<_HomePrayerCard> createState() => _HomePrayerCardState();
}

class _HomePrayerCardState extends State<_HomePrayerCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsStore>();
    final scheme = Theme.of(context).colorScheme;
    final lat = settings.prayerLat;
    final lng = settings.prayerLng;

    return Card(
      color: scheme.primary,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () => Navigator.pushNamed(context, PrayerTimesPage.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: lat == null || lng == null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'حدد موقعك لعرض مواقيت الصلاة',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.location_on_outlined, color: scheme.onPrimary),
                  ],
                )
              : Builder(
                  builder: (context) {
                    final now = DateTime.now();
                    final day = DateTime(now.year, now.month, now.day);
                    DailyPrayers today;
                    DailyPrayers tomorrow;
                    try {
                      today = PrayerService.calculate(
                        lat: lat,
                        lng: lng,
                        date: day,
                        method: settings.method,
                        madhab: settings.madhab,
                      );
                      tomorrow = PrayerService.calculate(
                        lat: lat,
                        lng: lng,
                        date: day.add(const Duration(days: 1)),
                        method: settings.method,
                        madhab: settings.madhab,
                      );
                    } catch (_) {
                      return Text(
                        'تعذر حساب المواقيت',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(color: scheme.onPrimary),
                      );
                    }
                    final next = PrayerService.nextPrayer(today, tomorrow, now);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الصلاة القادمة: ${next.kind.arabic}',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              PrayerService.formatCountdown(next.countdown),
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                color: scheme.onPrimary.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatPrayerTime(next.at),
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              Icons.mosque_outlined,
                              color: scheme.onPrimary,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// Circular routine progress with the percentage in the middle.
class _RoutineRing extends StatelessWidget {
  const _RoutineRing({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : done / total;
    return Semantics(
      label: 'تقدم الورد اليومي $done من $total',
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.outlineVariant,
              ),
            ),
            ExcludeSemantics(
              child: Text(
                '${(value * 100).round()}٪',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

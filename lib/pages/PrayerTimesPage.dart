import 'dart:async';

import 'package:azkar_new_app/data/notifications/reminder_service.dart';
import 'package:azkar_new_app/data/prayer/location_service.dart';
import 'package:azkar_new_app/pages/MapPickerPage.dart';
import 'package:azkar_new_app/data/prayer/prayer_service.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/design/components.dart';
import 'package:azkar_new_app/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

const List<String> _weekdays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

const List<String> _months = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String arabicDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}، ${d.day} ${_months[d.month - 1]} ${d.year}';

String formatPrayerTime(DateTime t) {
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final mm = t.minute.toString().padLeft(2, '0');
  final period = t.hour < 12 ? 'ص' : 'م';
  return '$h12:$mm $period';
}

const Map<PrayerKind, IconData> _prayerIcons = {
  PrayerKind.fajr: Icons.dark_mode,
  PrayerKind.sunrise: Icons.wb_twilight,
  PrayerKind.dhuhr: Icons.light_mode,
  PrayerKind.asr: Icons.wb_sunny,
  PrayerKind.maghrib: Icons.brightness_4,
  PrayerKind.isha: Icons.nights_stay,
};

class PrayerTimesPage extends StatefulWidget {
  static String id = 'PrayerTimesPage';
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  SettingsStore get _settings => Get.find<SettingsStore>();
  ReminderService? get _reminders => ReminderService.current;
  final LocationService _location = LocationService();

  DailyPrayers? _today;
  DailyPrayers? _tomorrow;
  String? _error;
  bool _locating = false;
  String? _locationNote;

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  Future<void> _recalculate() async {
    final lat = _settings.prayerLat;
    final lng = _settings.prayerLng;
    if (lat == null || lng == null) {
      setState(() {
        _today = null;
        _tomorrow = null;
        _error = null;
      });
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    try {
      final t = PrayerService.calculate(
        lat: lat,
        lng: lng,
        date: today,
        method: _settings.method,
        madhab: _settings.madhab,
      );
      final tm = PrayerService.calculate(
        lat: lat,
        lng: lng,
        date: today.add(const Duration(days: 1)),
        method: _settings.method,
        madhab: _settings.madhab,
      );
      if (!mounted) return;
      setState(() {
        _today = t;
        _tomorrow = tm;
        _error = null;
        _locationNote = null;
      });
      await _syncPrayerReminders();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _today = null;
        _tomorrow = null;
        _error =
            'تعذر حساب المواقيت لهذا الموقع. تحقق من الإحداثيات وحاول مجددًا.';
      });
    }
  }

  /// Recomputes notification jobs from current settings and replaces them.
  /// Called after every location/method/madhab/reminder change and on page
  /// open, since times shift daily.
  Future<void> _syncPrayerReminders() async {
    final svc = _reminders;
    final today = _today;
    final tomorrow = _tomorrow;
    if (svc == null || today == null || tomorrow == null) return;
    final jobs = PrayerService.prayerJobs(
      today: today,
      tomorrow: tomorrow,
      now: DateTime.now(),
      enabled: _settings.prayerReminders,
    );
    await svc.syncPrayerReminders(jobs);
  }

  Future<void> _useDeviceLocation() async {
    setState(() {
      _locating = true;
      _locationNote = null;
    });
    final (status, pos) = await _location.requestDeviceLocation();
    if (!mounted) return;
    if (status == LocationStatus.granted && pos != null) {
      await _settings.setPrayerLocation(pos.lat, pos.lng, pos.label);
      setState(() => _locating = false);
      await _recalculate();
    } else {
      setState(() {
        _locating = false;
        _locationNote = status.arabic;
      });
    }
  }

  Future<void> _pickOnMap() async {
    final current = _settings.prayerLat != null && _settings.prayerLng != null
        ? LatLng(_settings.prayerLat!, _settings.prayerLng!)
        : const LatLng(30.0444, 31.2357); // map view only, never saved as-is
    LatLng? picked;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initial: current,
          onConfirm: (p) => picked = p,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    String label = 'موقع مخصص';
    final resolved =
        await _location.describe(picked!.latitude, picked!.longitude);
    if (resolved != null) label = resolved;
    await _settings.setPrayerLocation(
        picked!.latitude, picked!.longitude, label);
    await _recalculate();
    if (mounted) setState(() {});
  }

  /// Single entry point for changing location AFTER onboarding too:
  /// GPS + interactive map + manual city list, then save + recalc + resync.
  Future<void> _openLocationSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: pageInsets(context),
          children: [
            ListTile(
              title: const Text('موقعي الحالي (GPS)',
                  textDirection: TextDirection.rtl),
              subtitle: _locating
                  ? const Text('جارٍ تحديد الموقع…',
                      textDirection: TextDirection.rtl)
                  : const Text('استخدام موقع الجهاز الحالي',
                      textDirection: TextDirection.rtl),
              leading: _locating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_outlined),
              onTap: _locating
                  ? null
                  : () async {
                      Navigator.of(ctx).pop();
                      await _useDeviceLocation();
                    },
            ),
            ListTile(
              title: const Text('من الخريطة', textDirection: TextDirection.rtl),
              subtitle: const Text('اختر أي مكان على الخريطة',
                  textDirection: TextDirection.rtl),
              leading: const Icon(Icons.map_outlined),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _pickOnMap();
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: Text('أو اختر مدينة',
                  textDirection: TextDirection.rtl,
                  style: Theme.of(ctx).textTheme.titleSmall),
            ),
            for (final c in manualCities)
              ListTile(
                title: Text(c.label, textDirection: TextDirection.rtl),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _settings.setPrayerLocation(c.lat, c.lng, c.label);
                  await _recalculate();
                },
              ),
            if (_locationNote != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(_locationNote!,
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<PrayerCity>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (_, scroll) => ListView.builder(
          controller: scroll,
          itemCount: manualCities.length,
          itemBuilder: (_, i) {
            final c = manualCities[i];
            return ListTile(
              title: Text(c.label, textDirection: TextDirection.rtl),
              onTap: () => Navigator.of(ctx).pop(c),
            );
          },
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await _settings.setPrayerLocation(picked.lat, picked.lng, picked.label);
    await _recalculate();
  }

  Future<void> _changeMethod(PrayerMethod? m) async {
    if (m == null) return;
    await _settings.setPrayerMethod(m);
    await _recalculate();
  }

  Future<void> _changeMadhab(PrayerMadhab? m) async {
    if (m == null) return;
    await _settings.setPrayerMadhab(m);
    await _recalculate();
  }

  Future<void> _togglePrayerReminder(PrayerKind kind, bool on) async {
    if (on && _reminders == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('التنبيهات غير متاحة على هذا الجهاز.',
                textDirection: TextDirection.rtl)));
      }
      return;
    }
    if (on) {
      final ok = await _reminders!.requestPermission();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('فعّل إذن التنبيهات من إعدادات النظام أولاً.',
                textDirection: TextDirection.rtl)));
        return;
      }
    }
    await _settings.setPrayerReminder(kind, on);
    await _syncPrayerReminders();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final today = _today;
    final tomorrow = _tomorrow;
    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'إعادة الحساب',
            onPressed: _recalculate,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: pageInsets(context),
        children: [
          if (_error != null)
            AppEmptyState(
              icon: Icons.error_outline,
              title: 'تعذر الحساب',
              subtitle: _error!,
              actionLabel: 'إعادة المحاولة',
              onAction: _recalculate,
            )
          else if (today == null || tomorrow == null) ...[
            AppEmptyState(
              icon: Icons.location_on_outlined,
              title: 'اختر موقعك أولاً',
              subtitle:
                  'نستخدم موقعك لحساب المواقيت دون إنترنت. يمكنك أيضًا اختيار مدينة يدويًا.',
              actionLabel: 'استخدام موقع الجهاز',
              onAction: _locating ? null : _useDeviceLocation,
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickCity,
                    icon: const Icon(Icons.list_outlined),
                    label: const Text('من قائمة المدن'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickOnMap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('من الخريطة'),
                  ),
                ),
              ],
            ),
            if (_locating)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_locationNote != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(_locationNote!,
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ] else ...[
            _NextPrayerHero(
              today: today,
              tomorrow: tomorrow,
              city: _settings.prayerCityLabel,
              onTapChange: _openLocationSheet,
            ),
            const AppSectionHeader(title: 'مواعيد اليوم'),
            for (final kind in PrayerKind.values)
              _PrayerRow(
                kind: kind,
                time: today.times[kind]!,
                isNext:
                    PrayerService.nextPrayer(today, tomorrow, DateTime.now())
                            .kind ==
                        kind,
                reminderOn: _settings.prayerReminder(kind),
                remindersAvailable: _reminders != null,
                onReminderChanged: (v) => _togglePrayerReminder(kind, v),
              ),
            const AppSectionHeader(title: 'طريقة الحساب'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    DropdownButtonFormField<PrayerMethod>(
                      initialValue: _settings.method,
                      decoration: const InputDecoration(
                          labelText: 'الطريقة', border: InputBorder.none),
                      items: [
                        for (final m in PrayerMethod.values)
                          DropdownMenuItem(value: m, child: Text(m.arabic)),
                      ],
                      onChanged: _changeMethod,
                    ),
                    DropdownButtonFormField<PrayerMadhab>(
                      initialValue: _settings.madhab,
                      decoration: const InputDecoration(
                          labelText: 'حساب العصر', border: InputBorder.none),
                      items: [
                        for (final m in PrayerMadhab.values)
                          DropdownMenuItem(value: m, child: Text(m.arabic)),
                      ],
                      onChanged: _changeMadhab,
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: Text(_settings.prayerCityLabel ?? 'بدون موقع',
                    textDirection: TextDirection.rtl),
                subtitle: const Text('الموقع المستخدم للحساب',
                    textDirection: TextDirection.rtl),
                trailing: const Icon(Icons.edit_location_outlined),
                onTap: _openLocationSheet,
              ),
            ),
            if (_locationNote != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(_locationNote!,
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Text(
                'الحساب محلي ودقيق حسب الطريقة المختارة. التنبيهات استرشادية وقد تتأخر بسبب توفير البطارية.',
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Next-prayer hero with a live countdown that rebuilds only itself.
class _NextPrayerHero extends StatelessWidget {
  const _NextPrayerHero(
      {required this.today,
      required this.tomorrow,
      required this.city,
      required this.onTapChange});

  final DailyPrayers today;
  final DailyPrayers tomorrow;
  final String? city;
  final VoidCallback onTapChange;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final next = PrayerService.nextPrayer(today, tomorrow, DateTime.now());
    return Card(
      color: scheme.primary,
      child: BrandFade(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: onTapChange,
                      icon: Icon(Icons.location_on_outlined,
                          size: 18, color: scheme.onPrimary),
                      label: Text(city ?? 'اختر الموقع',
                          style: TextStyle(color: scheme.onPrimary)),
                    ),
                    Text(
                      arabicDate(DateTime.now()),
                      textDirection: TextDirection.rtl,
                      style: TextStyle(color: scheme.onPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'الصلاة القادمة: ${next.kind.arabic}',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: scheme.onPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formatPrayerTime(next.at),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _LiveCountdown(target: next.at),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Countdown text with its own 30s ticker — the screen never rebuilds
/// wholesale for the clock.
class _LiveCountdown extends StatefulWidget {
  const _LiveCountdown({required this.target});

  final DateTime target;

  @override
  State<_LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<_LiveCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer =
        Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant _LiveCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remaining = widget.target.difference(DateTime.now());
    return Text(
      PrayerService.formatCountdown(
          remaining.isNegative ? Duration.zero : remaining),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(color: scheme.onPrimary),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.kind,
    required this.time,
    required this.isNext,
    required this.reminderOn,
    required this.remindersAvailable,
    required this.onReminderChanged,
  });

  final PrayerKind kind;
  final DateTime time;
  final bool isNext;
  final bool reminderOn;
  final bool remindersAvailable;
  final ValueChanged<bool> onReminderChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: isNext
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
              side: BorderSide(color: scheme.primary, width: 2),
            )
          : null,
      child: ListTile(
        leading: Icon(_prayerIcons[kind],
            color: isNext ? scheme.primary : scheme.onSurfaceVariant),
        title: Text(kind.arabic,
            textDirection: TextDirection.rtl,
            style: TextStyle(
                fontWeight: isNext ? FontWeight.bold : FontWeight.normal)),
        subtitle: isNext
            ? const Text('القادمة', textDirection: TextDirection.rtl)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatPrayerTime(time),
              style:
                  const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
            ),
            if (remindersAvailable)
              IconButton(
                tooltip: reminderOn
                    ? 'إيقاف تذكير ${kind.arabic}'
                    : 'تذكير ${kind.arabic}',
                icon: Icon(reminderOn
                    ? Icons.notifications_active
                    : Icons.notifications_none_outlined),
                onPressed: () => onReminderChanged(!reminderOn),
              ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/backup_service.dart';
import 'package:azkar_new_app/data/notifications/reminder_service.dart';
import 'package:azkar_new_app/data/prefs/custom_azkar_store.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/design/components.dart';
import 'package:azkar_new_app/design/tokens.dart';
import 'package:azkar_new_app/pages/AboutUsPage.dart';
import 'package:azkar_new_app/pages/PrayerTimesPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

String _fmt(int h, int m) =>
    '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

TimeOfDay? _parseTime(String? hhmm) {
  if (hhmm == null) return null;
  final parts = hhmm.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return TimeOfDay(hour: h, minute: m);
}

class SettingsPage extends StatefulWidget {
  static String id = 'SettingsPage';
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Controller get _controller => Get.find<Controller>();
  SettingsStore get _settings => Get.find<SettingsStore>();
  ProgressStore get _progress => Get.find<ProgressStore>();
  ReminderService? get _reminders => ReminderService.current;
  bool? _notifEnabled;

  @override
  void initState() {
    super.initState();
    _refreshNotificationStatus();
  }

  Future<void> _refreshNotificationStatus() async {
    final status = await _reminders?.notificationsEnabled();
    if (!mounted) return;
    setState(() => _notifEnabled = status);
  }

  Future<void> _pickTime({required bool morning}) async {
    final current = _parseTime(
        morning ? _settings.reminderMorning : _settings.reminderEvening);
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 7, minute: 0),
    );
    if (picked == null) return;
    final value = _fmt(picked.hour, picked.minute);
    if (morning) {
      await _settings.setReminderMorning(value);
    } else {
      await _settings.setReminderEvening(value);
    }
    await _reminders?.syncFromSettings(_settings);
    setState(() {});
  }

  Future<void> _toggleReminders(bool on) async {
    if (on) {
      final svc = _reminders;
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

      final before = await svc.notificationsEnabled();
      if (before != true) {
        await svc.requestPermission();
      }
      final after = await svc.notificationsEnabled();
      _notifEnabled = after;
      if (after == false && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'إذن الإشعارات غير مُفعل حالياً. فعّله من إعدادات النظام ثم أعد المحاولة.',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
        setState(() {});
        return;
      }

      // Default times on first enable.
      if (_settings.reminderMorning == null) {
        await _settings.setReminderMorning('07:00');
      }
      if (_settings.reminderEvening == null) {
        await _settings.setReminderEvening('19:00');
      }
    }
    await _settings.setRemindersEnabled(on);
    await _reminders?.syncFromSettings(_settings);
    await _refreshNotificationStatus();
    setState(() {});
  }

  Future<void> _sendTestNotification() async {
    final svc = _reminders;
    if (svc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            '\u0627\u0644\u062a\u0646\u0628\u064a\u0647\u0627\u062a \u063a\u064a\u0631 \u0645\u062a\u0627\u062d\u0629 \u0639\u0644\u0649 \u0647\u0630\u0627 \u0627\u0644\u062c\u0647\u0627\u0632.',
            textDirection: TextDirection.rtl),
      ));
      return;
    }
    final enabled = await svc.notificationsEnabled();
    _notifEnabled = enabled;
    if (enabled == false) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'الإشعارات محظورة للتطبيق. فعّلها من إعدادات النظام أولاً.',
            textDirection: TextDirection.rtl),
      ));
      setState(() {});
      return;
    }
    final at = await svc.scheduleTestNotification(const Duration(seconds: 60));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          at == null
              ? '\u062a\u0639\u0630\u0631 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u062a\u0646\u0628\u064a\u0647 \u0627\u0644\u062a\u062c\u0631\u064a\u0628\u064a\u060c \u062a\u062d\u0642\u0642 \u0645\u0646 \u0627\u0644\u0623\u0630\u0648\u0646\u0627\u062a.'
              : '\u062a\u0645\u062a \u062c\u062f\u0648\u0644\u0629 \u062a\u0646\u0628\u064a\u0647 \u062a\u062c\u0631\u064a\u0628\u064a \u0628\u0639\u062f \u062f\u0642\u064a\u0642\u0629.',
          textDirection: TextDirection.rtl),
    ));
  }

  Future<void> _export() async {
    final json = jsonEncode(BackupService.exportData(
        settings: _settings,
        progress: _progress,
        customs: Get.find<CustomAzkarStore>()));
    await Clipboard.setData(ClipboardData(text: json));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نسخ نسخة احتياطية إلى الحافظة.',
              textDirection: TextDirection.rtl),
        ),
      );
    }
  }

  Future<void> _import() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text == null || text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الحافظة فارغة — انسخ نسخة احتياطية أولاً.',
                textDirection: TextDirection.rtl),
          ),
        );
      }
      return;
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      decoded = null;
    }
    final error = await BackupService.importData(
        settings: _settings,
        progress: _progress,
        customs: Get.find<CustomAzkarStore>(),
        data: decoded);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error == null ? 'تم الاستيراد بنجاح.' : 'تعذر الاستيراد: $error',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات'), centerTitle: true),
      body: ListView(
        padding: pageInsets(context),
        children: [
          const AppSectionHeader(title: 'المظهر'),
          Card(
            child: Obx(() {
              final mode = _controller.mode.value;
              return RadioGroup<String>(
                groupValue: mode,
                onChanged: (v) async {
                  if (v == null) return;
                  _controller.setMode(v);
                  await _settings.setThemeMode(v);
                },
                child: Column(
                  children: [
                    _modeTile('فاتح', 'light', Icons.sunny),
                    _modeTile('داكن', 'dark', Icons.nights_stay),
                    _modeTile('أسود (AMOLED)', 'amoled', Icons.dark_mode),
                    _modeTile('حسب النظام', 'system', Icons.brightness_auto),
                  ],
                ),
              );
            }),
          ),
          const AppSectionHeader(title: 'الاسم'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextFormField(
                key: ValueKey('name:${_settings.userName ?? ''}'),
                initialValue: _settings.userName ?? '',
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'الاسم المعروض',
                  hintText: 'مثال: عبد الله',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (v) async {
                  await _settings.setUserName(v);
                  setState(() {});
                },
              ),
            ),
          ),
          const AppSectionHeader(title: 'القراءة'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'حجم الخط: ${_settings.textScale.toStringAsFixed(1)}×',
                    textDirection: TextDirection.rtl,
                  ),
                  Slider(
                    value: _settings.textScale,
                    min: 0.8,
                    max: 1.6,
                    divisions: 8,
                    label: '${_settings.textScale.toStringAsFixed(1)}×',
                    onChanged: (v) async {
                      await _settings.setTextScale(v);
                      setState(() {});
                    },
                  ),
                  Text(
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ — مثال حي لحجم الخط',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18 * _settings.textScale,
                      height: 2.0,
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('اهتزاز عند العد',
                        textDirection: TextDirection.rtl),
                    value: _settings.haptics,
                    onChanged: (v) async {
                      await _settings.setHaptics(v);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          const AppSectionHeader(title: 'مواقيت الصلاة'),
          Card(
            child: ListTile(
              title: const Text('إعدادات المواقيت والتنبيهات',
                  textDirection: TextDirection.rtl),
              subtitle: Text(
                _settings.prayerCityLabel ?? 'لم يتم اختيار الموقع',
                textDirection: TextDirection.rtl,
              ),
              trailing: const Icon(Icons.arrow_back_ios, size: 18),
              onTap: () => Navigator.pushNamed(context, PrayerTimesPage.id),
            ),
          ),
          const AppSectionHeader(title: 'تذكير الأذكار'),
          Card(
            child: Column(
              children: [
                if (_reminders == null)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'التنبيهات غير متاحة على هذا الجهاز.',
                      textDirection: TextDirection.rtl,
                    ),
                  )
                else ...[
                  ListTile(
                    title: const Text('حالة إذن الإشعارات',
                        textDirection: TextDirection.rtl),
                    subtitle: Text(
                      _notifEnabled == null
                          ? 'تعذر التحقق (أو غير مدعوم على هذا النظام).'
                          : (_notifEnabled!
                              ? 'مسموح: يمكن للتطبيق إرسال إشعارات.'
                              : 'محظور: فعّل إذن الإشعارات من إعدادات النظام.'),
                      textDirection: TextDirection.rtl,
                    ),
                    trailing: IconButton(
                      tooltip: 'تحديث الحالة',
                      onPressed: _refreshNotificationStatus,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('تفعيل التذكير اليومي',
                        textDirection: TextDirection.rtl),
                    value: _settings.remindersEnabled,
                    onChanged: _toggleReminders,
                  ),
                  ListTile(
                    title: const Text('تذكير الصباح',
                        textDirection: TextDirection.rtl),
                    trailing: Text(
                      _settings.reminderMorning ?? '--:--',
                      style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                    enabled: _settings.remindersEnabled,
                    onTap: _settings.remindersEnabled
                        ? () => _pickTime(morning: true)
                        : null,
                  ),
                  ListTile(
                    title: const Text('تذكير المساء',
                        textDirection: TextDirection.rtl),
                    trailing: Text(
                      _settings.reminderEvening ?? '--:--',
                      style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                    enabled: _settings.remindersEnabled,
                    onTap: _settings.remindersEnabled
                        ? () => _pickTime(morning: false)
                        : null,
                  ),
                ],
                ListTile(
                  title: const Text('إرسال إشعار تجريبي',
                      textDirection: TextDirection.rtl),
                  subtitle: const Text(
                      'تنبيه تجريبي بعد دقيقة للتحقق من الوصول',
                      textDirection: TextDirection.rtl),
                  trailing: const Icon(Icons.notifications_active_outlined),
                  onTap: _sendTestNotification,
                ),
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'ملاحظة: النظام قد يؤخر التنبيه قليلاً، وتنقطع التنبيهات بعد إعادة تشغيل الجهاز أو مع وضع توفير البطارية الشديد.',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const AppSectionHeader(title: 'البيانات'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('نسخ نسخة احتياطية',
                      textDirection: TextDirection.rtl),
                  trailing: const Icon(Icons.copy_outlined),
                  onTap: _export,
                ),
                ListTile(
                  title: const Text('استيراد من الحافظة',
                      textDirection: TextDirection.rtl),
                  trailing: const Icon(Icons.paste_outlined),
                  onTap: _import,
                ),
              ],
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('عن التطبيق', textDirection: TextDirection.rtl),
              trailing: const Icon(Icons.info_outline),
              onTap: () => Navigator.pushNamed(context, AboutUsPage.id),
            ),
          ),
          const AppSectionHeader(title: 'عن المحتوى'),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'الأذكار والأدعية مضمّنة في التطبيق وتعمل دون إنترنت. '
                'المصادر المعروضة محفوظة كما وردت؛ ما لا يحمل توثيقاً موسوم للمراجعة ولا يُنسب لمصدر.',
                textDirection: TextDirection.rtl,
                style: TextStyle(height: 1.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeTile(String label, String value, IconData icon) {
    return RadioListTile<String>(
      title: Text(label, textDirection: TextDirection.rtl),
      secondary: Icon(icon),
      value: value,
    );
  }
}

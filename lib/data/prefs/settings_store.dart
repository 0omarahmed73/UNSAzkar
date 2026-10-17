import 'package:azkar_new_app/data/prayer/prayer_service.dart';
import 'package:get_storage/get_storage.dart';

/// User preferences. Backed by [GetStorage]; constructor injection keeps it
/// testable with an isolated container.
///
/// Migration: legacy key `theme` (`light`|`dark`, written by v1 `Controller`)
/// is honored once and carried into `v2.themeMode`. The legacy key is left
/// in place so a downgrade still finds it.
class SettingsStore {
  SettingsStore(this._box);

  final GetStorage _box;

  static const String keyThemeMode = 'v2.themeMode';
  static const String keyUserName = 'v2.userName';
  static const String keyTextScale = 'v2.textScale';
  static const String keyHaptics = 'v2.haptics';
  static const String keySound = 'v2.sound';
  static const String keyReminderMorning = 'v2.reminderMorning';
  static const String keyReminderEvening = 'v2.reminderEvening';
  static const String keyRemindersEnabled = 'v2.remindersEnabled';
  static const String keyNotifPromptShown = 'v2.notifPromptShown';
  static const String keyPrayerMethod = 'v2.prayerMethod';
  static const String keyPrayerMadhab = 'v2.prayerMadhab';
  static const String keyPrayerLat = 'v2.prayerLat';
  static const String keyPrayerLng = 'v2.prayerLng';
  static const String keyPrayerCity = 'v2.prayerCity';
  static const String keyPrayerReminders = 'v2.prayerReminders';

  String themeMode = 'light';
  String? userName;
  PrayerMethod method = PrayerMethod.egyptian;
  PrayerMadhab madhab = PrayerMadhab.shafi;
  double? prayerLat;
  double? prayerLng;
  String? prayerCityLabel;
  final Map<String, bool> _prayerReminders = {};
  double textScale = 1.0;
  bool haptics = true;
  bool sound = false;
  String? reminderMorning;
  String? reminderEvening;
  bool remindersEnabled = false;
  bool notifPromptShown = false;

  static const validModes = {'light', 'dark', 'amoled', 'system'};

  Future<void> load() async {
    final migrated = _box.read<String>(keyThemeMode);
    if (migrated != null && validModes.contains(migrated)) {
      themeMode = migrated;
    } else {
      // One-time read of the v1 key; note: NOT deleted (downgrade-safe).
      final legacy = _box.read('theme');
      themeMode = (legacy == 'dark' || legacy == 'amoled') ? legacy : 'light';
      await _box.write(keyThemeMode, themeMode);
    }
    userName = _box.read<String?>(keyUserName);
    textScale = (_box.read(keyTextScale) as num?)?.toDouble() ?? 1.0;
    haptics = _box.read(keyHaptics) as bool? ?? true;
    sound = _box.read(keySound) as bool? ?? false;
    reminderMorning = _box.read<String?>(keyReminderMorning);
    reminderEvening = _box.read<String?>(keyReminderEvening);
    remindersEnabled = _box.read(keyRemindersEnabled) as bool? ?? false;
    notifPromptShown = _box.read(keyNotifPromptShown) as bool? ?? false;
    method = PrayerMethodInfo.fromKey(_box.read<String?>(keyPrayerMethod));
    madhab = PrayerMadhabInfo.fromKey(_box.read<String?>(keyPrayerMadhab));
    prayerLat = (_box.read(keyPrayerLat) as num?)?.toDouble();
    prayerLng = (_box.read(keyPrayerLng) as num?)?.toDouble();
    prayerCityLabel = _box.read<String?>(keyPrayerCity);
    _prayerReminders.clear();
    final rawRem = _box.read(keyPrayerReminders);
    if (rawRem is Map) {
      for (final e in rawRem.entries) {
        if (e.value is bool)
          _prayerReminders[e.key.toString()] = e.value as bool;
      }
    }
  }

  Future<void> setThemeMode(String mode) async {
    assert(validModes.contains(mode));
    themeMode = mode;
    await _box.write(keyThemeMode, mode);
    // Keep the legacy key in sync for any v1 code path still reading it.
    await _box.write('theme', mode == 'amoled' ? 'dark' : mode);
  }

  /// Display name shown in the greeting. Null/empty clears it.
  Future<void> setUserName(String? name) async {
    final trimmed = name?.trim();
    userName = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (userName == null) {
      await _box.remove(keyUserName);
    } else {
      await _box.write(keyUserName, userName);
    }
  }

  Future<void> setTextScale(double v) async {
    textScale = v.clamp(0.8, 1.6).toDouble();
    await _box.write(keyTextScale, textScale);
  }

  Future<void> setHaptics(bool v) async {
    haptics = v;
    await _box.write(keyHaptics, v);
  }

  Future<void> setSound(bool v) async {
    sound = v;
    await _box.write(keySound, v);
  }

  Future<void> setRemindersEnabled(bool v) async {
    remindersEnabled = v;
    await _box.write(keyRemindersEnabled, v);
  }

  /// First-launch notification explanation shown at most once ever.
  Future<void> setNotifPromptShown(bool v) async {
    notifPromptShown = v;
    await _box.write(keyNotifPromptShown, v);
  }

  /// Stores a daily time as `HH:MM` (24h). Null clears it.
  Future<void> setReminderMorning(String? hhmm) async {
    reminderMorning = hhmm;
    if (hhmm == null) {
      await _box.remove(keyReminderMorning);
    } else {
      await _box.write(keyReminderMorning, hhmm);
    }
  }

  Future<void> setReminderEvening(String? hhmm) async {
    reminderEvening = hhmm;
    if (hhmm == null) {
      await _box.remove(keyReminderEvening);
    } else {
      await _box.write(keyReminderEvening, hhmm);
    }
  }

  Future<void> setPrayerMethod(PrayerMethod m) async {
    method = m;
    await _box.write(keyPrayerMethod, m.key);
  }

  Future<void> setPrayerMadhab(PrayerMadhab m) async {
    madhab = m;
    await _box.write(keyPrayerMadhab, m.key);
  }

  Future<void> setPrayerLocation(double lat, double lng, String? city) async {
    prayerLat = lat;
    prayerLng = lng;
    prayerCityLabel =
        (city == null || city.trim().isEmpty) ? null : city.trim();
    await _box.write(keyPrayerLat, lat);
    await _box.write(keyPrayerLng, lng);
    if (prayerCityLabel == null) {
      await _box.remove(keyPrayerCity);
    } else {
      await _box.write(keyPrayerCity, prayerCityLabel);
    }
  }

  Future<void> clearPrayerLocation() async {
    prayerLat = null;
    prayerLng = null;
    prayerCityLabel = null;
    await _box.remove(keyPrayerLat);
    await _box.remove(keyPrayerLng);
    await _box.remove(keyPrayerCity);
  }

  bool prayerReminder(PrayerKind kind) => _prayerReminders[kind.key] ?? false;

  Map<String, bool> get prayerReminders => Map.unmodifiable(_prayerReminders);

  Future<void> setPrayerReminder(PrayerKind kind, bool on) async {
    _prayerReminders[kind.key] = on;
    await _box.write(keyPrayerReminders, Map.of(_prayerReminders));
  }

  /// Serializable snapshot for backup/restore (validated on import).
  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'userName': userName,
        'textScale': textScale,
        'haptics': haptics,
        'sound': sound,
        'remindersEnabled': remindersEnabled,
        'notifPromptShown': notifPromptShown,
        'reminderMorning': reminderMorning,
        'reminderEvening': reminderEvening,
        'prayerMethod': method.key,
        'prayerMadhab': madhab.key,
        'prayerLat': prayerLat,
        'prayerLng': prayerLng,
        'prayerCity': prayerCityLabel,
        'prayerReminders': Map.of(_prayerReminders),
      };

  /// Applies a validated backup map. Returns an error string on invalid
  /// input (state untouched), null on success. Never throws.
  Future<String?> applyJson(dynamic data) async {
    try {
      if (data is! Map) return 'not a settings object';
      final mode = data['themeMode'];
      themeMode = (mode is String && SettingsStore.validModes.contains(mode))
          ? mode
          : 'light';
      final name = data['userName'];
      userName =
          (name is String && name.trim().isNotEmpty) ? name.trim() : null;
      final scale = data['textScale'];
      textScale = (scale is num) ? scale.toDouble().clamp(0.8, 1.6) : 1.0;
      haptics = data['haptics'] is bool ? data['haptics'] as bool : true;
      sound = data['sound'] is bool ? data['sound'] as bool : false;
      remindersEnabled = data['remindersEnabled'] == true;
      notifPromptShown = data['notifPromptShown'] == true;
      reminderMorning = _validTime(data['reminderMorning']);
      reminderEvening = _validTime(data['reminderEvening']);
      method = PrayerMethodInfo.fromKey(data['prayerMethod'] is String
          ? data['prayerMethod'] as String
          : null);
      madhab = PrayerMadhabInfo.fromKey(data['prayerMadhab'] is String
          ? data['prayerMadhab'] as String
          : null);
      final lat = data['prayerLat'];
      final lng = data['prayerLng'];
      if (lat is num && lng is num) {
        prayerLat = lat.toDouble();
        prayerLng = lng.toDouble();
        final city = data['prayerCity'];
        prayerCityLabel =
            (city is String && city.trim().isNotEmpty) ? city.trim() : null;
      } else {
        prayerLat = null;
        prayerLng = null;
        prayerCityLabel = null;
      }
      _prayerReminders.clear();
      final pr = data['prayerReminders'];
      if (pr is Map) {
        for (final e in pr.entries) {
          if (e.value is bool)
            _prayerReminders[e.key.toString()] = e.value as bool;
        }
      }
      await _box.write(keyThemeMode, themeMode);
      if (userName == null) {
        await _box.remove(keyUserName);
      } else {
        await _box.write(keyUserName, userName);
      }
      await _box.write(keyTextScale, textScale);
      await _box.write(keyHaptics, haptics);
      await _box.write(keySound, sound);
      await _box.write(keyRemindersEnabled, remindersEnabled);
      await _box.write(keyNotifPromptShown, notifPromptShown);
      if (reminderMorning == null) {
        await _box.remove(keyReminderMorning);
      } else {
        await _box.write(keyReminderMorning, reminderMorning);
      }
      if (reminderEvening == null) {
        await _box.remove(keyReminderEvening);
      } else {
        await _box.write(keyReminderEvening, reminderEvening);
      }
      await _box.write(keyPrayerMethod, method.key);
      await _box.write(keyPrayerMadhab, madhab.key);
      if (prayerLat == null) {
        await _box.remove(keyPrayerLat);
        await _box.remove(keyPrayerLng);
        await _box.remove(keyPrayerCity);
      } else {
        await _box.write(keyPrayerLat, prayerLat);
        await _box.write(keyPrayerLng, prayerLng);
        if (prayerCityLabel == null) {
          await _box.remove(keyPrayerCity);
        } else {
          await _box.write(keyPrayerCity, prayerCityLabel);
        }
      }
      await _box.write(keyPrayerReminders, Map.of(_prayerReminders));
      return null;
    } catch (_) {
      return 'unreadable settings backup';
    }
  }

  static String? _validTime(dynamic v) {
    if (v is! String) return null;
    final parts = v.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return v;
  }

  bool get isDark => themeMode != 'light';
  bool get isAmoled => themeMode == 'amoled';
}

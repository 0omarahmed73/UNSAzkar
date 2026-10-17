import 'package:adhan/adhan.dart';

/// The six daily prayers (+sunrise) with stable Arabic labels.
enum PrayerKind { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension PrayerKindLabel on PrayerKind {
  String get arabic => switch (this) {
        PrayerKind.fajr => 'الفجر',
        PrayerKind.sunrise => 'الشروق',
        PrayerKind.dhuhr => 'الظهر',
        PrayerKind.asr => 'العصر',
        PrayerKind.maghrib => 'المغرب',
        PrayerKind.isha => 'العشاء',
      };

  String get key => name;
}

/// Calculation conventions exposed in Settings. Egyptian General Authority
/// of Survey is the default for Egypt.
enum PrayerMethod { egyptian, muslimWorldLeague, karachi, ummAlQura }

extension PrayerMethodInfo on PrayerMethod {
  String get arabic => switch (this) {
        PrayerMethod.egyptian => 'الهيئة المصرية العامة للمساحة',
        PrayerMethod.muslimWorldLeague => 'رابطة العالم الإسلامي',
        PrayerMethod.karachi => 'جامعة العلوم الإسلامية، كراتشي',
        PrayerMethod.ummAlQura => 'أم القرى، مكة المكرمة',
      };

  CalculationMethod get adhan => switch (this) {
        PrayerMethod.egyptian => CalculationMethod.egyptian,
        PrayerMethod.muslimWorldLeague => CalculationMethod.muslim_world_league,
        PrayerMethod.karachi => CalculationMethod.karachi,
        PrayerMethod.ummAlQura => CalculationMethod.umm_al_qura,
      };

  static PrayerMethod fromKey(String? key) => PrayerMethod.values
      .firstWhere((m) => m.key == key, orElse: () => PrayerMethod.egyptian);

  String get key => name;
}

enum PrayerMadhab { shafi, hanafi }

extension PrayerMadhabInfo on PrayerMadhab {
  String get arabic => this == PrayerMadhab.shafi ? 'الشافعي' : 'الحنفي';

  Madhab get adhan => this == PrayerMadhab.shafi ? Madhab.shafi : Madhab.hanafi;

  static PrayerMadhab fromKey(String? key) =>
      key == 'hanafi' ? PrayerMadhab.hanafi : PrayerMadhab.shafi;

  String get key => name;
}

/// One local day of calculated times (offline, adhan package).
class DailyPrayers {
  DailyPrayers({required this.date, required this.times});

  final DateTime date;
  final Map<PrayerKind, DateTime> times;
}

/// The upcoming prayer with its countdown target.
class UpcomingPrayer {
  UpcomingPrayer({required this.kind, required this.at, required this.now});

  final PrayerKind kind;
  final DateTime at;
  final DateTime now;

  Duration get countdown => at.difference(now);
}

/// One schedulable prayer notification instance. Ids are stable per
/// (kind, day-offset) so resyncing replaces rather than duplicates.
class PrayerNotificationJob {
  PrayerNotificationJob(
      {required this.id,
      required this.kind,
      required this.at,
      required this.title,
      required this.body});

  final int id;
  final PrayerKind kind;
  final DateTime at;
  final String title;
  final String body;
}

class PrayerService {
  /// Pure offline calculation for [date]'s local day. Throws only on
  /// invalid coordinates; never fabricates — failures propagate to the UI
  /// as explicit errors.
  static DailyPrayers calculate({
    required double lat,
    required double lng,
    required DateTime date,
    required PrayerMethod method,
    required PrayerMadhab madhab,
  }) {
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      throw ArgumentError('Invalid coordinates ($lat, $lng)');
    }
    final params = method.adhan.getParameters()..madhab = madhab.adhan;
    final pt = PrayerTimes(
      Coordinates(lat, lng),
      DateComponents(date.year, date.month, date.day),
      params,
    );
    DateTime local(DateTime t) =>
        DateTime(date.year, date.month, date.day, t.hour, t.minute, t.second);
    return DailyPrayers(
        date: DateTime(date.year, date.month, date.day),
        times: {
          PrayerKind.fajr: local(pt.fajr),
          PrayerKind.sunrise: local(pt.sunrise),
          PrayerKind.dhuhr: local(pt.dhuhr),
          PrayerKind.asr: local(pt.asr),
          PrayerKind.maghrib: local(pt.maghrib),
          PrayerKind.isha: local(pt.isha),
        });
  }

  /// First prayer strictly after [now]; after Isha this is tomorrow's Fajr.
  /// Pass the following day's times for correct rollover countdowns.
  static UpcomingPrayer nextPrayer(
      DailyPrayers today, DailyPrayers tomorrow, DateTime now) {
    const order = PrayerKind.values;
    for (final kind in order) {
      final at = today.times[kind]!;
      if (at.isAfter(now)) return UpcomingPrayer(kind: kind, at: at, now: now);
    }
    final fajr = tomorrow.times[PrayerKind.fajr]!;
    return UpcomingPrayer(kind: PrayerKind.fajr, at: fajr, now: now);
  }

  /// Jobs for enabled prayers strictly in the future (today remaining +
  /// tomorrow), with stable ids: 200+kindIndex (today), 300+kindIndex.
  static List<PrayerNotificationJob> prayerJobs({
    required DailyPrayers today,
    required DailyPrayers tomorrow,
    required DateTime now,
    required Map<String, bool> enabled,
  }) {
    final jobs = <PrayerNotificationJob>[];
    for (final entry in today.times.entries) {
      if ((enabled[entry.key.key] ?? false) && entry.value.isAfter(now)) {
        jobs.add(_job(entry.key, entry.value, 200, today.date));
      }
    }
    for (final entry in tomorrow.times.entries) {
      if (enabled[entry.key.key] ?? false) {
        jobs.add(_job(entry.key, entry.value, 300, tomorrow.date));
      }
    }
    return jobs;
  }

  static PrayerNotificationJob _job(
      PrayerKind kind, DateTime at, int base, DateTime day) {
    final label = kind.arabic;
    return PrayerNotificationJob(
      id: base + PrayerKind.values.indexOf(kind),
      kind: kind,
      at: at,
      title: kind == PrayerKind.sunrise ? 'الشروق' : 'حان وقت $label',
      body: kind == PrayerKind.sunrise ? 'أشرقت الشمس' : 'حان وقت صلاة $label',
    );
  }

  /// Short Arabic countdown: hours+minutes, minutes only, or "now".
  static String formatCountdown(Duration d) {
    if (d.inSeconds < 60) return 'حان الآن';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    String hourWord(int h) {
      if (h == 1) return 'ساعة';
      if (h == 2) return 'ساعتين';
      if (h <= 10) return 'ساعات';
      return 'ساعة';
    }

    String minWord(int m) {
      if (m == 1) return 'دقيقة';
      if (m == 2) return 'دقيقتين';
      if (m <= 10) return 'دقائق';
      return 'دقيقة';
    }

    if (hours <= 0) {
      if (minutes == 1) return 'بعد دقيقة';
      if (minutes == 2) return 'بعد دقيقتين';
      return 'بعد $minutes ${minWord(minutes)}';
    }
    final hPart = hours == 1
        ? 'بعد ساعة'
        : hours == 2
            ? 'بعد ساعتين'
            : 'بعد $hours ${hourWord(hours)}';
    if (minutes <= 0) return hPart;
    return '$hPart و $minutes ${minWord(minutes)}';
  }
}

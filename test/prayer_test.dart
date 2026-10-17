import 'package:azkar_new_app/data/prayer/prayer_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cairo, 15 Jan 2026. All expectations are structural/relational —
/// no fabricated times, only ordering, method/madhab sensitivity,
/// and rollover behavior.
void main() {
  const lat = 30.0444;
  const lng = 31.2357;
  final day = DateTime(2026, 1, 15);

  DailyPrayers calc(
          {PrayerMethod method = PrayerMethod.egyptian,
          PrayerMadhab madhab = PrayerMadhab.shafi}) =>
      PrayerService.calculate(
          lat: lat, lng: lng, date: day, method: method, madhab: madhab);

  test('all six times exist and are ordered within the day', () {
    final t = calc().times;
    expect(t.keys.toSet(), PrayerKind.values.toSet());
    final ordered = [
      PrayerKind.fajr,
      PrayerKind.sunrise,
      PrayerKind.dhuhr,
      PrayerKind.asr,
      PrayerKind.maghrib,
      PrayerKind.isha,
    ];
    for (var i = 0; i + 1 < ordered.length; i++) {
      expect(t[ordered[i]]!.isBefore(t[ordered[i + 1]]!), isTrue,
          reason: '${ordered[i]} before ${ordered[i + 1]}');
    }
  });

  test('madhab changes Asr (Shafi vs Hanafi differ)', () {
    final shafi = calc(madhab: PrayerMadhab.shafi).times[PrayerKind.asr]!;
    final hanafi = calc(madhab: PrayerMadhab.hanafi).times[PrayerKind.asr]!;
    expect(hanafi.isAfter(shafi), isTrue);
  });

  test('calculation method changes Fajr (Egypt vs Karachi differ)', () {
    final eg = calc(method: PrayerMethod.egyptian).times[PrayerKind.fajr]!;
    final k = calc(method: PrayerMethod.karachi).times[PrayerKind.fajr]!;
    expect(eg == k, isFalse);
  });

  test('midday now yields Dhuhr or Asr as next, with positive countdown',
      () {
    final today = calc();
    final tomorrow = PrayerService.calculate(
        lat: lat,
        lng: lng,
        date: day.add(const Duration(days: 1)),
        method: PrayerMethod.egyptian,
        madhab: PrayerMadhab.shafi);
    final now = DateTime(2026, 1, 15, 12, 30);
    final next = PrayerService.nextPrayer(today, tomorrow, now);
    expect(
        next.kind == PrayerKind.dhuhr || next.kind == PrayerKind.asr,
        isTrue);
    expect(next.at.isAfter(now), isTrue);
    expect(next.countdown.inMinutes, greaterThan(0));
  });

  test('after Isha the next prayer is tomorrow Fajr (rollover)', () {
    final today = calc();
    final tomorrow = PrayerService.calculate(
        lat: lat,
        lng: lng,
        date: day.add(const Duration(days: 1)),
        method: PrayerMethod.egyptian,
        madhab: PrayerMadhab.shafi);
    final now = DateTime(2026, 1, 15, 23, 30);
    final next = PrayerService.nextPrayer(today, tomorrow, now);
    expect(next.kind, PrayerKind.fajr);
    expect(next.at.day, 16);
    expect(next.countdown.inMinutes, greaterThan(0));
  });

  test('before Fajr the next prayer is today Fajr', () {
    final today = calc();
    final tomorrow = PrayerService.calculate(
        lat: lat,
        lng: lng,
        date: day.add(const Duration(days: 1)),
        method: PrayerMethod.egyptian,
        madhab: PrayerMadhab.shafi);
    final now = DateTime(2026, 1, 15, 3, 0);
    final next = PrayerService.nextPrayer(today, tomorrow, now);
    expect(next.kind, PrayerKind.fajr);
    expect(next.at.day, 15);
  });

  test('prayer names are Arabic and stable', () {
    expect(PrayerKind.fajr.arabic, 'الفجر');
    expect(PrayerKind.sunrise.arabic, 'الشروق');
    expect(PrayerKind.dhuhr.arabic, 'الظهر');
    expect(PrayerKind.asr.arabic, 'العصر');
    expect(PrayerKind.maghrib.arabic, 'المغرب');
    expect(PrayerKind.isha.arabic, 'العشاء');
  });

  test('supported methods include the required four', () {
    expect(PrayerMethod.values,
        containsAll([PrayerMethod.egyptian, PrayerMethod.ummAlQura, PrayerMethod.karachi, PrayerMethod.muslimWorldLeague]));
    expect(PrayerMethod.egyptian.arabic, contains('المصري'));
  });
}

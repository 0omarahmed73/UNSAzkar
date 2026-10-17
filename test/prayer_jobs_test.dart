import 'package:azkar_new_app/data/prayer/prayer_service.dart';
import 'package:flutter_test/flutter_test.dart';

DailyPrayers dayOf(int day, {PrayerMethod method = PrayerMethod.egyptian}) =>
    PrayerService.calculate(
      lat: 30.0444,
      lng: 31.2357,
      date: DateTime(2026, 1, day),
      method: method,
      madhab: PrayerMadhab.shafi,
    );

void main() {
  test('countdown formatting is Arabic and human', () {
    expect(PrayerService.formatCountdown(const Duration(hours: 2, minutes: 15)),
        'بعد ساعتين و 15 دقيقة');
    expect(PrayerService.formatCountdown(const Duration(hours: 1, minutes: 5)),
        'بعد ساعة و 5 دقائق');
    expect(
        PrayerService.formatCountdown(const Duration(minutes: 45)),
        'بعد 45 دقيقة');
    expect(PrayerService.formatCountdown(const Duration(minutes: 1)),
        'بعد دقيقة');
    expect(PrayerService.formatCountdown(const Duration(minutes: 2)),
        'بعد دقيقتين');
    expect(
        PrayerService.formatCountdown(Duration.zero), 'حان الآن');
  });

  test('prayer jobs only include enabled future prayers with stable ids',
      () {
    final today = dayOf(15);
    final tomorrow = dayOf(16);
    final now = DateTime(2026, 1, 15, 13, 0); // after dhuhr (Cairo ~11:5x)
    final jobs = PrayerService.prayerJobs(
      today: today,
      tomorrow: tomorrow,
      now: now,
      enabled: {'fajr': true, 'dhuhr': true, 'maghrib': true},
    );
    final kinds = jobs.map((j) => j.kind).toSet();
    // Past prayers (fajr, and dhuhr if already due) are skipped.
    expect(kinds.contains(PrayerKind.maghrib), isTrue);
    for (final j in jobs) {
      expect(j.at.isAfter(now), isTrue);
      expect(j.id, greaterThanOrEqualTo(200));
    }
    // Stable ids: same kind+day → same id across calls.
    final again = PrayerService.prayerJobs(
      today: today,
      tomorrow: tomorrow,
      now: now,
      enabled: {'fajr': true, 'dhuhr': true, 'maghrib': true},
    );
    expect(again.map((j) => j.id).toList(),
        jobs.map((j) => j.id).toList());
    // Disabled kinds never scheduled.
    expect(kinds.contains(PrayerKind.asr), isFalse);
    expect(kinds.contains(PrayerKind.isha), isFalse);
  });

  test('prayer jobs include tomorrow fajr when enabled after isha', () {
    final today = dayOf(15);
    final tomorrow = dayOf(16);
    final now = DateTime(2026, 1, 15, 23, 30);
    final jobs = PrayerService.prayerJobs(
      today: today,
      tomorrow: tomorrow,
      now: now,
      enabled: {'fajr': true},
    );
    expect(jobs.length, 1);
    expect(jobs.first.kind, PrayerKind.fajr);
    expect(jobs.first.at.day, 16);
  });
}

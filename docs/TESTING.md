# Testing — verified 2026-10-17 (Flutter 3.47.7 / Dart 3.13.5)

- `dart format` clean (applied incrementally).
- `flutter analyze` → **0 errors, 0 warnings** (infos only, mostly pre-existing legacy `file_names`/style notes).
- `flutter test` → **91/91 pass, exit 0** (~1 min), including:
  - Persistence: display name + theme/system-mode round-trips, corrupt/legacy fallback to light, controller restore path, backup round-trip incl. settings+prayer prefs, corrupt-backup atomicity.
  - RTL: tab order [الرئيسية,الأذكار,الدعاء,عنا], destinations, selected state, title-on-right.
  - شكر النعم: reachable from Dua tab, add/toggle persists; fixed a real ListTile ink-splash bug found by the test.
  - Azkar/tasbeeh: rapid taps exact counts, AnimatedOpacity completion fade, reduced-motion immediacy, restart persistence, corrupted-backup safety.
  - Safe area: 7 screens reserve the system bottom inset; last content reachable by drag.
  - Splash: BrandFade entrance completes; renders directly with animations disabled.
  - Quran: bundled mushaf integrity (114/6236/30 totals, Ikhlas/Baqarah/Fatiha spot checks, Uthmani diacritics preserved, verse symbols, random-verse validity).
  - Prayer: calculation structure/order, madhab + method sensitivity, midnight rollover, countdown formatting, notification job scheduling (future-only, stable ids), prefs persistence, method/madhab/location UI flows, permission-denied explanation, home card CTA + navigation.
- Test environment: hermetic `test_helpers.dart` (path_provider + splash + geolocator channel mocks); all async fixture I/O in `setUpAll`/`setUp` (real async — never inside `testWidgets` FakeAsync bodies); `dragIntoView` helper for lazily built list content; timed `pump` (not settle) where a 30s live ticker runs.
- Known gaps: no on-device run yet (emulator verification in progress); reminder exact timing, battery-saver behavior, and iOS build untested; upgrade-from-v1 on a real device untested; Samsung-device keyboard behavior needs manual check.

# Azkar Refinement & Expansion — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix Quran rendering, notification permission flow, splash/icon (pending SVG), transitions/haptics, custom Azkar management, settings persistence, map location picker; verify with tests + device screenshots + fresh APKs.

**Architecture:** Keep Get/GetStorage + repository/stores. Add: bundled Quran font (investigate first), `CustomAzkarStore` (user overlays, separate keys), `flutter_map`+`latlong2` (offline tiles? document), keep `ReminderService` (fix permission prompt timing).

**Tech Stack:** Flutter 3.47.7 / Dart 3.13.5; adhan (kept), geolocator/geocoding (kept), flutter_map + latlong2 (new, pending API check), no new backend.

**Spec:** Conversation brief 2026-10-17 (11 priorities). Design refs: `docs/prototype/*.png`; icon SVGs in `assets/icon-source/` (copied from uploads — user-supplied, NOT generated).

## Global Constraints

- Preserve bundled Arabic religious text verbatim; never invent sources/verses/times.
- user-supplied SVGs are the logo direction; integrate ONLY the supplied asset, never redraw.
- Icon integration stays PENDING until the missing/unstable file question is resolved with the user (foreground path flaky) — pipeline prepared, no substitution.
- No fake buttons; no test-pass claims without execution; no device claims without screenshots.
- Quran reader NOT expanded; no audio; no accounts.

## Review Focus

- Quran glyph integrity after font bundling (diacritics, Uthmani marks, verse symbols).
- Notification permission first-launch prompt exactly once; denied path explains + retries.
- Custom Azkar never clobbers bundled ids; survives upgrade + backup round-trip.
- Map picker works offline-ish (tiles need network — document; manual city always available).
- Rapid taps exact; haptics only where enabled/supported.

---
### Task 1: Quran typography root-cause + fix
**Files:** Create: `test/quran_render_test.dart`. Modify: `pubspec.yaml` (font), `lib/design/*` (Quran text style), verse card widgets.
- [ ] **Step 1: Investigate** dataset (`quran` pkg text), installed fonts, current TextStyle (letterSpacing? fontFamily fallback?) — record cause.
- [ ] **Step 2: Write failing test** — renders sample verse, asserts no `[]`/tofu markers, diacritics preserved.
- [ ] **Step 3: Run** — Expected: FAIL (wrong font/tofu).
- [ ] **Step 4: Implement** — bundle licensed Quran font (verify license file), apply to Quran text only, fix spacing/height.
- [ ] **Step 5: Run full suite** — Expected: PASS.
- [ ] **Step 6: Screenshot on device** — compare vs reference.
- [ ] **Step 7: Commit** — `git commit -m "fix: bundle Quran font, fix verse rendering"`

### Task 2: Notification permission + scheduling audit
**Files:** Modify: `lib/data/notifications/reminder_service.dart`, `lib/main.dart` (first-launch prompt timing), `AndroidManifest.xml` (verify), `test/reminder_flow_test.dart` (new).
- [ ] Failing tests for: prompt-once logic, denied→explanation+retry, resync on settings/date change, stable ids (no dupes).
- [ ] Implement, suite green, device-verify scheduled notification exists (`adb dumpsys notification`), commit.

### Task 3: Splash architecture + icon pipeline (logo PENDING)
**Files:** Create: `tool/make_icons.sh` (SVG→PNG at densities), `assets/icon-source/` (copied SVGs). Modify: `flutter_native_splash.yaml`, Android adaptive icon XML + mipmap PNGs, `lib/main.dart` transition.
- [ ] Prepare pipeline WITHOUT overwriting current icon; mark pending in docs.
- [ ] After user confirms asset: run pipeline, integrate, cold-start screenshot, launcher screenshot, commit.

### Task 4: Transitions + haptics
**Files:** Modify: page transitions (GetMaterialApp default → subdued), `AzkarPage._onTap` (haptics check device support), tasbeeh tap path. Tests: `test/haptics_test.dart`, nav timing tests.
- [ ] Profile: confirm no disk/network on navigation path (code read + test with fake async).
- [ ] Failing tests → implement (HapticFeedback gated by settings + try/catch) → green → commit.

### Task 5: Custom Azkar («إدارة الأذكار» + «أذكاري المخصصة»)
**Files:** Create: `lib/data/prefs/custom_azkar_store.dart`, `lib/pages/CustomAzkarPage.dart`, `test/custom_azkar_test.dart`. Modify: repository merge logic, backup service, AzkarCategories entry.
- [ ] Failing tests: create/edit/delete/assign/reorder/repeat validation/persist/restore-defaults/backup.
- [ ] Implement overlay model (`custom:<uuid>` ids, overrides map, never rewrite bundled lists) → green → commit.

### Task 6-7: Preserve behaviors + settings (regression tests exist; extend)
- Display-name + theme tests already green; add restart-order test (prefs loaded before first frame).
- شكر النعم reachability test exists; keep green.

### Task 8: Map picker
**Files:** Create: `lib/pages/MapPickerPage.dart` (flutter_map + marker + confirm/cancel). Modify: `PrayerTimesPage` (map button), pubspec. Tests: selection/confirm/cancel/persist/offline-fallback.
- [ ] Failing tests → implement → green → device screenshot → commit.

### Task 9-10: Layout/RTL + preserve (assert via widget tests + screenshots; no new features).

### Task 11: Verify — format, analyze (report infos honestly), suite count+exit, diff-check, fresh debug+release APKs, install on emulator (no physical device here — report as emulator-verified), screenshots per screen, final self-review, commit.

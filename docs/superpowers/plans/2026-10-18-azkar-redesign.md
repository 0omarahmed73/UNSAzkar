# Azkar 2.0 Redesign, Prayer Times & Compliance Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix reported bugs, enforce the supplied prototype design, add prayer times + Quran integrity + animations, verify with tests and a debug APK.

**Architecture:** Keep Get/GetStorage + repository/stores; add `PrayerService` (adhan pkg), `LocationStore` extension in SettingsStore, `PrayerTimesPage`, home prayer card, user display name in SettingsStore. No backend, no new state framework.

**Tech Stack:** Flutter 3.47.7 / Dart 3.13.5; adhan (new), geolocator + geocoding (new); existing get/get_storage/flutter_local_notifications/timezone.

**Spec:** Conversation brief 2026-10-18 (16 sections) + `docs/prototype/*.png` (9 screens) + `docs/DESIGN_SYSTEM.md`. The prototype PNGs are the visual authority; the two SVGs are references only — launcher icon integration stays PENDING until the user sends the final asset.

## Global Constraints

- Follow the supplied prototype; do not invent a new design or restyle screens.
- Preserve navy `#0A1B2D` / gold `#D8B75A` / ivory `#F7F4EE` palette and Arabic RTL everywhere.
- Preserve bundled Arabic religious text verbatim; never invent sources, verses, or times.
- No fake buttons: every control wired or omitted with a documented reason.
- Launcher icon: DO NOT integrate the SVGs; mark pending until the user sends the asset.
- No test-pass claims without execution; no visual claims without rendered inspection.
- P1/P2 Quran-reader expansion and audio remain out of scope; only integrity + rendering of existing content.

## Review Focus

- Theme/name restore after process kill (not just hot reload) — storage flush timing.
- Bottom content reachable above gesture nav on tall/short screens.
- Prayer times across midnight/DST/method changes — never show fabricated times.
- Rapid taps produce exact counts; completed cards animate out without layout jumps.
- RTL tab order right→left: الرئيسية، الأذكار، الدعاء، عنا; title on the right.

---

### Task 1: Settings persistence — display name + theme restore

**Files:**
- Modify: `lib/data/prefs/settings_store.dart`, `lib/pages/SettingsPage.dart`, `lib/pages/HomePage.dart` (greeting), `lib/controller/controller.dart` (System mode)
- Test: `test/settings_persistence_test.dart`

**Interfaces:**
- Consumes: SettingsStore keys, Controller.mode.
- Produces: `SettingsStore.userName (String? get/set)`, `Controller.setMode` accepts `light|dark|amoled|system`, startup applies stored mode before first frame.

- [ ] **Step 1: Write failing tests** — name round-trips across store instances; invalid/legacy mode values fall back to light; `system` mode persists and resolves.
- [ ] **Step 2: Run** — `flutter test test/settings_persistence_test.dart` — Expected: FAIL (no API).
- [ ] **Step 3: Implement** store field + Settings UI section + greeting use + System mode mapping (`ThemeMode.system`).
- [ ] **Step 4: Run** — Expected: PASS; then full `flutter test` green.
- [ ] **Step 5: Commit** — `git commit -m "feat: persist display name and restore theme incl system mode"`

### Task 2: RTL navigation + header compliance

**Files:**
- Modify: `lib/pages/HomePage.dart` (tab order, header order, single AppBar rule), callers of `setPageIndex`
- Test: extend `test/home_test.dart` (tab order right→left, destinations, selected state, title right)

- [ ] **Step 1: Failing tests** for tab labels order, tap→destination, title alignment.
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement** — items `[الرئيسية, الأذكار, الدعاء, عنا]`, index remap, header `[title | actions]`, hide shell AppBar on tabs with own AppBar (or remove inner duplication — decide by rendered/tested widget count == 1).
- [ ] **Step 4: Run** full suite — Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "fix: correct RTL tab order and header layout"`

### Task 3: Restore شكر النعم navigation + regression test

**Files:**
- Modify: `lib/pages/PrayersPage.dart` (add شكر النعم entry), maybe home quick access
- Test: `test/thanking_test.dart` (route opens from Dua tab, renders, persists toggle)

- [ ] **Step 1: Failing test** — Expected: FAIL (unreachable).
- [ ] **Step 2-4:** Implement + green suite.
- [ ] **Step 5: Commit** — `git commit -m "fix: restore شكر النعم navigation"`

### Task 4: Azkar/tasbeeh responsiveness + motion

**Files:**
- Modify: `lib/pages/AzkarPage.dart`, `lib/design/components.dart` (`DhikrReaderCard`), `lib/pages/TasbeehRingPage.dart`
- Test: `test/azkar_motion_test.dart` (rapid taps exact count, completion animation completes, no layout exception; reduced-motion respected)

- [ ] **Step 1: Failing tests** — Expected: FAIL.
- [ ] **Step 2-4:** AnimatedSwitcher/AnimatedSize on completion, synchronous counter update before persistence await, completion feedback; no per-tap disk-sync blocking (keep awaited writes but don't gate UI).
- [ ] **Step 5: Commit** — `git commit -m "feat: responsive counters with smooth completion motion"`

### Task 5: Safe-area + bottom reachability

**Files:** all `lib/pages/*.dart` bodies, `HomePage` shell
- Test: widget tests assert last item reachable via drag + `takeException()` clean; bottom nav above system UI.

- [ ] Failing test → implement (`SafeArea`/directional bottom padding, no fixed magic numbers) → green → commit `fix: safe-area and bottom reachability`.

### Task 6: Splash polish (icon stays pending)

**Files:** `flutter_native_splash.yaml`, `lib/pages/HomePage.dart` (brand fade-in)
- Subtle fade/scale on first frame only; keep native config compatible; icon asset UNCHANGED (pending user asset, recorded in docs).

### Task 7: Quran integrity + rendering

**Files:** Test `test/quran_integrity_test.dart` (bundled `quran` package: spot-check short/long surahs, order, identifiers, diacritics preserved); Modify `HomePage` verse card (surah name + number, decorative frame, error fallback).
- No network, no new data source unless validation fails (then report, don't invent).

### Task 8: Prayer times (service → screen → home card → settings → reminders)

**Files:**
- Modify: `pubspec.yaml` (adhan, geolocator, geocoding — verify APIs post-install)
- Create: `lib/data/prayer/prayer_service.dart`, `lib/pages/PrayerTimesPage.dart`
- Modify: `SettingsStore` (method, madhab, lat/lng, city label, per-prayer reminders), `SettingsPage`, `HomePage` (card), `ReminderService` (prayer scheduling)
- Test: `test/prayer_test.dart` (methods, madhab diff, midnight rollover, countdown math, persistence, permission-denied fallback, offline)

- [ ] Tests first (pure-math parts fail without impl) → implement → green → commit per sub-step (service, screen, card, settings, reminders).

### Task 9: Entrance micro-animations + reduced motion

**Files:** `lib/design/components.dart` (shared fade-rise wrapper honoring `MediaQuery.disableAnimations`), apply to home cards/headers/dialogs.
- Tests: animation completes, content present with animations disabled.

### Task 10: Verify — analyze, suite, diff-check, debug APK, visual pass

- [ ] `flutter analyze` 0 errors/warnings (excluding pre-existing infos)
- [ ] Full `flutter test` green
- [ ] `git diff --check` clean, no probes/leftovers
- [ ] `flutter build apk --debug` success, record path + size
- [ ] Emulator/rendered screenshots vs prototype where feasible; per-screen compliance report; icon + Samsung-device items marked unverified/manual.

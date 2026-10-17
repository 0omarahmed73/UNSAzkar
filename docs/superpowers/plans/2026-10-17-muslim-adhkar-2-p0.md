# Muslim Adhkar 2.0 P0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a stable P0 offline-first rebuild: design system, id-stable data layer, Home/Adhkar/Tasbeeh/Library/Settings, persistence, reminders, tested critical logic.

**Architecture:** Keep Get + GetStorage deliberately (existing, works, minimal churn — no Riverpod/go_router/Drift migration in P0). Add `AzkarRepository` between bundled content (`AllAzkar`, `NightOrMorning`) and UI; pure-Dart progress/counter logic under `lib/logic/` fully unit-tested; ThemeData-based theming.

**Tech Stack:** Flutter 3.x / Dart >=3.3.0 <4.0.0; get ^4.6.6; get_storage ^2.1.1; flutter_local_notifications (new, for reminders); flutter_test.

**Spec:** Master prompt in session (P0 §6) + `docs/PROJECT_AUDIT.md` (content inventory, preserve verbatim Arabic text, never invent sources).

## Global Constraints

- Preserve bundled Arabic religious text verbatim — never rewrite diacritics or invent sources/repeats; missing source → flag `source: null` + `needsReview: true`.
- Offline-first: bundled adhkar + tasbeeh work with no network; no location permission unless user enables prayer features (P1, out of scope).
- No Firebase/auth/backend/ads/social; no secrets in repo.
- Keep Get/GetStorage; do not add Riverpod/go_router/Drift in P0 without written justification.
- Existing GetStorage keys `theme`, `blesses` keep working (migration, not wipe).
- No fake buttons: every control wired or omitted.
- No test-pass claims without execution; `flutter` unavailable in this env → verification deferred, noted per task.

## Review Focus

- Repeat values from bundled maps (1/3/4/7/34) survive id-migration with exact counts — user completing a 7x item expects 7 taps, not 6 or 8.
- Arabic text with diacritics renders unclipped at 1.3x system text scale in reading view.
- Tasbeeh reset requires explicit confirm; a stray tap must not wipe a 900-count session.
- Upgrade from v1 storage (`theme` as String, `blesses` list) never crashes and never loses blesses.
- Reminder times survive timezone/DST change without duplicate or lost alarms (best-effort on Android battery-saver, documented).

---

### Task 1: Baseline — fix test harness + pure counter/progress logic

**Files:**
- Modify: `test/widget_test.dart` (replace broken MyApp counter test)
- Create: `lib/logic/repeat_counter.dart`
- Create: `lib/logic/daily_progress.dart`
- Test: `test/repeat_counter_test.dart`, `test/daily_progress_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `RepeatCounter({required int total})`, `remaining`, `isComplete`, `tap() -> bool completedThisTap`, `reset()`; `DailyProgress.completed/total`, `fraction`, `isDateToday(DateTime)`, `rolloverIfNewDay(lastOpen, today) -> bool reset`.

- [ ] **Step 1: Write failing tests** in `test/repeat_counter_test.dart` + `test/daily_progress_test.dart`: total=3 → 3 taps complete, 4th tap stays complete; remaining decrements 3→0; reset restores; progress 2/5 → 0.4; date-boundary rollover resets.
- [ ] **Step 2: Run to verify they fail.** Run: `flutter test test/repeat_counter_test.dart test/daily_progress_test.dart`. Expected: FAIL (files under test missing).
- [ ] **Step 3: Implement** `RepeatCounter` and `DailyProgress` as pure Dart (no Flutter imports) in `lib/logic/`.
- [ ] **Step 4: Run tests.** Run: `flutter test`. Expected: PASS. (Deferred: no SDK in this env.)
- [ ] **Step 5: Replace `test/widget_test.dart`** with a smoke test pumping `AzkarApp` and expecting home title; delete MyApp reference.
- [ ] **Step 6: Commit.** `git add lib/logic test && git commit -m "feat: add tested repeat counter and daily progress logic"`

### Task 2: Design system — tokens, 3 themes, reusable components

**Files:**
- Create: `lib/design/tokens.dart`
- Create: `lib/design/app_theme.dart`
- Create: `lib/design/components.dart`
- Modify: `lib/main.dart` (wire ThemeMode, remove inline theme maps from main only)
- Test: `test/theme_test.dart`

**Interfaces:**
- Consumes: GetStorage `theme` key (values `light|dark|amoled`).
- Produces: `AppColors{navy #0A1B2D, gold #D8B75A, ivory #F7F4EE, cardDark #18334B}`, `buildLightTheme()`, `buildDarkTheme()`, `buildAmoledTheme()` returning ThemeData (Almarai family, 48dp touch targets, 16–24 radii), `SettingsStore.themeMode` (Task 3 may own storage; Task 2 reads/writes the same key — coordinate exact key `themeMode`).

- [ ] **Step 1: Write failing test** `test/theme_test.dart`: all three builders return ThemeData with brightnesses light/dark/dark, scaffold colors ivory / navy-ish / black, fontFamily Almarai, distinct surfaces; contrast smoke (onSurface differs from surface).
- [ ] **Step 2: Run.** Run: `flutter test test/theme_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** tokens + builders; AMOLED scaffold/surface pure black; wire `GetMaterialApp(theme/darkTheme/themeMode)` in main.
- [ ] **Step 4: Run.** Run: `flutter test test/theme_test.dart`. Expected: PASS (deferred, no SDK).
- [ ] **Step 5: Widget test** home renders in each mode without overflow at textScale 1.0 and 1.3 (Arabic sample string).
- [ ] **Step 6: Commit.** `git add lib/design lib/main.dart test/theme_test.dart && git commit -m "feat: add navy/gold design system with light dark amoled"`

### Task 3: Data layer — stable ids, repository, settings/progress stores, migration

**Files:**
- Create: `lib/data/models/dhikr.dart`, `lib/data/models/category.dart`
- Create: `lib/data/repositories/azkar_repository.dart`
- Create: `lib/data/prefs/settings_store.dart`, `lib/data/prefs/progress_store.dart`
- Test: `test/azkar_repository_test.dart`, `test/migration_test.dart`

**Interfaces:**
- Consumes: `AllAzkar`, `NightOrMorning` maps verbatim.
- Produces: `DhikrItem{id, categoryId, arabicText, repeatTotal, virtue, source nullable, needsReview}`, `AzkarRepository.categories()`, `items(categoryId)`, `SettingsStore{themeMode, textScale, haptics, sound, reminderMorning, reminderEvening}`, `ProgressStore{remaining(itemId), completeTap(itemId), isBookmarked, toggleBookmark, tasbeehSessions}`. Stable id = ` Joyce `${categoryKey}:${index}`` (e.g. `morning:04`); never positional ints across versions.

- [ ] **Step 1: Write failing tests**: repository exposes ≥9 categories (morning, evening, sleep, wakeup, wodu, mosque, azan, afterPrayer, friday, quranDuaa, sunaaDuaa); every item keeps exact `repeat` from source maps; ids unique/stable across two builds; migration test feeds v1 storage (`theme:'light'`, `blesses` list) → stores upgrade without loss/crash; corrupt import returns error, never throws.
- [ ] **Step 2: Run.** Run: `flutter test test/azkar_repository_test.dart test/migration_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** models + repository (read-only mapping, no text edits) + stores on GetStorage (new keys namespaced `v2.*`, old `theme`/`blesses` read+migrated once).
- [ ] **Step 4: Run.** Run: `flutter test`. Expected: PASS (deferred).
- [ ] **Step 5: Commit.** `git add lib/data test/azkar* test/migration* && git commit -m "feat: add id-stable azkar repository and stores with migration"`

### Task 4: Navigation shell + Home dashboard

**Files:**
- Modify: `lib/main.dart`, `lib/pages/HomePage.dart`
- Create: `lib/pages/library_page.dart` (skeleton over existing duas), `lib/pages/settings_page.dart` (or reuse AboutUsPage → extend)
- Test: `test/home_test.dart`

**Interfaces:**
- Consumes: Task 2 themes, Task 3 repository/stores.
- Produces: 4-destination Get bottom nav (Home/Adhkar/Tasbeeh/Library) + Settings route; Home shows greeting, routine card + progress (Task 1 logic), shortcuts (morning/evening/sleep/wakeup), recent/bookmarks, tasbeeh shortcut.

- [ ] **Step 1: Write failing widget test** `test/home_test.dart`: pumps app, finds greeting, 4 category shortcuts, routine progress, tasbeeh button; RTL directionality; taps morning shortcut → AzkarPage with morning items.
- [ ] **Step 2: Run.** Run: `flutter test test/home_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** shell + dashboard using components from Task 2; delete duplicated theme maps in touched files; keep existing route ids stable.
- [ ] **Step 4: Run.** Run: `flutter test test/home_test.dart`. Expected: PASS (deferred).
- [ ] **Step 5: Commit.** `git add lib/pages lib/main.dart test/home_test.dart && git commit -m "feat: add home dashboard with four-destination nav"`

### Task 5: Adhkar browsing + reading + search + bookmarks

**Files:**
- Modify: `lib/pages/AzkarCategoriesPage.dart`, `lib/pages/AzkarPage.dart`, `lib/components/zikr_item.dart`
- Test: `test/azkar_flow_test.dart`

**Interfaces:**
- Consumes: Tasks 1–3.
- Produces: category list → readable item list with repeat pill, decrement-to-complete, bookmark toggle, copy/share, text-size control, next/prev, distraction-free reading mode, search across arabicText.

- [ ] **Step 1: Write failing widget test**: morning list shows first dhikr + repeat count; tapping decrements and persists (re-pump keeps state); bookmark toggles and appears in Library; search filters; text-size change re-renders without overflow.
- [ ] **Step 2: Run.** Run: `flutter test test/azkar_flow_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** on top of repository/stores; guard `ModalRoute args` null (no `as String` throw — fallback to categories).
- [ ] **Step 4: Run.** Run: `flutter test test/azkar_flow_test.dart`. Expected: PASS (deferred).
- [ ] **Step 5: Commit.** `git commit -m "feat: add adhkar reading with counters bookmarks search"`

### Task 6: Tasbeeh — targets, persistence, history, confirm reset

**Files:**
- Modify: `lib/pages/TasbeehRingPage.dart`
- Create: `lib/data/models/tasbeeh_session.dart` (or inside progress_store)
- Test: `test/tasbeeh_test.dart`

**Interfaces:**
- Consumes: `ProgressStore` (Task 3).
- Produces: big tap target, count/target display, presets 33/100 + custom, dhikr presets, haptic/sound toggles, pause/resume, reset-with-confirm, session history list, survives restart.

- [ ] **Step 1: Write failing tests** (unit + widget): tap increments; reaching target marks complete; reset without confirm does nothing; confirmed reset archives session to history; restart restores active session.
- [ ] **Step 2: Run.** Run: `flutter test test/tasbeeh_test.dart`. Expected: FAIL (mutable `widget.count` removed).
- [ ] **Step 3: Implement**: move count into controller/store state (no mutable widget fields); `Vibration`/`Sound` behind settings flags.
- [ ] **Step 4: Run.** Run: `flutter test test/tasbeeh_test.dart`. Expected: PASS (deferred).
- [ ] **Step 5: Commit.** `git commit -m "feat: rebuild tasbeeh with targets history and confirm"`

### Task 7: Settings + local reminders

**Files:**
- Modify/extend settings page; Create: `lib/data/notifications/reminder_scheduler.dart`
- Test: `test/reminder_test.dart`

**Interfaces:**
- Consumes: `SettingsStore`.
- Produces: `ReminderScheduler.scheduleMorning(TimeOfDay)`, `.scheduleEvening(TimeOfDay)`, `.cancelAll()`, reschedule-on-change; permission status surfaced; no spam (max 2 daily).

- [ ] **Step 1: Write failing tests**: setting times persists; scheduler called with exact times; disable cancels; timezone-mock reschedules without duplicates.
- [ ] **Step 2: Run.** Run: `flutter test test/reminder_test.dart`. Expected: FAIL (plugin absent).
- [ ] **Step 3: Implement**: add `flutter_local_notifications`, permission flow, Android channel, exact-vs-inexact documented; settings groups (theme/font/reading/notifications/haptics/data/export/import/about).
- [ ] **Step 4: Run.** Run: `flutter test test/reminder_test.dart`. Expected: PASS (deferred; manual device check for exact timing + battery-saver note).
- [ ] **Step 5: Commit.** `git commit -m "feat: add settings and morning evening reminders"`

### Task 8: QA + release docs

**Files:** `docs/TESTING.md`, `docs/RELEASE.md`, `docs/DESIGN_SYSTEM.md`, `docs/ARCHITECTURE.md`
**Test:** full suite + manual matrix (RTL, 1.3x text, small/large screens, offline, upgrade from v1 data, Android+iOS reminders).

- [ ] **Step 1: Run** `flutter analyze`, `flutter test`, `flutter build apk --release` (or ios). Record outputs verbatim in docs. Expected: zero errors (deferred — no SDK here).
- [ ] **Step 2: Fix** regressions found; re-run affected tests only.
- [ ] **Step 3: Commit docs.** `git commit -m "docs: add testing release design architecture notes"`

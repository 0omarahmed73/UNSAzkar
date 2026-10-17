# Final Polish, Bug Fixes & Rebranding — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebrand to أُنس | UNS, fix post-onboarding location, notifications, haptics, verify on emulator, ship fresh APKs.

**Architecture:** No framework changes. Additive fixes in existing stores/pages; new `test_notification` helper in ReminderService; map/location entry unified in one place.

**Tech Stack:** Flutter 3.47.7 / Dart 3.13.5; existing deps only unless a missing capability forces one (document first).

**Spec:** Conversation brief 2026-10-17 (9 sections). Design refs: `docs/prototype/*.png`; icon assets `assets/icon-source/*.svg` (user-supplied; do NOT redraw).

## Global Constraints

- Preserve working functionality and user data; keep package/bundle IDs.
- Never invent religious text, sources, timings, or store availability.
- No fake buttons; no test-pass claims without execution; no device claims without emulator evidence.
- Do NOT claim Play/App Store name availability (never checked).
- Launcher labels must fit without truncation (verify on emulator).

## Review Focus

- Rebrand completeness: every user-visible old name replaced, no stale route/title.
- Location change AFTER onboarding offers all three methods and refreshes prayer times.
- Notifications: permission asked once with Arabic reason; scheduled for real future times; no dupes.
- Haptics fire only on intended taps when enabled; silent otherwise.
- Backup still covers everything incl. new prefs keys.

---
### Task 1: Rebrand to أُنس | UNS + tagline
**Files:** grep for `أذكار المسلم|azkar_new_app title|رفيق` in lib/, android/, ios/, web/. Modify: app bar title, manifest `android:label`, iOS bundle name, web title, README/docs, home greeting where natural. Keep package ID, keys, routes.
- [ ] **Step 1: Inventory** all user-visible name occurrences (grep), list in ledger.
- [ ] **Step 2: Write failing test** — e.g. home title reads أُنس; settings about shows UNS; manifest label check is manual (note it).
- [ ] **Step 3: Run** — Expected: FAIL (old name).
- [ ] **Step 4: Implement** renames (no logo changes; launcher art already integrated).
- [ ] **Step 5: Run full suite** — Expected: PASS.
- [ ] **Step 6: Verify on emulator** (launcher label, home title).
- [ ] **Step 7: Commit** — `git commit -m "feat: rebrand to أُنس | UNS (رفيق يومك)"`.

### Task 2: Location after onboarding (GPS + map + manual everywhere)
**Files:** Modify: `lib/pages/PrayerTimesPage.dart` (unify location-change UI for no-location AND has-location states).
- [ ] **Step 1: Reproduce** — widget test: with saved location, tap change → GPS + map + city options all present. Expected: FAIL (map button missing when located).
- [ ] **Step 2: Fix** — reuse the SAME picker entry (extract `_LocationPickerSheet` used in both states); persist only on confirm; resync prayers.
- [ ] **Step 3: Run** — Expected: PASS + suite green.
- [ ] **Step 4: Emulator check** — change location via map, confirm times update.
- [ ] **Step 5: Commit** — `git commit -m "fix: all three location methods available after onboarding"`.

### Task 3: Notifications end-to-end (permission, scheduling, delivery)
**Files:** Modify: `lib/data/notifications/reminder_service.dart` (add `scheduleTestNotification`, `pendingCount()` for diagnostics), `lib/pages/SettingsPage.dart` (test-notification button + permission state text), `AndroidManifest.xml` (verify).
- [ ] **Step 1: Audit** — write down the full chain (init → permission → schedule → reschedule triggers) with file:line refs in the ledger.
- [ ] **Step 2: Failing tests** — test-notification schedules a ~60s alarm (mock clock/verify via pending list where testable: assert scheduled id exists via `pendingNotificationRequests` is real plugin — instead assert scheduling path calls with future time; permission-denied path shows guidance text).
- [ ] **Step 3: Run** — Expected: FAIL.
- [ ] **Step 4: Implement** — prompt-on-first-launch already exists; add settings test-notification + resync on boot (main already syncs; verify reboot path documented since no BOOT_COMPLETED receiver — document limitation).
- [ ] **Step 5: Emulator check** — schedule test notification, observe delivery via logcat + notification shade screenshot.
- [ ] **Step 6: Commit** — `git commit -m "feat: test notification + scheduling diagnostics"`.

### Task 4: Haptics root-cause + restore
**Files:** Modify: `lib/data/prefs/settings_store.dart` if needed; `AzkarPage`/`TasbeehRingPage` call sites; `test/haptics_test.dart` (new: mock MethodChannel `SystemChannels.platform` haptic methods, assert called on tap / not called when disabled).
- [ ] **Step 1: Investigate** — trace HapticFeedback → SystemChannels.platform → method channel name; check test binding default mock; read actual failure mode (tests can't feel vibration; assert API invocation).
- [ ] **Step 2: Failing tests** — Expected: FAIL.
- [ ] **Step 3: Implement minimal fix** (guarded calls already exist; likely fix = missing `await`? no — find real cause first).
- [ ] **Step 4: Emulator note** — haptics on emulator may not vibrate; record honestly.
- [ ] **Step 5: Commit**.

### Task 5: Full verification (format, analyze, suite, diff, APKs, emulator)
- [ ] `dart format` (changed files), `flutter analyze` (report errors/warnings/infos separately).
- [ ] Full suite with count + exit code.
- [ ] `git diff --check`, final self-review, fresh debug+release APKs, install on emulator, screenshot checklist (home, quran, azkar, custom azkar, prayer+map, settings, splash), compare vs prototype.
- [ ] Final report with the 9 required items + rulings + deferred minors.

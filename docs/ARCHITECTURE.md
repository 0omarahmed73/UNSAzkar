# Architecture

UI (GetMaterialApp, Get routes, Arabic locale) → Repository (`AzkarRepository` over bundled `AllAzkar`/`NightOrMorning`, read-only) → Stores (`SettingsStore`, `ProgressStore` on GetStorage) → pure logic (`lib/logic/`).

- Singletons registered once in `initAppState()` (`lib/data/app_state.dart`); pages resolve with `Get.find`, never touch `GetStorage` directly (except ThankingAllahPage, which owns the legacy `blesses` key).
- One source of truth per field: theme = `Controller.mode` (runtime) + `v2.themeMode`/`theme` keys (persisted, written together in `Controller.setMode`); text scale/haptics/reminders = `SettingsStore`; counters/bookmarks/tasbeeh = `ProgressStore` keyed by stable dhikr ids.
- Reminders: `ReminderService` (flutter_local_notifications, inexact daily schedule, best-effort — documented in Settings). Null when plugin unavailable → reminder controls disabled, never faked.
- No backend, no auth, no Firebase. Offline-first: all content + state local.

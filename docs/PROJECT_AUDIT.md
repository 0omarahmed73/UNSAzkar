# Project Audit — أذكار المسلم (azkar_new_app)

Date: 2026-10-17. Source: direct inspection (subagents unavailable). No Flutter/Dart toolchain, no git repo.

## 1. Basics
- Package: `azkar_new_app`, version 1.0.0+1, SDK `>=3.3.0 <4.0.0`.
- Platforms present: android/, ios/, linux/, macos/, web/, windows/ (configured target unknown; env is Linux, no Flutter SDK).
- Entry: `lib/main.dart` → `AzkarApp` (GetMaterialApp, routes map, initial HomePage).
- Total Dart: ~2594 lines across 23 lib files + 1 broken placeholder test.

## 2. Dependencies (pubspec.yaml)
- `provider: ^6.0.0` (installed but `ThemeNotifier`/`themes.dart` appear unused — dead code).
- `get: ^4.6.6` + `get_storage: ^2.1.1` — actual state + persistence (Controller.mode, blesses, theme string).
- `quran: ^1.2.8`, `hadith: ^1.0.0`, `html: ^0.15.4` — Quran/hadith content (verify usage in PrayersPage/ThankingAllahPage before reuse).
- `cupertino_icons`, `uuid`, `flutter_launcher_icons`, `flutter_native_splash`, `rename_app` (dev tooling, not runtime deps — consider moving to dev_dependencies later).
- No `riverpod`, `go_router`, `drift`, `sqflite`, `shared_preferences`, `flutter_local_notifications`, `intl`/`hijri`.

## 3. Architecture (actual, not assumed)
- Navigation: `GetMaterialApp.routes` map with string ids (`HomePage.id`, `AzkarPage.id`, `TasbeehRingPage.id`, `ThankingAllahPage.id`, `AboutUsPage.id`). No go_router. `AzkarCategoriesPage`, `PrayersPage` exist but routing unclear — check.
- State: `Controller` (GetxController, `mode` obs + GetStorage `theme`) and `AzkarController` (`azkarItems <Map>[].obs`, `decrementRepeat`). No repositories, no separation of UI/business logic.
- Persistence: only `GetStorage` keys `theme`, `blesses`. Counters/bookmarks/progress do NOT persist across restarts (except blesses list).
- Theming: inline `Map theme` rebuilt per page in `main.dart`, `AzkarPage`, `TasbeehRingPage` (duplicated light/dark maps, no ThemeData, no AMOLED, no text-scale). `themes.dart`/`theme_notifier.dart` unused.
- Data: `services/AllAzkar.dart` (294 lines: sleep, wodu, mosque, azan, gomaaSunn?, afterPrayZekrList, quranDuaa, sunaaDuaa, wakeup) + `services/NightOrMorning.dart` (390 lines: morning/night const lists of `{zekr, repeat, bless}`). Schema: `{zekr: String, repeat: int, bless: String}` — no ids, no source/attribution field, no completed flag. Religious content bundled — PRESERVE, do not rewrite diacritics.
- Models: `BlessModel{id,name,done}` (+toJson/fromJson), `AzkarCategoryModel{name,path}` (6 lines, usage TBD).
- Screens: HomePage (277 lines: HomePage bottom-nav shell + HomeScreen), AzkarPage (157), AzkarCategoriesPage (98), TasbeehRingPage (144 — `widget.count` mutable field, reset without confirm, no target/presets/history/persistence), PrayersPage (201), ThankingAllahPage (398), AboutUsPage (45). Components: custom_card_home, sub_button, zikr_item (140), custom_welcome, categories.
- Fonts: Almarai (Regular/Light/Bold/ExtraBold) + Orbitron-Bold bundled under assets/fonts. No IBM Plex/Noto; Almarai is the Arabic UI font — keep unless licensing/render test forces change.
- RTL: Arabic UI; verify `Directionality`/MaterialApp locale — GetMaterialApp has no locale set (check HomePage for hardcoded RTL rows).

## 4. Tests
- `test/widget_test.dart` is the default counter smoke test referencing non-existent `MyApp` — BROKEN, never passed on this codebase. No unit/widget/integration tests for counters, progress, persistence, migration.

## 5. Risks / tech problems
1. No toolchain in this env → cannot `flutter analyze/test/build`; all verification deferred until SDK available.
2. Not a git repo → no safe baseline; recommend `git init` + initial commit before edits (user approval needed — do not init without asking? Per rules, establish safe baseline; currently impossible).
3. Duplicated theme maps; stringly-typed routing args (`ModalRoute args as String` will throw on missing arg); mutable widget field in Tasbeeh; `print` debug statements; `Map` (dynamic) dhikr items without stable ids — migration to id-based models must preserve user data.
4. Content has no source/attribution fields; spec requires preserving source + flagging missing — do NOT invent attributions.
5. `quran`/`hadith` packages pin old versions; check null-safety/SDK compat before upgrade.

## 6. Preserve / refactor / replace
- Preserve: AllAzkar + NightOrMorning content verbatim; BlessModel data + GetStorage `blesses` key; Almarai fonts; Home/Azkar/Tasbeeh user-facing coverage.
- Refactor: theme → ThemeData + ThemeMode + AMOLED + persisted preference; dhikr maps → stable-id models + repository; Tasbeeh → target/confirm/history/persist; add bookmarks/search/reading settings on top of existing lists.
- Replace/remove: broken widget_test; unused provider ThemeNotifier path (after migration); duplicated inline theme maps; `print`s.
- Do NOT introduce Firebase/auth/backend. Keep Get/GetStorage deliberately (spec allows preserving existing over Riverpod/go_router/Drift unless justified).

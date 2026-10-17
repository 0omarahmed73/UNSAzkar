# Release — verified 2026-10-17 (refinement phase)

Toolchain (kept in the home directory so the app can be rebuilt anytime): Flutter 3.47.7 (stable, `~/sdks/flutter`), Dart 3.13.5 (bundled), Temurin JDK 17.0.20.1 (portable, `~/sdks/jdk17`), Android SDK 36 (`~/Android/Sdk`), Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20, Java 17, desugaring 1.2.2. `flutter doctor`: Android toolchain OK, all licenses accepted. Chrome/Linux-desktop missing (not needed for APK).

Dependency resolutions (minimal targeted bumps; old pins didn't compile): win32 5.5.x, path_provider→2.1.6, flutter_timezone 5.1.1, geolocator 14.0.2 + uuid 4.6.0 (SDK floor 3.3.0→3.5.0), adhan 2.0.0+1, flutter_map 8.x + latlong2, flutter_localizations SDK dep. `flutter pub get` clean.

Builds (from repo root, env vars `PATH`, `JAVA_HOME`, `ANDROID_HOME` set):
- `flutter build apk --debug` → exit 0 → `build/app/outputs/flutter-apk/app-debug.apk` (282 MB, 2026-10-17, final tree).
- `flutter build apk --release` → exit 0 → `build/app/outputs/flutter-apk/app-release.apk` (125 MB, 2026-10-17, final tree; debug-signed per existing `build.gradle`; replace `signingConfig` + `applicationId` before store upload).
- Emulator verification (API 34, KVM): release + debug APKs installed; cold start shows the native splash with the supplied mark on ivory; home/categories/dua/about/tasbeeh/reading/settings/prayer-with-Cairo exercised via taps + screenshots; light/dark/AMOLED all rendered; dark theme persisted across force-stop relaunch; notifications channel + permission flow present (delivery timing subject to OS limits).
- Launcher icon: generated from the user-supplied SVG (`assets/icon-source/`, `tool/make_icons.sh` reproducible) — adaptive icon (ivory bg) + legacy mipmaps + iOS set; installed launcher shows the new mark.

Not performed: physical Samsung device checks (gesture nav, keyboard, haptics feel); exact reminder delivery timing; iOS build (no macOS). Release size is large (all ABIs + bundled content) — consider `--split-per-abi` + `shrinkResources` later.

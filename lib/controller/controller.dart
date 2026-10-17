import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class Controller extends GetxController {
  final GetStorage storage = GetStorage();
  var mode = 'light'.obs;

  static const validModes = {'light', 'dark', 'amoled', 'system'};

  @override
  void onInit() {
    super.onInit();
    mode.value = _sanitize(storage.read('theme'));
  }

  /// Unknown, missing, or legacy values can never boot the app into an
  /// unexpected theme: anything unrecognized falls back to light.
  /// (`system` is stored in `v2.themeMode` only; see [setMode].)
  static String _sanitize(dynamic stored) =>
      stored == 'dark' || stored == 'amoled' ? stored as String : 'light';

  /// Restores the persisted v2 mode (incl. `system`) after a restart.
  /// Must be called once at startup before first frame renders.
  void restore() {
    final stored = storage.read('v2.themeMode');
    if (stored is String && validModes.contains(stored)) {
      mode.value = stored;
    }
  }

  void toggleMode() {
    mode.value = mode.value == 'dark' ? 'light' : 'dark';
    storage.write('theme', mode.value);
  }

  /// Sets any of the three P0 modes explicitly (`light|dark|amoled`).
  /// Persists to both the v1 `theme` key and the v2 `v2.themeMode` key so
  /// [SettingsStore] and legacy readers stay consistent.
  void setMode(String value) {
    assert(validModes.contains(value));
    mode.value = value;
    // v1 readers only know light/dark: map amoled→dark, system→light.
    storage.write('theme',
        value == 'amoled' ? 'dark' : (value == 'system' ? 'light' : value));
    storage.write('v2.themeMode', value);
  }

  /// Cycles light → dark → system → light (quick app-bar toggle).
  /// AMOLED remains available from Settings only to avoid accidental mode
  /// switches that dramatically alter the agreed visual style.
  void cycleMode() {
    if (mode.value == 'light') {
      setMode('dark');
    } else if (mode.value == 'dark') {
      setMode('system');
    } else {
      setMode('light');
    }
  }
}

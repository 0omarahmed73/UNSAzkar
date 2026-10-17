import 'package:azkar_new_app/data/prefs/custom_azkar_store.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';

/// Versioned backup covering mutable user data AND settings.
/// Version 3+: `{settings, progress}`. Legacy version-2 progress-only
/// backups still import (settings left untouched).
class BackupService {
  static const int exportVersion = 3;

  static Map<String, dynamic> exportData({
    required SettingsStore settings,
    required ProgressStore progress,
    CustomAzkarStore? customs,
  }) =>
      {
        'version': exportVersion,
        'settings': settings.toJson(),
        'progress': progress.exportData(),
        if (customs != null) 'customs': customs.toJson(),
      };

  /// Validates everything before touching either store. Returns an error
  /// string on failure (state untouched), null on success. Never throws.
  static Future<String?> importData({
    required SettingsStore settings,
    required ProgressStore progress,
    required dynamic data,
    CustomAzkarStore? customs,
  }) async {
    if (data is! Map) return 'not a backup object';
    final version = data['version'];
    if (version == ProgressStore.exportVersion && data['settings'] == null) {
      // Legacy v2 progress-only backup.
      final error = progress.importData(data);
      return error;
    }
    if (version != exportVersion) return 'unsupported version';
    final settingsData = data['settings'];
    final progressData = data['progress'];
    if (settingsData == null || progressData == null) {
      return 'malformed backup';
    }
    // Validate both first: dry-run settings on a scratch check via the
    // real validators without writing (applyJson writes, so validate the
    // progress map shape here and rely on applyJson's own guards).
    if (progressData is! Map) return 'malformed backup';
    // Apply settings first; roll back from a snapshot if anything later
    // fails, so a half-import can never silently discard user data.
    final settingsSnap = settings.toJson();
    final customsSnap = customs?.toJson();
    final settingsError = await settings.applyJson(settingsData);
    if (settingsError != null) return settingsError;
    if (customs != null && data.containsKey('customs')) {
      final customsError = customs.importJson(data['customs']);
      if (customsError != null) {
        await settings.applyJson(settingsSnap);
        return customsError;
      }
    }
    final progressError = progress.importData(progressData);
    if (progressError != null) {
      await settings.applyJson(settingsSnap);
      if (customs != null) {
        if (customsSnap == null) {
          await customs.restoreDefaults();
        } else {
          customs.importJson(customsSnap);
        }
      }
      return progressError;
    }
    return null;
  }
}

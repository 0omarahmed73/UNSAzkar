import 'package:azkar_new_app/data/prefs/custom_azkar_store.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/data/repositories/azkar_repository.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Registers the P0 app-wide singletons exactly once.
///
/// Called from `main()` after `GetStorage.init()`. Pages resolve these with
/// `Get.find` instead of touching `GetStorage` directly.
void initAppState(GetStorage box) {
  if (!Get.isRegistered<CustomAzkarStore>()) {
    Get.put(CustomAzkarStore(box)..load());
  }
  if (!Get.isRegistered<AzkarRepository>()) {
    Get.put(AzkarRepository(
        customs: Get.isRegistered<CustomAzkarStore>()
            ? Get.find<CustomAzkarStore>()
            : null));
  }
  if (!Get.isRegistered<SettingsStore>()) {
    Get.put(SettingsStore(box)..load());
  }
  if (!Get.isRegistered<ProgressStore>()) {
    Get.put(ProgressStore(box)..load());
  }
}

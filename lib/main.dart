import 'dart:async';

import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/app_state.dart';
import 'package:azkar_new_app/data/notifications/reminder_service.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/design/app_theme.dart';
import 'package:azkar_new_app/pages/PrayerTimesPage.dart';
import 'package:azkar_new_app/pages/SettingsPage.dart';
import 'package:azkar_new_app/models/bless_model.dart';
import 'package:azkar_new_app/pages/AboutUsPage.dart';
import 'package:azkar_new_app/pages/AzkarPage.dart';
import 'package:azkar_new_app/pages/CustomAzkarPage.dart';
import 'package:azkar_new_app/pages/HomePage.dart';
import 'package:azkar_new_app/pages/SplashPage.dart';
import 'package:azkar_new_app/pages/TasbeehRingPage.dart';
import 'package:azkar_new_app/pages/ThankingAllahPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await GetStorage.init(); // Initialize get_storage
  final GetStorage storage = GetStorage();

  List<BlessModel> defaultBlesses = [
    BlessModel(name: "سمعي", done: false, id: 0),
    BlessModel(name: "بصري", done: false, id: 1),
    BlessModel(name: "لساني", done: false, id: 2),
    BlessModel(name: "ديني", done: false, id: 3),
    BlessModel(name: "أهلي", done: false, id: 4),
    BlessModel(name: "العلم", done: false, id: 5),
    BlessModel(name: "الإسلام", done: false, id: 6),
    BlessModel(name: "الهداية", done: false, id: 7),
  ];

  // Check if 'blesses' data exists in storage
  if (!storage.hasData('blesses')) {
    // Save the default blesses to storage
    storage.write('blesses', defaultBlesses.map((e) => e.toJson()).toList());
  }

  initAppState(storage);

  // Register the theme controller early and restore the persisted mode
  // BEFORE the first frame so the app never flashes a wrong theme.
  Get.put(Controller()).restore();

  // Local reminders (best-effort). Initialized AFTER the first frame so
  // plugin/timezone setup never delays startup; a null service disables
  // reminder controls in Settings instead of faking them.
  unawaited(initReminders());

  runApp(const AzkarApp());
}

/// Reminder plugin setup. Never throws: failures leave
/// [ReminderService.current] null and the UI adapts. Safe to call twice.
Future<void> initReminders() async {
  try {
    ReminderService.current = await ReminderService.create();
    final settings = Get.find<SettingsStore>();
    await ReminderService.current!.syncFromSettings(settings);
    await ReminderService.current!.syncPrayerFromSettings(settings);
  } catch (_) {
    ReminderService.current = null;
  }
}

class AzkarApp extends StatelessWidget {
  const AzkarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<Controller>();
    return Obx(() {
      final mode = controller.mode.value;
      return GetMaterialApp(
        routes: {
          HomePage.id: (context) => HomePage(),
          AzkarPage.id: (context) => AzkarPage(),
          TasbeehRingPage.id: (context) => TasbeehRingPage(),
          ThankingAllahPage.id: (context) => ThankingAllahPage(),
          CustomAzkarPage.id: (_) => const CustomAzkarPage(),
          CustomAzkarEditorPage.id: (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            return CustomAzkarEditorPage(
                existingId: args is String ? args : null);
          },
          PrayerTimesPage.id: (context) => const PrayerTimesPage(),
          SettingsPage.id: (context) => const SettingsPage(),
          AboutUsPage.id: (context) => const AboutUsPage(),
          SplashPage.id: (context) => const SplashPage(),
        },
        initialRoute: SplashPage.id,
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildLightTheme(),
        darkTheme: mode == 'amoled' ? buildAmoledTheme() : buildDarkTheme(),
        themeMode: mode == 'light'
            ? ThemeMode.light
            : (mode == 'system' ? ThemeMode.system : ThemeMode.dark),
      );
    });
  }
}

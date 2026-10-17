import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dismisses the first-launch notification prompt if present.
/// HomeScreen shows it once per fresh box; tests that pump HomeScreen must
/// clear it before interacting, exactly like a real user would.
Future<void> dismissNotifPrompt(WidgetTester t) async {
  await t.pumpAndSettle();
  if (find.text('تفعيل التذكير اليومي؟').evaluate().isNotEmpty) {
    await t.tap(find.text('لاحقًا'));
    await t.pumpAndSettle();
  }
}

/// Drags the outer [ListView] until [finder] is built and visible.
/// ListView builds lazily and random-length content (verse/hadith) shifts
/// positions run to run, so fixed drag counts are flaky.
Future<void> dragIntoView(WidgetTester t, Finder finder,
    {int maxDrags = 8, bool useLastScrollable = false}) async {
  final scrollable = useLastScrollable
      ? find.byType(ListView).last
      : find.byType(ListView).first;
  for (var i = 0; i < maxDrags && finder.evaluate().isEmpty; i++) {
    await t.drag(scrollable, const Offset(0, -500));
    await t.pumpAndSettle();
  }
}

/// Each call creates a fresh temp dir, keeping test files isolated.
///
/// NOTE: install BEFORE any `GetStorage.init()` — inside `testWidgets`
/// (FakeAsync zone) an unmocked channel hang is possible instead of the
/// usual fast MissingPluginException.
Future<Directory> mockPathProvider() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = await Directory.systemTemp.createTemp('azkar_test_');
  const channels = [
    'plugins.flutter.io/path_provider',
    'flutter_native_splash',
  ];
  for (final name in channels) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel(name), (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return dir.path;
      }
      return null;
    });
  }
  // Geolocator reports a disabled service: deterministic, no hangs, and it
  // exercises the service-disabled explanation path in every widget test.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/geolocator'), (call) async {
    if (call.method == 'isLocationServiceEnabled') return false;
    if (call.method == 'checkPermission') return 0; // denied
    return null;
  });
  return dir;
}

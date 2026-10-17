import 'package:azkar_new_app/controller/controller.dart';
import 'package:azkar_new_app/data/app_state.dart';
import 'package:azkar_new_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_helpers.dart';

void main() {
  // Fixture I/O in real async (see home_test.dart): never inside bodies.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await mockPathProvider();
  });

  setUp(() async {
    await GetStorage.init();
    Get.reset();
    initAppState(GetStorage());
    Get.put(Controller());
  });

  testWidgets('app boots into branded splash', (tester) async {
    await tester.pumpWidget(const AzkarApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('أُنس'), findsWidgets);
    expect(find.text('رفيق يومك'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

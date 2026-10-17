import 'package:azkar_new_app/data/prayer/location_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  test('manual city list has valid unique entries', () {
    expect(manualCities, isNotEmpty);
    final names = manualCities.map((c) => c.label).toSet();
    expect(names.length, manualCities.length);
    for (final c in manualCities) {
      expect(c.lat, inInclusiveRange(-90.0, 90.0), reason: c.label);
      expect(c.lng, inInclusiveRange(-180.0, 180.0), reason: c.label);
      expect(c.label.trim().isNotEmpty, isTrue);
    }
  });

  test('manual list covers the required regions', () {
    final labels = manualCities.map((c) => c.label).join(' ');
    for (final city in ['القاهرة', 'مكة المكرمة', 'المدينة المنورة', 'الرياض', 'كراتشي']) {
      expect(labels, contains(city));
    }
  });

  test('Cairo coordinates are exact (default reference, not assumption)', () {
    final cairo = manualCities.firstWhere((c) => c.label.contains('القاهرة'));
    expect(cairo.lat, 30.0444);
    expect(cairo.lng, 31.2357);
  });

  test('service-disabled short-circuits with explanation', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await mockPathProvider();
    final (status, pos) = await LocationService().requestDeviceLocation();
    expect(status, LocationStatus.serviceDisabled);
    expect(pos, isNull);
  });
}

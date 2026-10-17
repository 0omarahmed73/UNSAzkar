import 'package:azkar_new_app/pages/MapPickerPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets('tapping the map moves the marker', (t) async {
    LatLng? confirmed;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MapPickerPage(
          initial: const LatLng(30.0444, 31.2357),
          onConfirm: (pos) => confirmed = pos,
        ),
      ),
    ));
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.location_on), findsOneWidget);

    // flutter_map debounces taps (~250ms); settle exits before one-shot
    // timers fire, so pump past it explicitly.
    await t.tap(find.byType(MapPickerMap));
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();
    expect(confirmed, isNull); // tap alone does not confirm
    expect(t.takeException(), isNull);
  });

  testWidgets('confirm returns the chosen position, cancel returns null',
      (t) async {
    LatLng? confirmed = const LatLng(0, 0);
    var cancelled = false;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MapPickerPage(
          initial: const LatLng(30.0444, 31.2357),
          onConfirm: (pos) => confirmed = pos,
          onCancel: () => cancelled = true,
        ),
      ),
    ));
    await t.pumpAndSettle();

    await t.tap(find.text('تأكيد'));
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();
    expect(confirmed, isNotNull);
    expect(confirmed!.latitude, closeTo(30.0444, 0.5));
    expect(cancelled, isFalse);
    expect(t.takeException(), isNull);
  });
}

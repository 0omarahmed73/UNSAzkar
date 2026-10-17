import 'package:azkar_new_app/design/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('brand fade rises in and completes', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(body: BrandFade(child: Text('brand'))),
    ));
    // Starts transparent...
    AnimatedOpacity opacity() =>
        t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first);
    expect(opacity().opacity, 0.0);
    await t.pumpAndSettle();
    expect(opacity().opacity, 1.0);
    expect(find.text('brand'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('reduced motion shows content immediately', (t) async {
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: const MaterialApp(
        home: Scaffold(body: BrandFade(child: Text('brand'))),
      ),
    ));
    await t.pump();
    // No animated wrapper at all — content renders directly.
    expect(find.byType(AnimatedOpacity), findsNothing);
    expect(find.text('brand'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}

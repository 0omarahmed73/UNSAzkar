import 'dart:io';

import 'package:azkar_new_app/design/quran_text.dart';
import 'package:azkar_new_app/design/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bundled data uses Uthmani marks (U+06D6+, U+06E0+, ۞, ۩) that neither
/// Roboto nor Almarai cover — without a Quran font they render as tofu.
void main() {
  testWidgets('verse text uses the bundled Quran font, not fallback',
      (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildLightTheme(),
      home: const Scaffold(
          body: QuranText('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ﴿١﴾')),
    ));
    await t.pumpAndSettle();
    final text = t.widget<Text>(find.textContaining('بِسْمِ'));
    expect(text.style?.fontFamily, 'AmiriQuran');
    expect(text.style?.letterSpacing, isNull);
    expect(t.takeException(), isNull);
  });

  test('Quran font asset and license are bundled', () {
    expect(File('assets/fonts/AmiriQuran-Regular.ttf').existsSync(), isTrue,
        reason: 'font file must be bundled');
    expect(File('assets/fonts/OFL.txt').existsSync(), isTrue,
        reason: 'SIL OFL license must ship with the font');
  });
}

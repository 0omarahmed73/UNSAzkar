import 'package:azkar_new_app/design/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light theme is light on ivory with Almarai', () {
    final t = buildLightTheme();
    expect(t.brightness, Brightness.light);
    expect(t.scaffoldBackgroundColor, const Color(0xFFF7F4EE));
    expect(t.textTheme.bodyLarge?.fontFamily, 'Almarai');
  });

  test('dark theme is dark on navy', () {
    final t = buildDarkTheme();
    expect(t.brightness, Brightness.dark);
    expect(t.scaffoldBackgroundColor, const Color(0xFF0A1B2D));
  });

  test('amoled theme is predominantly black', () {
    final t = buildAmoledTheme();
    expect(t.brightness, Brightness.dark);
    expect(t.scaffoldBackgroundColor, Colors.black);
    expect(t.colorScheme.surface, Colors.black);
  });

  test('onSurface differs from surface in all themes', () {
    for (final t in [buildLightTheme(), buildDarkTheme(), buildAmoledTheme()]) {
      expect(t.colorScheme.onSurface, isNot(t.colorScheme.surface));
    }
  });
}

import 'package:flutter/material.dart';

/// Quranic text rendered in the bundled Amiri Quran font (SIL OFL).
///
/// The bundled mushaf uses Uthmani marks (U+06D6+, U+06E0+, ۞, ۩) that
/// neither Roboto nor Almarai cover — without this widget they render as
/// tofu boxes. Never set letterSpacing here: it breaks Arabic joining.
class QuranText extends StatelessWidget {
  const QuranText(
    this.text, {
    super.key,
    this.fontSize = 20,
    this.textAlign = TextAlign.center,
    this.color,
  });

  final String text;
  final double fontSize;
  final TextAlign textAlign;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textDirection: TextDirection.rtl,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: 'AmiriQuran',
        fontSize: fontSize,
        height: 2.2,
        color: color,
      ),
    );
  }
}

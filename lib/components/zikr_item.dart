import 'package:azkar_new_app/design/components.dart';
import 'package:flutter/material.dart';

/// Single dhikr row in the reading list. New P0 API backed by
/// [DhikrReaderCard]; the legacy Map-based constructor was removed with the
/// [AzkarController]-driven list (state now lives in [ProgressStore]).
class ZikrItem extends StatelessWidget {
  const ZikrItem({
    super.key,
    required this.text,
    required this.remaining,
    required this.total,
    required this.bookmarked,
    required this.textScale,
    required this.virtue,
    required this.onTap,
    required this.onBookmark,
    required this.onCopy,
  });

  final String text;
  final int remaining;
  final int total;
  final bool bookmarked;
  final double textScale;
  final String virtue;
  final VoidCallback onTap;
  final VoidCallback onBookmark;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return BrandFade(
      child: DhikrReaderCard(
        text: text,
        remaining: remaining,
        total: total,
        bookmarked: bookmarked,
        textScale: textScale,
        virtue: virtue,
        onTap: onTap,
        onBookmark: onBookmark,
        onCopy: onCopy,
      ),
    );
  }
}

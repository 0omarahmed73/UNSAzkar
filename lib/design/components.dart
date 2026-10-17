import 'package:flutter/material.dart';
import 'package:azkar_new_app/design/tokens.dart';

/// Reusable P0 components. Everything reads from [Theme.of], never from an
/// inline theme map.

/// Scrollable-screen padding: consistent gutters plus the Android system
/// bottom inset, so the last item stays reachable above gesture navigation.
/// Uses viewPadding (not padding) so transient gesture bars are covered.
EdgeInsets pageInsets(BuildContext context) {
  final bottom = MediaQuery.viewPaddingOf(context).bottom;
  return EdgeInsets.fromLTRB(
    AppSpacing.md,
    AppSpacing.md,
    AppSpacing.md,
    AppSpacing.md + bottom,
  );
}

/// Subtle first-frame entrance: fades + rises content once, then stays.
/// Honors reduced-motion by rendering content directly with no animation.
class BrandFade extends StatefulWidget {
  const BrandFade({super.key, required this.child});

  final Widget child;

  @override
  State<BrandFade> createState() => _BrandFadeState();
}

class _BrandFadeState extends State<BrandFade> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 450),
      opacity: _visible ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 450),
        offset: _visible ? Offset.zero : const Offset(0, 0.04),
        child: widget.child,
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class HomeShortcut extends StatelessWidget {
  const HomeShortcut({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: scheme.primary),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GoldButton extends StatelessWidget {
  const GoldButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(onPressed: onTap, child: Text(label)),
    );
  }
}

/// One dhikr in reading view: tap the card to count one recitation.
/// Shows the repeat pill, a progress bar, and bookmark/copy actions.
class DhikrReaderCard extends StatelessWidget {
  const DhikrReaderCard({
    super.key,
    required this.text,
    required this.remaining,
    required this.total,
    required this.bookmarked,
    required this.textScale,
    required this.onTap,
    required this.onBookmark,
    required this.onCopy,
    this.virtue = '',
  });

  final String text;
  final int remaining;
  final int total;
  final bool bookmarked;
  final double textScale;
  final VoidCallback onTap;
  final VoidCallback onBookmark;
  final VoidCallback onCopy;
  final String virtue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = total - remaining;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 20 * textScale,
                  height: 2.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (virtue.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  virtue,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.8,
                      ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: LinearProgressIndicator(
                  value: total == 0 ? 1 : done / total,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'نسخ',
                        onPressed: onCopy,
                        icon: const Icon(Icons.copy_outlined),
                      ),
                      IconButton(
                        tooltip: bookmarked ? 'إزالة من المحفوظات' : 'حفظ',
                        onPressed: onBookmark,
                        icon: Icon(
                          bookmarked ? Icons.bookmark : Icons.bookmark_border,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: AnimatedSwitcher(
                      duration: reduced
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Text(
                        remaining > 0 ? 'المتبقي $remaining / $total' : 'تم ✓',
                        key: ValueKey(remaining),
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              GoldButton(label: actionLabel!, onTap: onAction!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Confirmation dialog used before destructive actions (tasbeeh reset…).
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  String confirmLabel = 'تأكيد',
  String cancelLabel = 'تراجع',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, textDirection: TextDirection.rtl),
      content: Text(body, textDirection: TextDirection.rtl),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

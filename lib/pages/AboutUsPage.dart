import 'package:azkar_new_app/design/tokens.dart';
import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  static String id = 'AboutUsPage';

  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عن التطبيق'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mosque_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'أُنس | UNS',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              Text(
                'رفيق يومك',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'تم تصميم هذا التطبيق كصدقة جارية عن جميع اموات المسلمين',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'تقبل الله منا ومنكم وجزاكم الله خيراً',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

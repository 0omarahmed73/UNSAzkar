import 'package:azkar_new_app/design/components.dart';
import 'package:azkar_new_app/design/tokens.dart';
import 'package:azkar_new_app/pages/AzkarPage.dart';
import 'package:azkar_new_app/pages/ThankingAllahPage.dart';
import 'package:flutter/material.dart';

class PrayersPage extends StatelessWidget {
  PrayersPage({super.key});

  void _open(BuildContext context, String name) {
    Navigator.of(context).pushNamed(AzkarPage.id, arguments: name);
  }

  void _openThanks(BuildContext context) {
    Navigator.of(context).pushNamed(ThankingAllahPage.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدعاء'), centerTitle: true),
      body: ListView(
        padding: pageInsets(context),
        children: [
          Row(
            children: [
              Expanded(
                child: HomeShortcut(
                  label: 'أدعية قرآنية',
                  icon: Icons.book_outlined,
                  onTap: () => _open(context, 'أدعية قرآنية'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HomeShortcut(
                  label: 'أدعية نبوية',
                  icon: Icons.person_outline,
                  onTap: () => _open(context, 'أدعية نبوية'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          HomeShortcut(
            label: 'شكر النعم',
            icon: Icons.favorite_outline,
            onTap: () => _openThanks(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _InfoCard(
            text: 'قال رسول الله صلى الله عليه وسلم: "الدعاء هو العبادة"',
          ),
          const _InfoCard(
            title: 'شروط إجابة الدعاء ثلاثة:',
            text:
                'الأول: دعاء الله وحده لا شريك له بصدق وإخلاص، لأن الدعاء عبادة.\n'
                'الثاني: ألا يدعو المرء بإثم أو قطيعة رحم، وألا يستعجل\n'
                'الثالث: أن يدعو بقلب حاضر، موقن بالإجابة، ويحسن ظنه بربه',
          ),
          const _InfoCard(
            text:
                'ومن آداب الدعاء: افتتاحه بحمد الله والثناء عليه، والصلاة والسلام على رسول الله صلى الله عليه وسلم، وختمه بذلك، ورفع اليدين، وعدم التردد، بل ينبغي للداعي أن يعزم على الله ويلح عليه، وكذلك تحري أوقات الإجابة كالثلث الأخير من الليل، وبين الأذان والإقامة، وعند الإفطار من الصيام، وغير ذلك .',
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({this.title, required this.text});

  final String? title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title!,
                textDirection: TextDirection.rtl,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              text,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 16, height: 2.0),
            ),
          ],
        ),
      ),
    );
  }
}

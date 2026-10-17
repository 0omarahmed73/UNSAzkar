import 'dart:async';

import 'package:azkar_new_app/data/models/tasbeeh_session.dart';
import 'package:azkar_new_app/data/prefs/progress_store.dart';
import 'package:azkar_new_app/data/prefs/settings_store.dart';
import 'package:azkar_new_app/design/components.dart';
import 'package:azkar_new_app/design/tokens.dart';
import 'package:azkar_new_app/services/haptics_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

const List<String> tasbeehPresets = [
  'سبحان الله',
  'الحمد لله',
  'الله أكبر',
  'لا إله إلا الله',
  'أستغفر الله',
];

const List<int> tasbeehTargets = [33, 100];

class TasbeehRingPage extends StatefulWidget {
  TasbeehRingPage({super.key});
  static String id = 'TasbeehRingPage';

  @override
  State<TasbeehRingPage> createState() => _TasbeehRingPageState();
}

class _TasbeehRingPageState extends State<TasbeehRingPage> {
  ProgressStore get _progress => Get.find<ProgressStore>();
  SettingsStore get _settings => Get.find<SettingsStore>();

  TasbeehSession get _session => _progress.activeTasbeeh!;

  @override
  void initState() {
    super.initState();
    if (_progress.activeTasbeeh == null) {
      _progress.activeTasbeeh = TasbeehSession(
        id: const Uuid().v4(),
        dhikrName: tasbeehPresets.first,
        target: tasbeehTargets.first,
      );
      _progress.saveTasbeeh();
    }
  }

  Future<void> _tap() async {
    if (_settings.haptics) {
      unawaited(HapticsService.instance.lightImpact().catchError((_) {
        // Unsupported device/channel — counting must not fail.
      }));
    }
    setState(() => _session.increment());
    if (_session.isComplete && _settings.haptics) {
      unawaited(HapticsService.instance.heavyImpact().catchError((_) {}));
    }
    await _progress.saveTasbeeh();
  }

  Future<void> _newSession(
      {required String dhikrName, required int target}) async {
    if (_progress.activeTasbeeh != null && _session.count > 0) {
      await _progress.archiveTasbeeh();
    }
    _progress.activeTasbeeh = TasbeehSession(
      id: const Uuid().v4(),
      dhikrName: dhikrName,
      target: target,
    );
    await _progress.saveTasbeeh();
    setState(() {});
  }

  Future<void> _reset() async {
    final ok = await confirmAction(
      context,
      title: 'تصفير العداد؟',
      body: 'سيتم أرشفة الجلسة الحالية (${_session.count}) في السجل.',
      confirmLabel: 'تصفير وأرشفة',
    );
    if (ok) {
      final name = _session.dhikrName;
      final target = _session.target;
      await _progress.archiveTasbeeh();
      _progress.activeTasbeeh = TasbeehSession(
        id: const Uuid().v4(),
        dhikrName: name,
        target: target,
      );
      await _progress.saveTasbeeh();
      setState(() {});
    }
  }

  Future<void> _customTarget() async {
    final controller = TextEditingController(text: _session.target.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('هدف مخصص', textDirection: TextDirection.rtl),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(hintText: 'مثال: 500'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(ctx).pop(int.tryParse(controller.text.trim())),
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
    if (value != null && value > 0) {
      await _newSession(dhikrName: _session.dhikrName, target: value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final history = _progress.tasbeehHistory.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('خاتم التسبيح'), centerTitle: true),
      body: ListView(
        padding: pageInsets(context),
        children: [
          BrandFade(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      _session.dhikrName,
                      textDirection: TextDirection.rtl,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Builder(builder: (context) {
                      final reduced = MediaQuery.disableAnimationsOf(context);
                      return AnimatedSwitcher(
                        duration: reduced
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Text(
                          '${_session.count} / ${_session.target}',
                          key: ValueKey('${_session.count}/${_session.target}'),
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: LinearProgressIndicator(
                        value: _session.target == 0
                            ? 0
                            : (_session.count / _session.target)
                                .clamp(0.0, 1.0),
                        minHeight: 8,
                      ),
                    ),
                    if (_session.isComplete) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'تقبل الله منك 🎉',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: scheme.primary),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Big counting control: 176dp touch target.
                        Material(
                          color: scheme.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _tap,
                            child: const SizedBox(
                              width: 176,
                              height: 176,
                              child: Center(
                                child: Icon(Icons.touch_app_outlined, size: 72),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('تصفير (بتأكيد)'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const AppSectionHeader(title: 'الذكر'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final name in tasbeehPresets)
                ChoiceChip(
                  label: Text(name),
                  selected: _session.dhikrName == name,
                  onSelected: (_) {
                    if (_session.dhikrName != name) {
                      _newSession(dhikrName: name, target: _session.target);
                    }
                  },
                ),
            ],
          ),
          const AppSectionHeader(title: 'الهدف'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in tasbeehTargets)
                ChoiceChip(
                  label: Text('$t'),
                  selected: _session.target == t,
                  onSelected: (_) {
                    if (_session.target != t) {
                      _newSession(dhikrName: _session.dhikrName, target: t);
                    }
                  },
                ),
              ActionChip(
                label: Text(tasbeehTargets.contains(_session.target)
                    ? 'مخصص…'
                    : '${_session.target} (مخصص)'),
                onPressed: _customTarget,
              ),
            ],
          ),
          const AppSectionHeader(title: 'الجلسات السابقة'),
          if (history.isEmpty)
            const Text(
              'لا جلسات بعد — ابدأ التسبيح وستظهر هنا.',
              textDirection: TextDirection.rtl,
            )
          else
            for (final h in history.take(20))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(h.dhikrName, textDirection: TextDirection.rtl),
                subtitle: Text(
                  '${h.count} / ${h.target}',
                  style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()]),
                ),
              ),
        ],
      ),
    );
  }
}

import 'package:azkar_new_app/design/components.dart';
import 'package:azkar_new_app/design/tokens.dart';
import 'package:azkar_new_app/models/bless_model.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

/// Daily blessings journal ("شكر النعم"). Owns the legacy `blesses`
/// GetStorage key: list of {id, name, done}. Behavior preserved from v1 —
/// `done` flags reset when the page is opened; entries persist across
/// restarts and upgrades.
class ThankingAllahPage extends StatefulWidget {
  ThankingAllahPage({super.key});
  static String id = 'ThankingAllahPage';

  @override
  State<ThankingAllahPage> createState() => _ThankingAllahPageState();
}

class _ThankingAllahPageState extends State<ThankingAllahPage> {
  List<BlessModel> blesses = [];

  @override
  void initState() {
    super.initState();
    loadBlesses();
    // v1 behavior: daily review starts unchecked.
    for (final b in blesses) {
      b.done = false;
    }
  }

  void loadBlesses() {
    final GetStorage storage = GetStorage();
    final dynamic storedData = storage.read('blesses');
    if (storedData != null) {
      blesses = (storedData as List)
          .map((e) => BlessModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
  }

  void saveBlesses() {
    final GetStorage storage = GetStorage();
    List<Map<String, dynamic>> blessesToStore =
        blesses.map((e) => e.toJson()).toList();
    storage.write('blesses', blessesToStore);
  }

  void saveBless(BlessModel bless) {
    setState(() {
      // Generate a unique ID for the new bless
      bless.id = generateUniqueId();
      blesses.add(bless); // Add the new bless to the list
      saveBlesses();
    });
  }

  num generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  void removeBless(BlessModel bless) {
    setState(() {
      blesses.remove(bless);
      saveBlesses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('شكر النعم'), centerTitle: true),
      body: ListView(
        padding: pageInsets(context),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'كان بعض السلف يسمي (الشكر): الحافظ الجالب؛ لأنه يحفظ النعم الموجودة، ويجلب النعم المفقودة',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, height: 1.9),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => _BlessDialog(
                          onSave: saveBless,
                          nextId: blesses.length,
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (blesses.isEmpty)
                    Text(
                      'لا نعم مسجلة بعد — أضف أول نعمة تشكر الله عليها.',
                      textDirection: TextDirection.rtl,
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    for (final bless in blesses)
                      _BlessTile(
                        bless: bless,
                        onToggle: () {
                          setState(() => bless.done = !bless.done);
                          saveBlesses();
                        },
                        onRemove: () => removeBless(bless),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlessTile extends StatelessWidget {
  const _BlessTile({
    required this.bless,
    required this.onToggle,
    required this.onRemove,
  });

  final BlessModel bless;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: ListTile(
          title: Text(
            bless.name,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: bless.done ? TextDecoration.lineThrough : null,
            ),
          ),
          trailing: Icon(
            bless.done ? Icons.check_circle : Icons.check_circle_outline,
            color: scheme.primary,
          ),
          leading: IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.delete_outline),
            onPressed: onRemove,
          ),
          onTap: onToggle,
        ),
      ),
    );
  }
}

class _BlessDialog extends StatefulWidget {
  const _BlessDialog({required this.onSave, required this.nextId});

  final Function(BlessModel) onSave;
  final int nextId;

  @override
  State<_BlessDialog> createState() => _BlessDialogState();
}

class _BlessDialogState extends State<_BlessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة نعمة جديدة', textAlign: TextAlign.end),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          textDirection: TextDirection.rtl,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'الرجاء التأكد من ملأ الخانة';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('تراجع'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(BlessModel(
                id: widget.nextId,
                name: _nameController.text,
                done: false,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}

import 'package:azkar_new_app/data/prefs/custom_azkar_store.dart';
import 'package:azkar_new_app/design/components.dart';
import 'package:azkar_new_app/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// «إدارة الأذكار»: the user's own collection. Create, edit, delete
/// (with confirmation), reorder, and restore built-in defaults.
class CustomAzkarPage extends StatefulWidget {
  static String id = 'CustomAzkarPage';
  const CustomAzkarPage({super.key});

  @override
  State<CustomAzkarPage> createState() => _CustomAzkarPageState();
}

class _CustomAzkarPageState extends State<CustomAzkarPage> {
  CustomAzkarStore get _store => Get.find<CustomAzkarStore>();

  Future<void> _openEditor({String? existingId}) async {
    final changed = await Navigator.pushNamed(
      context,
      CustomAzkarEditorPage.id,
      arguments: existingId,
    );
    if (changed == true && mounted) setState(() {});
  }

  Future<void> _confirmDelete(CustomDhikr item) async {
    final ok = await confirmAction(
      context,
      title: 'حذف هذا الذكر؟',
      body: 'سيتم حذف «${item.arabicText}» نهائيًا من مجموعتك.',
      confirmLabel: 'حذف',
    );
    if (ok) {
      await _store.remove(item.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _restoreDefaults() async {
    final ok = await confirmAction(
      context,
      title: 'استعادة الافتراضي؟',
      body: 'سيتم حذف جميع الأذكار المخصصة. لا يمكن التراجع.',
      confirmLabel: 'استعادة',
    );
    if (ok) {
      await _store.restoreDefaults();
      if (mounted) setState(() {});
    }
  }

  String _assignmentLabel(CustomDhikr item) {
    final parts = <String>[];
    if (item.categories.contains('morning')) parts.add('الصباح');
    if (item.categories.contains('evening')) parts.add('المساء');
    if (parts.isEmpty) return 'مجموعتي فقط';
    return parts.join('، ');
  }

  @override
  Widget build(BuildContext context) {
    final items = _store.customs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأذكار'),
        centerTitle: true,
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'استعادة الافتراضي',
              onPressed: _restoreDefaults,
              icon: const Icon(Icons.restore_outlined),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'إضافة ذكر',
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة ذكر'),
      ),
      body: items.isEmpty
          ? const AppEmptyState(
              icon: Icons.edit_note_outlined,
              title: 'لا توجد أذكار مخصصة بعد',
              subtitle: 'أضف ذكرك الخاص واختر الفئة والتكرار المناسبين.',
            )
          : ReorderableListView.builder(
              padding: pageInsets(context),
              itemCount: items.length,
              onReorder: (oldIndex, newIndex) async {
                final ids = items.map((e) => e.id).toList();
                if (newIndex > oldIndex) newIndex -= 1;
                final moved = ids.removeAt(oldIndex);
                ids.insert(newIndex, moved);
                await _store.reorder(ids);
                if (mounted) setState(() {});
              },
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  key: ValueKey(item.id),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    title: Text(item.arabicText,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        'التكرار: ${item.repeatTotal} • ${_assignmentLabel(item)}',
                        textDirection: TextDirection.rtl),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'تعديل',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _openEditor(existingId: item.id),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Editor for one custom dhikr (create when [existingId] is null).
class CustomAzkarEditorPage extends StatefulWidget {
  static String id = 'CustomAzkarEditorPage';
  const CustomAzkarEditorPage({super.key, this.existingId});

  final String? existingId;

  @override
  State<CustomAzkarEditorPage> createState() => _CustomAzkarEditorPageState();
}

class _CustomAzkarEditorPageState extends State<CustomAzkarEditorPage> {
  CustomAzkarStore get _store => Get.find<CustomAzkarStore>();

  late final TextEditingController _textController;
  late final TextEditingController _virtueController;
  late int _repeat;
  late Set<String> _cats;
  String? _error;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    CustomDhikr? existing;
    for (final e in _store.customs) {
      if (e.id == widget.existingId) existing = e;
    }
    _textController = TextEditingController(text: existing?.arabicText ?? '');
    _virtueController = TextEditingController(text: existing?.virtue ?? '');
    _repeat = existing?.repeatTotal ?? 1;
    _cats =
        existing == null ? {'morning'} : Set<String>.from(existing.categories);
  }

  @override
  void dispose() {
    _textController.dispose();
    _virtueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'اكتب نص الذكر أولاً');
      return;
    }
    if (_cats.isEmpty) {
      setState(() => _error = 'اختر فئة واحدة على الأقل');
      return;
    }
    if (widget.existingId == null) {
      final created = await _store.add(
        text: text,
        repeat: _repeat,
        virtue: _virtueController.text,
        categories: _cats.toList(),
      );
      if (created == null) {
        if (!mounted) return;
        setState(() => _error = 'تعذر الحفظ — تحقق من المدخلات');
        return;
      }
    } else {
      final ok = await _store.update(
        widget.existingId!,
        text: text,
        repeat: _repeat,
        virtue: _virtueController.text,
        categories: _cats.toList(),
      );
      if (!ok) {
        if (!mounted) return;
        setState(() => _error = 'تعذر الحفظ — تحقق من المدخلات');
        return;
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  void _bump(int delta) {
    setState(() {
      _repeat = (_repeat + delta).clamp(1, CustomAzkarStore.maxRepeat);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingId == null ? 'ذكر جديد' : 'تعديل الذكر'),
        centerTitle: true,
      ),
      body: ListView(
        padding: pageInsets(context),
        children: [
          TextField(
            key: const ValueKey('customText'),
            controller: _textController,
            textDirection: TextDirection.rtl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'نص الذكر',
              hintText: 'اكتب نص الذكر هنا',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _virtueController,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'الفضل (اختياري)',
              hintText: 'مثال: فضل عظيم',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('التكرار', textDirection: TextDirection.rtl),
              Row(
                children: [
                  IconButton(
                    tooltip: 'تقليل التكرار',
                    onPressed: _repeat > 1 ? () => _bump(-1) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      '$_repeat',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'زيادة التكرار',
                    onPressed: _repeat < CustomAzkarStore.maxRepeat
                        ? () => _bump(1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              FilterChip(
                label: const Text('أذكار الصباح'),
                selected: _cats.contains('morning'),
                onSelected: (v) => setState(() {
                  v ? _cats.add('morning') : _cats.remove('morning');
                }),
              ),
              FilterChip(
                label: const Text('أذكار المساء'),
                selected: _cats.contains('evening'),
                onSelected: (v) => setState(() {
                  v ? _cats.add('evening') : _cats.remove('evening');
                }),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'يظهر الذكر تلقائيًا في «أذكاري المخصصة» أيضًا.',
              textDirection: TextDirection.rtl,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                _error!,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          GoldButton(label: 'حفظ', onTap: _save),
        ],
      ),
    );
  }
}

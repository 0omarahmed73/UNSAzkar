import 'package:azkar_new_app/data/repositories/azkar_repository.dart';
import 'package:azkar_new_app/design/components.dart';
import 'package:azkar_new_app/design/tokens.dart';
import 'package:azkar_new_app/pages/AzkarPage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AzkarCategoriesPage extends StatelessWidget {
  AzkarCategoriesPage({super.key});

  final AzkarRepository _repo = Get.find<AzkarRepository>();

  @override
  Widget build(BuildContext context) {
    final cats = _repo.categories();
    return Scaffold(
      appBar: AppBar(title: const Text('تصنيفات الأذكار'), centerTitle: true),
      body: ListView.builder(
        padding: pageInsets(context),
        itemCount: cats.length,
        itemBuilder: (context, index) {
          final cat = cats[index];
          final count = _repo.items(cat.key).length;
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              title: Text(
                cat.name,
                textDirection: TextDirection.rtl,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '$count ذكر',
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.arrow_back_ios, size: 18),
              onTap: () => Navigator.of(context)
                  .pushNamed(AzkarPage.id, arguments: cat.name),
            ),
          );
        },
      ),
    );
  }
}

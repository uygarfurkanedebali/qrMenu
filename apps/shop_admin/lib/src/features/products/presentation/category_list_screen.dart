/// Category Management Screen
/// 
/// Lists categories with drag-and-drop reordering.
/// Allows adding, editing, and deleting categories.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import '../application/categories_provider.dart';
import 'category_edit_screen.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(categoriesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CategoryEditScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found. Add one!'));
          }

          return ReorderableListView.builder(
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) {
              ref
                  .read(categoriesProvider.notifier)
                  .reorderCategories(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                key: ValueKey(category.id),
                leading: category.imageUrl != null
                    ? CircleAvatar(backgroundImage: NetworkImage(category.imageUrl!))
                    : const CircleAvatar(child: Icon(Icons.category)),
                title: Text(category.name),
                subtitle: Text('${category.description ?? ""} (${category.sortOrder})'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoryEditScreen(category: category),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Category?'),
                            content: Text('Are you sure you want to delete "${category.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          await ref.read(categoriesProvider.notifier).deleteCategory(category.id);
                        }
                      },
                    ),
                    const Icon(Icons.drag_handle),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Category Management Screen
///
/// Lists categories with drag-and-drop reordering.
/// Allows adding, editing, and deleting categories.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../application/categories_provider.dart';
import '../../auth/application/auth_provider.dart';
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
          final tenant = ref.watch(currentTenantProvider);
          if (tenant == null) return const Center(child: Text('No tenant selected'));

          // Prepare Display List
          final List<Category> displayList = List.from(categories);

          // Check/Add System Category (ID '0' or Name 'All Products')
          final hasSystem = displayList.any((c) => c.id == '0' || c.name == 'All Products' || c.name == 'Tüm Ürünler');
          
          if (!hasSystem) {
             // Create a virtual system category for display
             final systemCategory = Category(
               id: '0', 
               tenantId: tenant.id,
               name: 'Tüm Ürünler',
               sortOrder: -999, // Ensure it is at top
               imageUrl: tenant.bannerUrl, // Use tenant banner as image
               createdAt: DateTime.now(),
               updatedAt: DateTime.now(),
               description: 'Sistem Kategorisi',
             );
             displayList.insert(0, systemCategory);
          }

          // Sort by sortOrder
          displayList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return ReorderableListView.builder(
            itemCount: displayList.length,
            padding: const EdgeInsets.only(bottom: 80),
            onReorder: (oldIndex, newIndex) {
              // Prevent reordering the System Category (assuming it's at index 0)
              if (oldIndex == 0 || newIndex == 0) {
                 return; 
              }
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              // In a real app we would call provider to save the new order
              // For now we just update the provider locally if it supports it
              ref.read(categoriesProvider.notifier).reorderCategories(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final category = displayList[index];
              // Identify system category
              final isSystemCategory = category.id == '0' || category.name == 'Tüm Ürünler' || category.name == 'All Products';

              return Card(
                key: ValueKey(category.id),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSystemCategory 
                        ? Theme.of(context).primaryColor.withAlpha(25) 
                        : null,
                    backgroundImage: category.imageUrl != null 
                        ? NetworkImage(category.imageUrl!) 
                        : null,
                    child: (category.imageUrl == null) 
                        ? Icon(isSystemCategory ? Icons.apps : Icons.category, color: isSystemCategory ? Theme.of(context).primaryColor : null)
                        : null,
                  ),
                  title: Text(
                    category.name,
                    style: isSystemCategory ? const TextStyle(fontWeight: FontWeight.bold) : null,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit Button
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                           Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CategoryEditScreen(
                                category: category,
                                isSystemCategory: isSystemCategory,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Delete/Lock Button
                      if (isSystemCategory)
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.lock, color: Colors.grey, size: 20),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, ref, category),
                        ),
                      
                      // Drag Handle
                      if (!isSystemCategory)
                         ReorderableDragStartListener(
                           index: index,
                           child: const Icon(Icons.drag_handle),
                         )
                      else
                         const SizedBox(width: 24), // Spacer for system category
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategoriyi Sil?'),
        content: Text('"${category.name}" kategorisini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(categoriesProvider.notifier).deleteCategory(category.id);
    }
  }
}

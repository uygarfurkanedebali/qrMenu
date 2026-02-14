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
          if (tenant == null) return const Center(child: CircularProgressIndicator());

          // 1. Prepare Display List (Merge Real & System Categories)
          final List<Category> displayList = List.from(categories);
          
          // Check if system category exists in DB (tagged with [SYSTEM] in description)
          // If not found, inject ghost category
          final hasSystemCategory = displayList.any((c) => c.description?.contains('[SYSTEM]') ?? false);
          
          if (!hasSystemCategory) {
            displayList.add(Category(
              id: 'all_products',
              tenantId: tenant.id,
              name: 'Tüm Ürünler',
              description: '[SYSTEM] Sistem Kategorisi',
              imageUrl: tenant.bannerUrl,
              sortOrder: -999, // Should be at top initially
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));
          }

          // Sort by sort_order
          displayList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return ReorderableListView.builder(
            itemCount: displayList.length,
            padding: const EdgeInsets.only(bottom: 80),
            onReorder: (oldIndex, newIndex) {
               ref
                  .read(categoriesProvider.notifier)
                  .reorderCategories(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final category = displayList[index];
              // Identify system category by ID or tag
              final isSystemCategory = category.id == 'all_products' || (category.description?.contains('[SYSTEM]') ?? false);

              return ListTile(
                key: ValueKey(category.id),
                leading: CircleAvatar(
                   backgroundColor: isSystemCategory 
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.1) 
                      : null,
                   backgroundImage: category.imageUrl != null 
                      ? NetworkImage(category.imageUrl!) 
                      : null,
                   child: (category.imageUrl == null) 
                      ? (isSystemCategory 
                          ? Icon(Icons.apps, color: Theme.of(context).primaryColor)
                          : const Icon(Icons.category))
                      : null,
                ),
                title: Text(
                  category.name,
                  style: isSystemCategory ? const TextStyle(fontWeight: FontWeight.bold) : null,
                ),
                subtitle: Text(
                  isSystemCategory 
                      ? 'Sistem Kategorisi • Otomatik Yönetilir' 
                      : '${category.description ?? ""} (${category.sortOrder})',
                  style: isSystemCategory ? const TextStyle(fontSize: 12, color: Colors.grey) : null,
                ),
                // Visual cue for system category
                tileColor: isSystemCategory 
                    ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) 
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // EDIT BUTTON (Enabled for all)
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
                    
                    // DELETE BUTTON (Disabled for System Category)
                    if (isSystemCategory)
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).disabledColor),
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sistem kategorisi silinemez.')),
                          );
                        },
                      )
                    else
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
                    
                    // DRAG HANDLE (Enabled for all)
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

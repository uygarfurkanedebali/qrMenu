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
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CategoryEditScreen()));
        },
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (categories) {
          final tenant = ref.watch(currentTenantProvider);
          final bannerUrl = tenant?.bannerUrl;

          return Column(
            children: [
              // SYSTEM CATEGORY: ALL PRODUCTS (Editable but Not Deletable)
              Container(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    backgroundImage: bannerUrl != null
                        ? NetworkImage(bannerUrl)
                        : null,
                    child: bannerUrl == null
                        ? Icon(
                            Icons.apps,
                            color: Theme.of(context).primaryColor,
                          )
                        : null,
                  ),
                  title: const Text(
                    'Tüm Ürünler',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Sistem Kategorisi • Banner Düzenlenebilir',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // EDIT BUTTON (Allowed)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Banner Düzenle',
                        onPressed: () {
                          // Navigate to Edit Screen with a "System Category" flag or ID '0' logic
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CategoryEditScreen(
                                // We don't have a real Category object for "All Products" in the DB usually,
                                // but we can pass a dummy one or handle it in the Edit Screen.
                                // However, based on the prompt, "All Products" might not be a real category in DB.
                                // If it IS a real category with ID '0', we should find it in the list.
                                // But here it is hardcoded.
                                // Let's open Edit Screen with a special mode for Tenant Banner.
                                isSystemCategory: true,
                              ),
                            ),
                          );
                        },
                      ),
                      // DELETE BUTTON (Disabled/Hidden)
                      const SizedBox(width: 48), // Placeholder for alignment
                      Tooltip(
                        message: 'Bu kategori silinemez.',
                        child: Icon(
                          Icons.lock_outline,
                          size: 20,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Same as edit
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const CategoryEditScreen(isSystemCategory: true),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),

              // REAL CATEGORIES (Reorderable)
              Expanded(
                child: categories.isEmpty
                    ? const Center(
                        child: Text(
                          'Henüz başka kategori yok. Eklemek için + butonuna basın.',
                        ),
                      )
                    : ReorderableListView.builder(
                        itemCount: categories.length,
                        padding: const EdgeInsets.only(bottom: 80),
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
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      category.imageUrl!,
                                    ),
                                  )
                                : const CircleAvatar(
                                    child: Icon(Icons.category),
                                  ),
                            title: Text(category.name),
                            subtitle: Text(
                              '${category.description ?? ""} (${category.sortOrder})',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CategoryEditScreen(
                                          category: category,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Category?'),
                                        content: Text(
                                          'Are you sure you want to delete "${category.name}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await ref
                                          .read(categoriesProvider.notifier)
                                          .deleteCategory(category.id);
                                    }
                                  },
                                ),
                                const Icon(Icons.drag_handle),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

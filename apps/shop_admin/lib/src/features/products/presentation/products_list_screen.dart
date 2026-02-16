import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import '../application/products_provider.dart';
import '../application/categories_provider.dart';
import '../../auth/application/auth_provider.dart';
import '../../navigation/admin_menu_drawer.dart';

// Local state for search and filtering
final productSearchProvider = StateProvider.autoDispose<String>((ref) => '');
final selectedCategoryProvider = StateProvider.autoDispose<String?>((ref) => null);

class ProductsListScreen extends ConsumerWidget {
  const ProductsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(currentTenantProvider);
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final searchQuery = ref.watch(productSearchProvider);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);

    // Auth Guard
    if (tenant == null) {
      return const Scaffold(
        body: Center(child: Text('Lütfen giriş yapın.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Off-White Background
      endDrawer: const AdminMenuDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/products/new'),
        backgroundColor: Colors.black,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ürün Ekle', style: TextStyle(color: Colors.white)),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Hata oluştu: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(productsProvider),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
        data: (products) {
          // FILTERING LOGIC
          final filteredProducts = products.where((product) {
            final matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase());
            final matchesCategory = selectedCategoryId == null || product.categoryId == selectedCategoryId;
            return matchesSearch && matchesCategory;
          }).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Silver App Bar with Search & Title
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0,
                centerTitle: false,
                automaticallyImplyLeading: true,
                leading: const BackButton(color: Colors.black),
                title: _SearchAppBarTitle(
                  isSearching: searchQuery.isNotEmpty,
                  onSearchChanged: (val) => ref.read(productSearchProvider.notifier).state = val,
                  onClear: () => ref.read(productSearchProvider.notifier).state = '',
                ),
                actions: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                      tooltip: 'Menüler',
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // 2. Category Chips
              SliverToBoxAdapter(
                child: Container(
                  height: 60,
                  color: Colors.white,
                  child: categoriesAsync.when(
                    data: (categories) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      itemCount: categories.length + 2, // +1 for "Manage", +1 for "All"
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        // 1. Manage Categories Button (First Item)
                        if (index == 0) {
                          return ActionChip(
                            avatar: const Icon(Icons.edit, size: 16, color: Colors.black),
                            label: const Text('Düzenle'),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.grey),
                            onPressed: () => _showCategoryManagementSheet(context, ref),
                          );
                        }

                        // 2. "All" Filter
                        if (index == 1) {
                          final isSelected = selectedCategoryId == null;
                          return ChoiceChip(
                            label: Text('Tümü', style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                            selected: isSelected,
                            onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = null,
                            selectedColor: Colors.black,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                            showCheckmark: false,
                          );
                        }

                        // 3. Actual Categories
                        final category = categories[index - 2]; // Offset by 2
                        final isSelected = selectedCategoryId == category.id;
                        return ChoiceChip(
                          label: Text(category.name, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                          selected: isSelected,
                          onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = category.id,
                          selectedColor: Colors.black,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                          showCheckmark: false,
                        );
                      },
                    ),
                    loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                    error: (_, __) => const SizedBox(),
                  ),
                ),
              ),

              // 3. Product List
              if (filteredProducts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Ürün bulunamadı',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = filteredProducts[index];
                        return _ProductCard(product: product);
                      },
                      childCount: filteredProducts.length,
                    ),
                  ),
                ),
              
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
      ),
    );
  }

  void _showCategoryManagementSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Tam ekran hissi için
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _CategoryManagementSheet(),
    );
  }
}

class _SearchAppBarTitle extends StatefulWidget {
  final bool isSearching;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  const _SearchAppBarTitle({required this.isSearching, required this.onSearchChanged, required this.onClear});

  @override
  State<_SearchAppBarTitle> createState() => _SearchAppBarTitleState();
}

class _SearchAppBarTitleState extends State<_SearchAppBarTitle> {
  bool _active = false;
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (_active || widget.isSearching) {
      return TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Ürün ara...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _controller.clear();
              widget.onClear();
              setState(() => _active = false);
            },
          ),
        ),
        onChanged: widget.onSearchChanged,
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Ürün Yönetimi',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
        ),
        IconButton(
          onPressed: () => setState(() => _active = true),
          icon: const Icon(Icons.search, color: Colors.black),
        ),
      ],
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            image: product.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(product.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: product.imageUrl == null
              ? Icon(Icons.lunch_dining, color: Colors.grey.shade400)
              : null,
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
        ),
        subtitle: Text(
          '${product.price} ₺',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active/Passive Switch
            Switch(
              value: product.isAvailable,
              activeColor: Colors.green,
              onChanged: (val) {
                // Optimistic Update wrapper
                final updated = product.copyWith(isAvailable: val);
                 ref.read(productsProvider.notifier).updateProduct(updated);
              },
            ),
            const SizedBox(width: 8),
             // Edit Button
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.black54),
              onPressed: () => context.go('/products/${product.id}'),
            ),
          ],
        ),
      ),
    );
  }
}


class _CategoryManagementSheet extends ConsumerStatefulWidget {
  const _CategoryManagementSheet();

  @override
  ConsumerState<_CategoryManagementSheet> createState() => _CategoryManagementSheetState();
}

class _CategoryManagementSheetState extends ConsumerState<_CategoryManagementSheet> {
  final _addController = TextEditingController();

  Future<void> _showAddCategoryDialog() async {
    _addController.clear();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Kategori'),
        content: TextField(
          controller: _addController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Kategori Adı',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              final name = _addController.text.trim();
              if (name.isNotEmpty) {
                try {
                  await ref.read(categoriesProvider.notifier).addCategory(name: name);
                  if (context.mounted) Navigator.pop(context); // Close Dialog
                } catch (e) {
                  // Error handling
                }
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Category category) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategoriyi Sil?'),
        content: Text('${category.name} kategorisini silmek istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          TextButton( // Destructive action
            onPressed: () async {
              await ref.read(categoriesProvider.notifier).deleteCategory(category.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Sheet Handle
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kategorilerim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Hata: $err')),
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Center(child: Text('Henüz kategori yok.'));
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ListTile(
                        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: IconButton(
                          onPressed: () => _confirmDelete(category),
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Add Button (Footer)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showAddCategoryDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Kategori Ekle'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

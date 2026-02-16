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

    if (tenant == null) {
      return const Scaffold(body: Center(child: Text('Lütfen giriş yapın.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
              Text('Hata oluştu: $err', style: const TextStyle(color: Colors.black87)),
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
              // 1. SliverAppBar with Search & Magic Wand
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
                  // Magic Wand — Bulk Price
                  IconButton(
                    icon: const Icon(Icons.auto_fix_high, color: Colors.black87),
                    tooltip: 'Toplu Fiyat Güncelle',
                    onPressed: () => _showBulkPriceDialog(context, ref, filteredProducts),
                  ),
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
                      itemCount: categories.length + 2,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return ActionChip(
                            avatar: const Icon(Icons.edit, size: 16, color: Colors.black),
                            label: const Text('Düzenle', style: TextStyle(color: Colors.black87)),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.grey),
                            onPressed: () => _showCategoryManagementSheet(context, ref),
                          );
                        }
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
                        final category = categories[index - 2];
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
                        Text('Ürün bulunamadı', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
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
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _CategoryManagementSheet(),
    );
  }

  void _showBulkPriceDialog(BuildContext context, WidgetRef ref, List<Product> products) {
    showDialog(
      context: context,
      builder: (ctx) => _BulkPriceDialog(products: products),
    );
  }
}

// ═══════════════════════════════════════════════════════
// BULK PRICE DIALOG
// ═══════════════════════════════════════════════════════

class _BulkPriceDialog extends ConsumerStatefulWidget {
  final List<Product> products;
  const _BulkPriceDialog({required this.products});

  @override
  ConsumerState<_BulkPriceDialog> createState() => _BulkPriceDialogState();
}

class _BulkPriceDialogState extends ConsumerState<_BulkPriceDialog> {
  final _percentController = TextEditingController(text: '10');
  double _roundTo = 1.0;
  bool _isApplying = false;

  double _roundPrice(double price, double roundTo) {
    if (roundTo <= 0) return price;
    return (price / roundTo).round() * roundTo;
  }

  Future<void> _apply() async {
    final percent = double.tryParse(_percentController.text.trim());
    if (percent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir yüzde girin')),
      );
      return;
    }

    setState(() => _isApplying = true);

    try {
      final multiplier = 1.0 + (percent / 100.0);
      int updated = 0;

      for (final product in widget.products) {
        final newPrice = _roundPrice(product.price * multiplier, _roundTo);
        final updatedProduct = product.copyWith(price: newPrice);
        await ref.read(productsProvider.notifier).updateProduct(updatedProduct);
        updated++;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$updated ürünün fiyatı güncellendi!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.auto_fix_high, color: Colors.black87),
          SizedBox(width: 8),
          Text('Toplu Fiyat Güncelle', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.products.length} ürüne uygulanacak', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 20),

          // Percentage Input
          const Text('Yüzde Değişim', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 8),
          TextField(
            controller: _percentController,
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Ör: +10 veya -5',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              suffixText: '%',
              suffixStyle: const TextStyle(color: Colors.black54, fontSize: 16),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
            ),
          ),
          const SizedBox(height: 20),

          // Rounding
          const Text('Yuvarla (en yakın)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 8),
          DropdownButtonFormField<double>(
            value: _roundTo,
            style: const TextStyle(color: Colors.black87, fontSize: 15),
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            items: const [
              DropdownMenuItem(value: 0.5, child: Text('0.50 ₺')),
              DropdownMenuItem(value: 1.0, child: Text('1 ₺')),
              DropdownMenuItem(value: 5.0, child: Text('5 ₺')),
              DropdownMenuItem(value: 10.0, child: Text('10 ₺')),
            ],
            onChanged: (v) => setState(() => _roundTo = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isApplying ? null : () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: Colors.black54)),
        ),
        FilledButton.icon(
          onPressed: _isApplying ? null : _apply,
          icon: _isApplying
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check, size: 18),
          label: Text(_isApplying ? 'Uygulanıyor...' : 'Uygula'),
          style: FilledButton.styleFrom(backgroundColor: Colors.black),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// SEARCH BAR
// ═══════════════════════════════════════════════════════

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
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Ürün ara...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, color: Colors.black54),
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        IconButton(
          onPressed: () => setState(() => _active = true),
          icon: const Icon(Icons.search, color: Colors.black),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// PRODUCT CARD
// ═══════════════════════════════════════════════════════

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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
                ? DecorationImage(image: NetworkImage(product.imageUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: product.imageUrl == null ? Icon(Icons.lunch_dining, color: Colors.grey.shade400) : null,
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
        subtitle: Text(
          '${product.price} ₺',
          style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: product.isAvailable,
              activeColor: Colors.green,
              onChanged: (val) {
                final updated = product.copyWith(isAvailable: val);
                ref.read(productsProvider.notifier).updateProduct(updated);
              },
            ),
            const SizedBox(width: 8),
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

// ═══════════════════════════════════════════════════════
// CATEGORY MANAGEMENT SHEET
// ═══════════════════════════════════════════════════════

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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Yeni Kategori', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _addController,
          autofocus: true,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Kategori Adı',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.black54)),
          ),
          FilledButton(
            onPressed: () async {
              final name = _addController.text.trim();
              if (name.isNotEmpty) {
                try {
                  await ref.read(categoriesProvider.notifier).addCategory(name: name);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  // Error handling
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.black),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kategoriyi Sil?', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: Text(
          '${category.name} kategorisini silmek istediğine emin misin?',
          style: const TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
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
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kategorilerim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.black54)),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.black87))),
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Center(child: Text('Henüz kategori yok.', style: TextStyle(color: Colors.black54)));
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ListTile(
                        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
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

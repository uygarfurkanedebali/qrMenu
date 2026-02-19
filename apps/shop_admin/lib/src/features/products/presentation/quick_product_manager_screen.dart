/// Quick Product Manager Screen
///
/// A fast, flat list of ALL products with instant search filtering.
/// Tap a product → bottom sheet for quick edits (category, price, toggles).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../application/products_provider.dart';
import '../application/categories_provider.dart';
import '../../navigation/admin_menu_drawer.dart';

final _searchProvider = StateProvider.autoDispose<String>((ref) => '');

class QuickProductManagerScreen extends ConsumerWidget {
  const QuickProductManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final searchQuery = ref.watch(_searchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      endDrawer: const AdminMenuDrawer(),
      body: Column(
        children: [
          // TOP BAR
          _buildTopBar(context, ref),
          const Divider(height: 1, color: Color(0xFFE4E4E4)),

          // STICKY SEARCH
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              onChanged: (v) => ref.read(_searchProvider.notifier).state = v,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ürün adı ile ara...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // PRODUCT LIST
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black38)),
              error: (e, _) => Center(child: Text('Hata: $e', style: const TextStyle(color: Colors.black54))),
              data: (products) {
                var filtered = products.toList();
                if (searchQuery.isNotEmpty) {
                  final q = searchQuery.toLowerCase();
                  filtered = filtered.where((p) => p.name.toLowerCase().contains(q)).toList();
                }
                filtered.sort((a, b) => a.name.compareTo(b.name));

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text('Ürün bulunamadı', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 40),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 60, color: Color(0xFFF0F0F0)),
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return _QuickProductRow(product: product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: Colors.white,
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.flash_on, size: 20, color: Colors.amber),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Hızlı Ürün Yönetimi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87, letterSpacing: -0.3)),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 19, color: Colors.black54),
              onPressed: () => ref.invalidate(productsProvider),
            ),
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, size: 19, color: Colors.black54),
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PRODUCT ROW
// ═══════════════════════════════════════════════════════════════

class _QuickProductRow extends ConsumerWidget {
  final Product product;
  const _QuickProductRow({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final category = categories.where((c) => c.id == product.categoryId).firstOrNull;
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return InkWell(
      onTap: () => _showQuickEdit(context, ref, product, categories),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Thumb
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                image: hasImage ? DecorationImage(image: NetworkImage(product.imageUrl!), fit: BoxFit.cover, onError: (_, __) {}) : null,
              ),
              child: !hasImage ? Icon(Icons.fastfood, size: 18, color: Colors.grey.shade400) : null,
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('${product.price.toStringAsFixed(0)} ₺', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                      const SizedBox(width: 8),
                      if (category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFFECEFF1), borderRadius: BorderRadius.circular(4)),
                          child: Text(category.name, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Toggle
            SizedBox(
              width: 44,
              child: Transform.scale(
                scale: 0.65,
                child: Switch(
                  value: product.isAvailable,
                  activeColor: Colors.green,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) {
                    final updated = product.copyWith(isAvailable: val);
                    ref.read(productsProvider.notifier).updateProduct(updated);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUICK EDIT BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════

void _showQuickEdit(BuildContext context, WidgetRef ref, Product product, List<Category> categories) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _QuickEditSheet(product: product, categories: categories),
  );
}

class _QuickEditSheet extends ConsumerStatefulWidget {
  final Product product;
  final List<Category> categories;
  const _QuickEditSheet({required this.product, required this.categories});

  @override
  ConsumerState<_QuickEditSheet> createState() => _QuickEditSheetState();
}

class _QuickEditSheetState extends ConsumerState<_QuickEditSheet> {
  late TextEditingController _priceCtrl;
  late String? _selectedCategoryId;
  late bool _isAvailable;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(text: widget.product.price.toStringAsFixed(2));
    _selectedCategoryId = widget.product.categoryId;
    _isAvailable = widget.product.isAvailable;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final newPrice = double.tryParse(_priceCtrl.text) ?? widget.product.price;
      final updated = widget.product.copyWith(
        price: newPrice,
        categoryId: _selectedCategoryId,
        isAvailable: _isAvailable,
      );
      await ref.read(productsProvider.notifier).updateProduct(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build hierarchical dropdown items
    final mainCats = widget.categories.where((c) => c.parentId == null).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final List<DropdownMenuItem<String>> dropdownItems = [];
    for (final main in mainCats) {
      dropdownItems.add(DropdownMenuItem(value: main.id, child: Text(main.name, style: const TextStyle(fontWeight: FontWeight.w600))));
      final subs = widget.categories.where((c) => c.parentId == main.id).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (final sub in subs) {
        dropdownItems.add(DropdownMenuItem(value: sub.id, child: Text('  ↳ ${sub.name}', style: const TextStyle(fontWeight: FontWeight.w400))));
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          // Title
          Text(widget.product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 18),

          // Category Dropdown
          _sheetLabel('Kategori'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: dropdownItems.any((i) => i.value == _selectedCategoryId) ? _selectedCategoryId : null,
            items: dropdownItems,
            onChanged: (v) => setState(() => _selectedCategoryId = v),
            decoration: _inputDeco('Kategori seçin'),
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            dropdownColor: Colors.white,
          ),
          const SizedBox(height: 14),

          // Price
          _sheetLabel('Fiyat (₺)'),
          const SizedBox(height: 6),
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            decoration: _inputDeco('0.00'),
          ),
          const SizedBox(height: 14),

          // Active Toggle
          Row(
            children: [
              _sheetLabel('Durum'),
              const Spacer(),
              Row(
                children: [
                  Text(_isAvailable ? 'Aktif' : 'Pasif', style: TextStyle(fontSize: 13, color: _isAvailable ? Colors.green : Colors.red.shade400, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  Switch(
                    value: _isAvailable,
                    activeColor: Colors.green,
                    onChanged: (v) => setState(() => _isAvailable = v),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Save
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _sheetLabel(String text) => Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600, letterSpacing: 0.3));

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400),
    filled: true, fillColor: const Color(0xFFF5F5F5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black54, width: 1.5)),
  );
}

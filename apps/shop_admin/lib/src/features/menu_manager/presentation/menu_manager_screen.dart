/// Menu Manager Screen — Unified File Explorer
///
/// Replaces separate Category and Product list screens with
/// a single, hierarchical file-explorer-style management UI.
/// Breadcrumb navigation, folder/file metaphor, drag-and-drop reorder.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_core/shared_core.dart';
import '../../products/application/products_provider.dart';
import '../../products/application/categories_provider.dart';
import '../../products/data/mock_storage_service.dart';
import '../../auth/application/auth_provider.dart';
import '../../navigation/admin_menu_drawer.dart';

// ─── Breadcrumb Model ──────────────────────────────────────────
class _BreadcrumbItem {
  final String id;
  final String label;
  _BreadcrumbItem({required this.id, required this.label});
}

// ─── Local search state ────────────────────────────────────────
final _menuManagerSearchProvider = StateProvider.autoDispose<String>((ref) => '');

// ═══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════

class MenuManagerScreen extends ConsumerStatefulWidget {
  const MenuManagerScreen({super.key});

  @override
  ConsumerState<MenuManagerScreen> createState() => _MenuManagerScreenState();
}

class _MenuManagerScreenState extends ConsumerState<MenuManagerScreen> {
  final List<_BreadcrumbItem> _breadcrumbs = [];
  // null = root level, otherwise current folder category ID
  String? get _currentFolderId =>
      _breadcrumbs.isNotEmpty ? _breadcrumbs.last.id : null;

  void _openFolder(String categoryId, String categoryName) {
    setState(() {
      _breadcrumbs.add(_BreadcrumbItem(id: categoryId, label: categoryName));
    });
  }

  void _navigateToBreadcrumb(int index) {
    setState(() {
      // -1 = root
      if (index < 0) {
        _breadcrumbs.clear();
      } else {
        _breadcrumbs.removeRange(index + 1, _breadcrumbs.length);
      }
    });
  }

  void _goUp() {
    if (_breadcrumbs.isNotEmpty) {
      setState(() => _breadcrumbs.removeLast());
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);
    final searchQuery = ref.watch(_menuManagerSearchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      endDrawer: const AdminMenuDrawer(),
      body: Column(
        children: [
          // ─── App Bar ───
          _buildAppBar(context),

          // ─── Breadcrumbs ───
          _buildBreadcrumbBar(),

          // ─── Search Bar ───
          _buildSearchBar(),

          // ─── Content ───
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 12),
                    Text('Hata: $err', style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(categoriesProvider),
                      style: FilledButton.styleFrom(backgroundColor: Colors.black),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
              data: (allCategories) => productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Ürün hatası: $err')),
                data: (allProducts) => _buildContent(
                  context,
                  allCategories,
                  allProducts,
                  searchQuery,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            if (_breadcrumbs.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: _goUp,
              )
            else
              const SizedBox(width: 16),
            const Icon(Icons.folder_open, color: Colors.black87, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Menü Yöneticisi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black54),
              onPressed: () {
                ref.invalidate(categoriesProvider);
                ref.invalidate(productsProvider);
              },
              tooltip: 'Yenile',
            ),
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black87),
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BREADCRUMBS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBreadcrumbBar() {
    return Container(
      height: 44,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Root
          _BreadcrumbChip(
            label: 'Tüm Kategoriler',
            isActive: _breadcrumbs.isEmpty,
            onTap: () => _navigateToBreadcrumb(-1),
          ),
          // Trail
          for (int i = 0; i < _breadcrumbs.length; i++) ...[
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
            _BreadcrumbChip(
              label: _breadcrumbs[i].label,
              isActive: i == _breadcrumbs.length - 1,
              onTap: () => _navigateToBreadcrumb(i),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        onChanged: (v) => ref.read(_menuManagerSearchProvider.notifier).state = v,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Bu klasörde ara...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          isDense: true,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CONTENT — The mixed folder/file list
  // ═══════════════════════════════════════════════════════════════
  Widget _buildContent(
    BuildContext context,
    List<Category> allCategories,
    List<Product> allProducts,
    String searchQuery,
  ) {
    // Determine what to show at this level
    List<Category> childCategories;
    List<Product> childProducts;

    if (_currentFolderId == null) {
      // Root: main categories only
      childCategories = allCategories.where((c) => c.parentId == null).toList();
      childProducts = []; // No products at root level
    } else {
      // Inside a folder: subcategories + products of this folder
      childCategories = allCategories.where((c) => c.parentId == _currentFolderId).toList();
      childProducts = allProducts.where((p) => p.categoryId == _currentFolderId).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      childCategories = childCategories.where((c) => c.name.toLowerCase().contains(q)).toList();
      childProducts = childProducts.where((p) => p.name.toLowerCase().contains(q)).toList();
    }

    // Sort
    childCategories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    childProducts.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Build combined list: categories first, then products
    final List<_ExplorerItem> items = [
      ...childCategories.map((c) => _ExplorerItem(category: c)),
      ...childProducts.map((p) => _ExplorerItem(product: p)),
    ];

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      itemCount: items.length,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            child: child,
          ),
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) => _handleReorder(items, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isCategory) {
          return _buildCategoryTile(item.category!, index, key: ValueKey('cat_${item.category!.id}'));
        } else {
          return _buildProductTile(item.product!, index, key: ValueKey('prod_${item.product!.id}'));
        }
      },
    );
  }

  // ─── Empty State ─────────────────────────────────────────────
  Widget _buildEmptyState() {
    final isRoot = _currentFolderId == null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isRoot ? Icons.create_new_folder_outlined : Icons.folder_open,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isRoot ? 'Henüz kategori eklenmedi' : 'Bu klasör boş',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            isRoot
                ? '+ butonuyla ilk kategorinizi oluşturun'
                : 'Alt kategori veya ürün ekleyin',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CATEGORY TILE (Folder)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCategoryTile(Category category, int index, {required Key key}) {
    final allCategories = ref.read(categoriesProvider).valueOrNull ?? [];
    final allProducts = ref.read(productsProvider).valueOrNull ?? [];

    // Count direct children
    final subCount = allCategories.where((c) => c.parentId == category.id).length;
    final prodCount = allProducts.where((p) => p.categoryId == category.id).length;
    final totalCount = subCount + prodCount;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: category.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    category.imageUrl!,
                    fit: BoxFit.cover,
                    width: 44,
                    height: 44,
                    errorBuilder: (_, __, ___) => const Icon(Icons.folder, color: Color(0xFFFF9800), size: 22),
                  ),
                )
              : const Icon(Icons.folder, color: Color(0xFFFF9800), size: 22),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
        ),
        subtitle: Text(
          '$totalCount öğe',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.black45),
              onPressed: () => _showCategoryEditSheet(category),
              tooltip: 'Düzenle',
            ),
            // Delete button
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade300),
              onPressed: () => _confirmDeleteCategory(category),
              tooltip: 'Sil',
            ),
            // Navigate chevron
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle, color: Colors.grey.shade400),
            ),
          ],
        ),
        onTap: () => _openFolder(category.id, category.name),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PRODUCT TILE (File)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildProductTile(Product product, int index, {required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: product.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                    width: 44,
                    height: 44,
                    errorBuilder: (_, __, ___) => Icon(Icons.fastfood, color: Colors.grey.shade400, size: 22),
                  ),
                )
              : Icon(Icons.fastfood, color: Colors.grey.shade400, size: 22),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black87),
        ),
        subtitle: Text(
          '${product.price.toStringAsFixed(0)} ₺',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Availability toggle
            Switch(
              value: product.isAvailable,
              activeColor: Colors.green,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (val) {
                final updated = product.copyWith(isAvailable: val);
                ref.read(productsProvider.notifier).updateProduct(updated);
              },
            ),
            // Edit
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.black45),
              onPressed: () => context.go('/products/${product.id}'),
              tooltip: 'Düzenle',
            ),
            // Delete
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade300),
              onPressed: () => _confirmDeleteProduct(product),
              tooltip: 'Sil',
            ),
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle, color: Colors.grey.shade400),
            ),
          ],
        ),
        onTap: () => context.go('/products/${product.id}'),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FAB — Context-aware
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFab(BuildContext context) {
    if (_currentFolderId == null) {
      // Root → add main category
      return FloatingActionButton.extended(
        onPressed: () => _showCategoryEditSheet(null),
        backgroundColor: Colors.black,
        icon: const Icon(Icons.create_new_folder, color: Colors.white, size: 20),
        label: const Text('Kategori Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      );
    }

    // Inside a folder → expandable options
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Add subcategory
        FloatingActionButton.small(
          heroTag: 'addSubCat',
          onPressed: () => _showCategoryEditSheet(null, parentId: _currentFolderId),
          backgroundColor: Colors.orange.shade700,
          child: const Icon(Icons.create_new_folder, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 10),
        // Add product
        FloatingActionButton.extended(
          heroTag: 'addProduct',
          onPressed: () {
            // Navigate to product create with pre-assigned category
            context.go('/products/new?categoryId=$_currentFolderId');
          },
          backgroundColor: Colors.black,
          icon: const Icon(Icons.add, color: Colors.white, size: 20),
          label: const Text('Ürün Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // REORDER HANDLER
  // ═══════════════════════════════════════════════════════════════
  void _handleReorder(List<_ExplorerItem> items, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;

    final movedItem = items[oldIndex];
    // We need separate reorder logic for categories and products
    // For now, update sort_order in-place for the visible list

    if (movedItem.isCategory) {
      // Extract only category items, reorder, and save
      final allCategories = ref.read(categoriesProvider).valueOrNull ?? [];
      final siblings = allCategories.where((c) => c.parentId == _currentFolderId).toList();
      siblings.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final catOldIdx = siblings.indexWhere((c) => c.id == movedItem.category!.id);
      if (catOldIdx == -1) return;

      // Calculate target index among categories only
      int catNewIdx;
      if (newIndex < items.where((i) => i.isCategory).length) {
        catNewIdx = newIndex;
      } else {
        catNewIdx = siblings.length - 1;
      }

      if (catOldIdx == catNewIdx) return;
      ref.read(categoriesProvider.notifier).reorderCategories(catOldIdx, catNewIdx);
    } else {
      // Product reorder — update sort_order
      final product = movedItem.product!;
      final updatedProduct = product.copyWith(sortOrder: newIndex);
      ref.read(productsProvider.notifier).updateProduct(updatedProduct);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CATEGORY EDIT SHEET
  // ═══════════════════════════════════════════════════════════════
  void _showCategoryEditSheet(Category? category, {String? parentId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CategoryEditSheet(
        category: category,
        defaultParentId: parentId ?? _currentFolderId,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DELETE CONFIRMATIONS
  // ═══════════════════════════════════════════════════════════════
  void _confirmDeleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Klasörü Sil?', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: Text(
          '"${category.name}" ve içindeki tüm alt kategoriler silinecek. Emin misiniz?',
          style: const TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(categoriesProvider.notifier).deleteCategory(category.id);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ürünü Sil?', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: Text(
          '"${product.name}" silinecek. Emin misiniz?',
          style: const TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(productsProvider.notifier).deleteProduct(product.id);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXPLORER ITEM — Union type for category or product
// ═══════════════════════════════════════════════════════════════
class _ExplorerItem {
  final Category? category;
  final Product? product;

  _ExplorerItem({this.category, this.product})
      : assert(category != null || product != null);

  bool get isCategory => category != null;
}

// ═══════════════════════════════════════════════════════════════
// BREADCRUMB CHIP
// ═══════════════════════════════════════════════════════════════
class _BreadcrumbChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BreadcrumbChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.black87 : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY EDIT SHEET (Inline — creates/edits categories)
// ═══════════════════════════════════════════════════════════════
class _CategoryEditSheet extends ConsumerStatefulWidget {
  final Category? category;
  final String? defaultParentId;

  const _CategoryEditSheet({this.category, this.defaultParentId});

  @override
  ConsumerState<_CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends ConsumerState<_CategoryEditSheet> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _pickedFile;
  String? _previewUrl;
  bool _isLoading = false;
  String? _selectedParentId;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _previewUrl = widget.category!.imageUrl;
      _selectedParentId = widget.category!.parentId;
    } else {
      _selectedParentId = widget.defaultParentId;
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked != null) {
      setState(() {
        _pickedFile = picked;
        _previewUrl = null;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori adı boş olamaz')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = widget.category?.imageUrl;
      if (_pickedFile != null) {
        final storageService = ref.read(storageServiceProvider);
        imageUrl = await storageService.uploadCategoryImage(_pickedFile!);
      }

      if (widget.category == null) {
        await ref.read(categoriesProvider.notifier).addCategory(
          name: name,
          imageUrl: imageUrl,
          parentId: _selectedParentId,
        );
      } else {
        final updated = widget.category!.copyWith(
          name: name,
          imageUrl: imageUrl,
          parentId: _selectedParentId,
          clearParentId: _selectedParentId == null,
        );
        await ref.read(categoriesProvider.notifier).updateCategory(updated);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLocalImage = _pickedFile != null;
    final bool hasNetworkImage = _previewUrl != null;
    final isEditing = widget.category != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.folder, color: Colors.orange.shade700, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Klasörü Düzenle' : 'Yeni Klasör',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Image Picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                image: hasLocalImage
                    ? DecorationImage(image: NetworkImage(_pickedFile!.path), fit: BoxFit.cover, onError: (_, __) {})
                    : (hasNetworkImage ? DecorationImage(image: NetworkImage(_previewUrl!), fit: BoxFit.cover) : null),
              ),
              child: !hasLocalImage && !hasNetworkImage
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey.shade400),
                          const SizedBox(height: 6),
                          Text('Kapak Görseli', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Name Input
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Klasör Adı',
              labelStyle: const TextStyle(color: Colors.black54),
              hintText: 'Örn: Kahvaltılıklar',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
            ),
          ),
          const SizedBox(height: 20),

          // Save Button
          FilledButton(
            onPressed: _isLoading ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isEditing ? 'Güncelle' : 'Oluştur', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

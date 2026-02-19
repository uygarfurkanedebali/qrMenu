/// Menu Explorer Screen — Supabase Storage / Windows Explorer UX
///
/// A file-explorer paradigm for managing Categories (Folders) and Products (Files).
/// Features: breadcrumb navigation, drag-and-drop reassignment, preview panel.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_core/shared_core.dart';
import '../../products/application/products_provider.dart';
import '../../products/application/categories_provider.dart';
import '../../products/data/mock_storage_service.dart';
import '../../navigation/admin_menu_drawer.dart';

// ═══════════════════════════════════════════════════════════════
// STATE — Current path managed via Riverpod
// ═══════════════════════════════════════════════════════════════

/// Each node in the breadcrumb path. null id = root.
class PathNode {
  final String? id;
  final String label;
  const PathNode({required this.id, required this.label});
}

/// Manages the current explorer path (breadcrumb trail).
class ExplorerPathNotifier extends StateNotifier<List<PathNode>> {
  ExplorerPathNotifier() : super(const []);

  /// Current folder ID. null = root.
  String? get currentFolderId => state.isNotEmpty ? state.last.id : null;

  /// Drill into a folder.
  void push(String id, String label) {
    state = [...state, PathNode(id: id, label: label)];
  }

  /// Navigate to a specific breadcrumb index. -1 = root.
  void navigateTo(int index) {
    if (index < 0) {
      state = [];
    } else {
      state = state.sublist(0, index + 1);
    }
  }

  /// Go up one level.
  void pop() {
    if (state.isNotEmpty) {
      state = state.sublist(0, state.length - 1);
    }
  }
}

final explorerPathProvider =
    StateNotifierProvider<ExplorerPathNotifier, List<PathNode>>(
  (ref) => ExplorerPathNotifier(),
);

/// Derived provider: items visible in the current directory.
final currentDirectoryProvider = Provider<_DirectoryContents>((ref) {
  final path = ref.watch(explorerPathProvider);
  final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
  final products = ref.watch(productsProvider).valueOrNull ?? [];

  final currentId = path.isNotEmpty ? path.last.id : null;

  final childCategories = categories
      .where((c) => c.parentId == currentId)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final childProducts = currentId == null
      ? <Product>[] // Root shows no products, only category folders
      : products
          .where((p) => p.categoryId == currentId)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  return _DirectoryContents(categories: childCategories, products: childProducts);
});

class _DirectoryContents {
  final List<Category> categories;
  final List<Product> products;
  const _DirectoryContents({required this.categories, required this.products});
  int get totalCount => categories.length + products.length;
  bool get isEmpty => totalCount == 0;
}

// ═══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════

class MenuExplorerScreen extends ConsumerWidget {
  const MenuExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);

    // Wait for both to load
    final isLoading = categoriesAsync.isLoading || productsAsync.isLoading;
    final hasError = categoriesAsync.hasError || productsAsync.hasError;
    final errorMsg = categoriesAsync.error?.toString() ??
        productsAsync.error?.toString() ??
        '';

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      endDrawer: const AdminMenuDrawer(),
      body: Column(
        children: [
          // ─── Toolbar ───
          _ExplorerToolbar(),

          // ─── Breadcrumb Bar ───
          const _BreadcrumbBar(),

          // ─── Column Header ───
          _columnHeader(),

          const Divider(height: 1, color: Color(0xFFE8E8E8)),

          // ─── Content ───
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black45))
                : hasError
                    ? _errorWidget(ref, errorMsg)
                    : const _DirectoryListView(),
          ),
        ],
      ),
    );
  }

  Widget _columnHeader() {
    return Container(
      height: 36,
      color: const Color(0xFFF6F6F6),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const SizedBox(width: 36), // icon space
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text('Ad',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5)),
          ),
          Expanded(
            flex: 2,
            child: Text('Tür',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5)),
          ),
          SizedBox(
            width: 80,
            child: Text('Boyut',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(width: 48), // actions space
        ],
      ),
    );
  }

  Widget _errorWidget(WidgetRef ref, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 48, color: Colors.red.shade200),
          const SizedBox(height: 12),
          Text('Hata: $msg',
              style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(categoriesProvider);
              ref.invalidate(productsProvider);
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Tekrar Dene'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOOLBAR — Top bar with actions
// ═══════════════════════════════════════════════════════════════

class _ExplorerToolbar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(explorerPathProvider);
    final canGoUp = path.isNotEmpty;

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: Colors.white,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: 8),
            // Back
            IconButton(
              icon: Icon(Icons.arrow_back,
                  color: canGoUp ? Colors.black87 : Colors.grey.shade300,
                  size: 20),
              onPressed: canGoUp
                  ? () => ref.read(explorerPathProvider.notifier).pop()
                  : null,
            ),
            // Refresh
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black54, size: 20),
              onPressed: () {
                ref.invalidate(categoriesProvider);
                ref.invalidate(productsProvider);
              },
              tooltip: 'Yenile',
            ),

            const Spacer(),

            // + Klasör
            _ToolbarButton(
              icon: Icons.create_new_folder_outlined,
              label: 'Klasör',
              onTap: () => _showNewCategorySheet(context, ref),
            ),
            const SizedBox(width: 6),

            // + Dosya
            _ToolbarButton(
              icon: Icons.note_add_outlined,
              label: 'Dosya',
              onTap: () {
                final currentId =
                    ref.read(explorerPathProvider.notifier).currentFolderId;
                if (currentId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Önce bir kategori klasörüne girin'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                context.go('/products/new?categoryId=$currentId');
              },
            ),
            const SizedBox(width: 8),

            // Drawer
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black54, size: 20),
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  void _showNewCategorySheet(BuildContext context, WidgetRef ref) {
    final parentId = ref.read(explorerPathProvider.notifier).currentFolderId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CategoryCreateSheet(parentId: parentId),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolbarButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0F0F0),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.black87),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BREADCRUMB BAR
// ═══════════════════════════════════════════════════════════════

class _BreadcrumbBar extends ConsumerWidget {
  const _BreadcrumbBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(explorerPathProvider);

    return Container(
      height: 40,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Home
            _crumb(
              icon: Icons.home_outlined,
              label: 'Ana Sayfa',
              isActive: path.isEmpty,
              onTap: () => ref.read(explorerPathProvider.notifier).navigateTo(-1),
            ),
            // Trail
            for (int i = 0; i < path.length; i++) ...[
              Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
              _crumb(
                label: path[i].label,
                isActive: i == path.length - 1,
                onTap: () =>
                    ref.read(explorerPathProvider.notifier).navigateTo(i),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _crumb(
      {IconData? icon,
      required String label,
      required bool isActive,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16,
                  color: isActive ? Colors.black87 : Colors.grey.shade500),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.black87 : Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DIRECTORY LIST VIEW — Folders then Files
// ═══════════════════════════════════════════════════════════════

class _DirectoryListView extends ConsumerWidget {
  const _DirectoryListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(currentDirectoryProvider);

    if (dir.isEmpty) {
      return _emptyState(ref);
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: dir.totalCount,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 68, color: Color(0xFFF0F0F0)),
      itemBuilder: (context, index) {
        if (index < dir.categories.length) {
          return _FolderRow(category: dir.categories[index]);
        }
        final prodIndex = index - dir.categories.length;
        return _FileRow(product: dir.products[prodIndex]);
      },
    );
  }

  Widget _emptyState(WidgetRef ref) {
    final isRoot =
        ref.read(explorerPathProvider.notifier).currentFolderId == null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isRoot ? Icons.folder_off_outlined : Icons.insert_drive_file_outlined,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            isRoot ? 'Henüz klasör yok' : 'Bu klasör boş',
            style:
                TextStyle(fontSize: 15, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            'Araç çubuğundan + butonlarıyla ekleyin',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FOLDER ROW — A category, acts as DragTarget for products
// ═══════════════════════════════════════════════════════════════

class _FolderRow extends ConsumerStatefulWidget {
  final Category category;
  const _FolderRow({required this.category});

  @override
  ConsumerState<_FolderRow> createState() => _FolderRowState();
}

class _FolderRowState extends ConsumerState<_FolderRow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;

    // Count children for the size column
    final allCats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final allProds = ref.watch(productsProvider).valueOrNull ?? [];
    final childCount = allCats.where((c) => c.parentId == cat.id).length +
        allProds.where((p) => p.categoryId == cat.id).length;

    // This folder is a DragTarget for Products and Categories
    return DragTarget<Product>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _isHovering = false),
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        _reassignProduct(details.data, cat.id);
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<Category>(
          data: cat,
          feedback: _DragFeedback(icon: Icons.folder, label: cat.name, color: const Color(0xFF78909C)),
          childWhenDragging: Opacity(opacity: 0.3, child: _buildTile(cat, childCount)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: _isHovering ? const Color(0xFFE3F2FD) : Colors.white,
            child: _buildTile(cat, childCount),
          ),
        );
      },
    );
  }

  Widget _buildTile(Category cat, int childCount) {
    return InkWell(
      onTap: () =>
          ref.read(explorerPathProvider.notifier).push(cat.id, cat.name),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            // Folder icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFECEFF1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.folder, color: Color(0xFF78909C), size: 20),
            ),
            const SizedBox(width: 12),

            // Name
            Expanded(
              flex: 4,
              child: Text(
                cat.name,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Type
            Expanded(
              flex: 2,
              child: Text('Klasör',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ),

            // Size (item count)
            SizedBox(
              width: 80,
              child: Text('$childCount öğe',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ),

            // Info button
            SizedBox(
              width: 48,
              child: IconButton(
                icon: Icon(Icons.info_outline,
                    size: 18, color: Colors.grey.shade400),
                onPressed: () => _showCategoryPreview(context, cat),
                splashRadius: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reassignProduct(Product product, String newCategoryId) {
    final updated = product.copyWith(categoryId: newCategoryId);
    ref.read(productsProvider.notifier).updateProduct(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${product.name}" taşındı'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCategoryPreview(BuildContext context, Category cat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CategoryPreviewPanel(category: cat),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FILE ROW — A product, draggable onto folders
// ═══════════════════════════════════════════════════════════════

class _FileRow extends ConsumerWidget {
  final Product product;
  const _FileRow({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LongPressDraggable<Product>(
      data: product,
      feedback: _DragFeedback(
          icon: Icons.insert_drive_file,
          label: product.name,
          color: Colors.blueGrey.shade300),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildTile(context, ref)),
      child: _buildTile(context, ref),
    );
  }

  Widget _buildTile(BuildContext context, WidgetRef ref) {
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return InkWell(
      onTap: () => _showProductPreview(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                image: hasImage
                    ? DecorationImage(
                        image: NetworkImage(product.imageUrl!),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
              ),
              child: !hasImage
                  ? Icon(Icons.insert_drive_file,
                      color: Colors.grey.shade400, size: 18)
                  : null,
            ),
            const SizedBox(width: 12),

            // Name
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!product.isAvailable)
                    Text('Stokta yok',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            // Type
            Expanded(
              flex: 2,
              child: Text('Ürün',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ),

            // Price
            SizedBox(
              width: 80,
              child: Text(
                '${product.price.toStringAsFixed(0)} ₺',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700),
              ),
            ),

            // Info button
            SizedBox(
              width: 48,
              child: IconButton(
                icon: Icon(Icons.info_outline,
                    size: 18, color: Colors.grey.shade400),
                onPressed: () => _showProductPreview(context, ref),
                splashRadius: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductPreview(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ProductPreviewPanel(product: product),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DRAG FEEDBACK — Ghost widget shown while dragging
// ═══════════════════════════════════════════════════════════════

class _DragFeedback extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _DragFeedback(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 220),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    decoration: TextDecoration.none),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PRODUCT PREVIEW PANEL — Bottom sheet detail view
// ═══════════════════════════════════════════════════════════════

class _ProductPreviewPanel extends ConsumerWidget {
  final Product product;
  const _ProductPreviewPanel({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Image
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.broken_image,
                      size: 48, color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.fastfood, size: 48, color: Colors.grey.shade300),
            ),
          const SizedBox(height: 20),

          // Name
          Text(product.name,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 6),

          // Price
          Text('${product.price.toStringAsFixed(2)} ₺',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 4),

          // Description
          if (product.description != null && product.description!.isNotEmpty)
            Text(product.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.4)),

          const SizedBox(height: 8),

          // Metadata
          Row(
            children: [
              Icon(Icons.circle,
                  size: 8,
                  color:
                      product.isAvailable ? Colors.green : Colors.red.shade300),
              const SizedBox(width: 6),
              Text(
                product.isAvailable ? 'Aktif' : 'Pasif',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Spacer(),
              Text(
                'Eklenme: ${product.createdAt.day}.${product.createdAt.month}.${product.createdAt.year}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/products/${product.id}');
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Düzenle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        title: const Text('Ürünü Sil?',
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 17)),
                        content: Text('"${product.name}" kalıcı olarak silinecek.',
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 14)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('İptal',
                                style: TextStyle(color: Colors.black54)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sil',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      ref
                          .read(productsProvider.notifier)
                          .deleteProduct(product.id);
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Sil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY PREVIEW PANEL — Bottom sheet for folder info
// ═══════════════════════════════════════════════════════════════

class _CategoryPreviewPanel extends ConsumerWidget {
  final Category category;
  const _CategoryPreviewPanel({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage =
        category.imageUrl != null && category.imageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Image
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(category.imageUrl!,
                  height: 160, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderBox()),
            )
          else
            _placeholderBox(),

          const SizedBox(height: 20),

          // Name
          Row(
            children: [
              const Icon(Icons.folder, color: Color(0xFF78909C), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(category.name,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
              ),
            ],
          ),
          if (category.description != null &&
              category.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(category.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (_) =>
                          _CategoryCreateSheet(editCategory: category),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Düzenle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        title: const Text('Klasörü Sil?',
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 17)),
                        content: Text(
                            '"${category.name}" ve içindekiler silinecek.',
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 14)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('İptal',
                                style: TextStyle(color: Colors.black54)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sil',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      ref
                          .read(categoriesProvider.notifier)
                          .deleteCategory(category.id);
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Sil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _placeholderBox() => Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.folder_open, size: 40, color: Color(0xFFBDBDBD)),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY CREATE / EDIT SHEET
// ═══════════════════════════════════════════════════════════════

class _CategoryCreateSheet extends ConsumerStatefulWidget {
  final String? parentId;
  final Category? editCategory;
  const _CategoryCreateSheet({this.parentId, this.editCategory});

  @override
  ConsumerState<_CategoryCreateSheet> createState() =>
      _CategoryCreateSheetState();
}

class _CategoryCreateSheetState extends ConsumerState<_CategoryCreateSheet> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _pickedFile;
  String? _previewUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editCategory != null) {
      _nameController.text = widget.editCategory!.name;
      _previewUrl = widget.editCategory!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked != null) {
      setState(() {
        _pickedFile = picked;
        _previewUrl = null;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      String? imageUrl = widget.editCategory?.imageUrl;
      if (_pickedFile != null) {
        imageUrl = await ref
            .read(storageServiceProvider)
            .uploadCategoryImage(_pickedFile!);
      }

      if (widget.editCategory == null) {
        // Create
        await ref.read(categoriesProvider.notifier).addCategory(
              name: name,
              imageUrl: imageUrl,
              parentId: widget.parentId,
            );
      } else {
        // Update
        final updated = widget.editCategory!.copyWith(
          name: name,
          imageUrl: imageUrl,
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editCategory != null;
    final hasLocalImage = _pickedFile != null;
    final hasNetworkImage = _previewUrl != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              const Icon(Icons.create_new_folder,
                  color: Color(0xFF78909C), size: 22),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'Klasörü Düzenle' : 'Yeni Klasör',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.black45, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Image
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8E8)),
                image: hasLocalImage
                    ? DecorationImage(
                        image: NetworkImage(_pickedFile!.path),
                        fit: BoxFit.cover,
                        onError: (_, __) {})
                    : (hasNetworkImage
                        ? DecorationImage(
                            image: NetworkImage(_previewUrl!),
                            fit: BoxFit.cover)
                        : null),
              ),
              child: !hasLocalImage && !hasNetworkImage
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 28, color: Colors.grey.shade400),
                        const SizedBox(height: 4),
                        Text('Kapak Görseli',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400)),
                      ],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),

          // Name
          TextField(
            controller: _nameController,
            autofocus: !isEditing,
            style: const TextStyle(color: Colors.black87, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Klasör adı',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Colors.black54, width: 1.5)),
            ),
          ),
          const SizedBox(height: 18),

          // Save
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(isEditing ? 'Güncelle' : 'Oluştur',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

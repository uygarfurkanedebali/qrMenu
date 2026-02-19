/// Menu Explorer Screen — VS Code / Supabase Storage Split-Pane
///
/// Left Pane:  Main Categories (parent_id == null) — always visible
/// Right Pane: Contents of selected Main Category (subcategories + products)
/// Drag & Drop: LongPressDraggable for nesting/moving, ReorderableDragStartListener for reorder
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
// STATE
// ═══════════════════════════════════════════════════════════════

/// Tracks which Main Category is currently selected in the left pane.
final selectedMainCategoryProvider = StateProvider<String?>((ref) => null);

// ═══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════

class MenuExplorerScreen extends ConsumerWidget {
  const MenuExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);
    final isLoading = categoriesAsync.isLoading || productsAsync.isLoading;
    final hasError = categoriesAsync.hasError || productsAsync.hasError;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      endDrawer: const AdminMenuDrawer(),
      body: Column(
        children: [
          _TopBar(),
          const Divider(height: 1, color: Color(0xFFE4E4E4)),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black38))
                : hasError
                    ? _ErrorView()
                    : isMobile
                        ? _MobileLayout()
                        : _DesktopLayout(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════

class _TopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: Colors.white,
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.folder_open, size: 20, color: Colors.black87),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Menü Yöneticisi',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87, letterSpacing: -0.3)),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 19, color: Colors.black54),
              onPressed: () {
                ref.invalidate(categoriesProvider);
                ref.invalidate(productsProvider);
              },
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
// ERROR VIEW
// ═══════════════════════════════════════════════════════════════

class _ErrorView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 44, color: Colors.red.shade200),
          const SizedBox(height: 10),
          const Text('Veriler yüklenemedi', style: TextStyle(color: Colors.black54, fontSize: 14)),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {
              ref.invalidate(categoriesProvider);
              ref.invalidate(productsProvider);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Color(0xFFDDD)),
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DESKTOP LAYOUT — Side-by-side panes
// ═══════════════════════════════════════════════════════════════

class _DesktopLayout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // LEFT PANE — Main Categories
        SizedBox(
          width: 280,
          child: Container(
            color: const Color(0xFFF5F5F5),
            child: const _LeftPane(),
          ),
        ),
        const VerticalDivider(width: 1, color: Color(0xFFE4E4E4)),
        // RIGHT PANE — Contents
        const Expanded(child: _RightPane()),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MOBILE LAYOUT — Tabs or stacked view
// ═══════════════════════════════════════════════════════════════

class _MobileLayout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedMainCategoryProvider);

    if (selectedId == null) {
      return const _LeftPane();
    }

    return Column(
      children: [
        // Back bar
        Container(
          color: Colors.white,
          height: 40,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                onPressed: () => ref.read(selectedMainCategoryProvider.notifier).state = null,
              ),
              Consumer(builder: (context, ref, _) {
                final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
                final cat = cats.where((c) => c.id == selectedId).firstOrNull;
                return Text(cat?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15));
              }),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE4E4E4)),
        const Expanded(child: _RightPane()),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LEFT PANE — Main Categories list
// ═══════════════════════════════════════════════════════════════

class _LeftPane extends ConsumerWidget {
  const _LeftPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final mainCategories = categories.where((c) => c.parentId == null).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final selectedId = ref.watch(selectedMainCategoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // PANE HEADER
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Text('Kategoriler', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600, letterSpacing: 0.5)),
              const Spacer(),
              _MiniButton(
                icon: Icons.create_new_folder_outlined,
                tooltip: 'Yeni Kategori',
                onTap: () => _showCategorySheet(context, ref, parentId: null),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // CATEGORY LIST — DragTarget for promoting items to root
        Expanded(
          child: DragTarget<Product>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) {
              // Dropping a product into empty left pane → can't promote products to root
              // (products must belong to a category)
            },
            builder: (context, _, __) => DragTarget<Category>(
              onWillAcceptWithDetails: (details) => details.data.parentId != null,
              onAcceptWithDetails: (details) {
                // Promote subcategory to main category
                final updated = details.data.copyWith(parentId: null, clearParentId: true);
                ref.read(categoriesProvider.notifier).updateCategory(updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${details.data.name}" ana kategori yapıldı'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.green.shade700),
                );
              },
              builder: (context, candidateData, _) {
                final isHovering = candidateData.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  color: isHovering ? const Color(0xFFE3F2FD) : Colors.transparent,
                  child: mainCategories.isEmpty
                      ? Center(child: Text('Klasör yok', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)))
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: mainCategories.length,
                          onReorder: (o, n) => ref.read(categoriesProvider.notifier).reorderCategories(o, n),
                          proxyDecorator: _proxyDecorator,
                          itemBuilder: (context, index) {
                            final cat = mainCategories[index];
                            return _MainCategoryRow(
                              key: ValueKey('main_${cat.id}'),
                              category: cat,
                              isSelected: cat.id == selectedId,
                              index: index,
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RIGHT PANE — Subcategories + Products of selected main
// ═══════════════════════════════════════════════════════════════

class _RightPane extends ConsumerWidget {
  const _RightPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedMainCategoryProvider);
    if (selectedId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text('Bir kategori seçin', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final products = ref.watch(productsProvider).valueOrNull ?? [];

    final subCategories = categories.where((c) => c.parentId == selectedId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final directProducts = products.where((p) => p.categoryId == selectedId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Combined items: subcategories first, then products
    final List<_ExplorerItem> items = [
      ...subCategories.map((c) => _ExplorerItem.folder(c)),
      ...directProducts.map((p) => _ExplorerItem.file(p)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // PANE HEADER
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Text('İçerik', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600, letterSpacing: 0.5)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                child: Text('${items.length}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              _MiniButton(
                icon: Icons.create_new_folder_outlined,
                tooltip: 'Alt Kategori Ekle',
                onTap: () => _showCategorySheet(context, ref, parentId: selectedId),
              ),
              const SizedBox(width: 4),
              _MiniButton(
                icon: Icons.note_add_outlined,
                tooltip: 'Ürün Ekle',
                onTap: () => context.go('/products/new?categoryId=$selectedId'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // COLUMN HEADER
        Container(
          height: 32,
          color: const Color(0xFFFAFAFA),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const SizedBox(width: 34),
              Expanded(flex: 3, child: _colLabel('Ad')),
              Expanded(flex: 1, child: _colLabel('Tür')),
              const SizedBox(width: 130), // actions space
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // ITEMS LIST
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_outlined, size: 44, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('Klasör boş', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: items.length,
                  onReorder: (o, n) => _handleReorder(ref, items, o, n),
                  proxyDecorator: _proxyDecorator,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item.isFolder) {
                      return _SubFolderRow(key: ValueKey('sub_${item.category!.id}'), category: item.category!, index: index);
                    }
                    return _FileRow(key: ValueKey('file_${item.product!.id}'), product: item.product!, index: index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _colLabel(String text) => Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.3));

  void _handleReorder(WidgetRef ref, List<_ExplorerItem> items, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    if (oldIndex == newIndex) return;

    final item = items[oldIndex];
    if (item.isFolder) {
      // Reorder among subcategories
      final catItems = items.where((i) => i.isFolder).toList();
      final catOld = catItems.indexWhere((i) => i.category!.id == item.category!.id);
      final catNew = newIndex.clamp(0, catItems.length - 1);
      if (catOld != catNew) ref.read(categoriesProvider.notifier).reorderCategories(catOld, catNew);
    } else {
      // Update product sort_order
      final updated = item.product!.copyWith(sortOrder: newIndex);
      ref.read(productsProvider.notifier).updateProduct(updated);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// MAIN CATEGORY ROW (Left Pane)
// ═══════════════════════════════════════════════════════════════

class _MainCategoryRow extends ConsumerStatefulWidget {
  final Category category;
  final bool isSelected;
  final int index;
  const _MainCategoryRow({super.key, required this.category, required this.isSelected, required this.index});

  @override
  ConsumerState<_MainCategoryRow> createState() => _MainCategoryRowState();
}

class _MainCategoryRowState extends ConsumerState<_MainCategoryRow> {
  bool _isDragHovering = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;

    // This row is a DragTarget for products/subcategories being moved here
    return DragTarget<Product>(
      onWillAcceptWithDetails: (d) {
        setState(() => _isDragHovering = true);
        return d.data.categoryId != cat.id;
      },
      onLeave: (_) => setState(() => _isDragHovering = false),
      onAcceptWithDetails: (d) {
        setState(() => _isDragHovering = false);
        final updated = d.data.copyWith(categoryId: cat.id);
        ref.read(productsProvider.notifier).updateProduct(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${d.data.name}" → ${cat.name}'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.green.shade700),
        );
      },
      builder: (context, _, __) => DragTarget<Category>(
        onWillAcceptWithDetails: (d) {
          setState(() => _isDragHovering = true);
          return d.data.id != cat.id && d.data.parentId != cat.id;
        },
        onLeave: (_) => setState(() => _isDragHovering = false),
        onAcceptWithDetails: (d) {
          setState(() => _isDragHovering = false);
          // Move the category under this main category
          final updated = d.data.copyWith(parentId: cat.id);
          ref.read(categoriesProvider.notifier).updateCategory(updated);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${d.data.name}" → ${cat.name}'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.green.shade700),
          );
        },
        builder: (context, catCandidates, __) {
          final hovering = _isDragHovering || catCandidates.isNotEmpty;

          return LongPressDraggable<Category>(
            data: cat,
            feedback: _DragGhost(icon: Icons.folder, label: cat.name),
            childWhenDragging: Opacity(opacity: 0.25, child: _tile(cat, hovering)),
            child: _tile(cat, hovering),
          );
        },
      ),
    );
  }

  Widget _tile(Category cat, bool hovering) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: hovering
          ? const Color(0xFFE3F2FD)
          : widget.isSelected
              ? const Color(0xFFEAEAEA)
              : Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(selectedMainCategoryProvider.notifier).state = cat.id,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.folder, color: Color(0xFF78909C), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(cat.name, style: TextStyle(fontSize: 14, fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              // Actions
              _ActionSwitch(isAvailable: true, onChanged: (_) {}), // Categories don't have active flag yet
              _ActionIconButton(icon: Icons.edit_outlined, onTap: () => _showCategorySheet(context, ref, category: cat)),
              ReorderableDragStartListener(
                index: widget.index,
                child: Icon(Icons.drag_handle, size: 18, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SUB FOLDER ROW (Right Pane)
// ═══════════════════════════════════════════════════════════════

class _SubFolderRow extends ConsumerStatefulWidget {
  final Category category;
  final int index;
  const _SubFolderRow({super.key, required this.category, required this.index});

  @override
  ConsumerState<_SubFolderRow> createState() => _SubFolderRowState();
}

class _SubFolderRowState extends ConsumerState<_SubFolderRow> {
  bool _isDragHovering = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;

    return DragTarget<Product>(
      onWillAcceptWithDetails: (d) {
        setState(() => _isDragHovering = true);
        return d.data.categoryId != cat.id;
      },
      onLeave: (_) => setState(() => _isDragHovering = false),
      onAcceptWithDetails: (d) {
        setState(() => _isDragHovering = false);
        final updated = d.data.copyWith(categoryId: cat.id);
        ref.read(productsProvider.notifier).updateProduct(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${d.data.name}" → ${cat.name}'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.green.shade700),
        );
      },
      builder: (context, _, __) {
        return LongPressDraggable<Category>(
          data: cat,
          feedback: _DragGhost(icon: Icons.folder, label: cat.name),
          childWhenDragging: Opacity(opacity: 0.25, child: _tile(cat)),
          child: _tile(cat),
        );
      },
    );
  }

  Widget _tile(Category cat) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: _isDragHovering ? const Color(0xFFE3F2FD) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.folder, color: Color(0xFF78909C), size: 20),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: Text(cat.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Expanded(flex: 1, child: Text('Klasör', style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
            // Actions
            _ActionSwitch(isAvailable: true, onChanged: (_) {}),
            _ActionIconButton(icon: Icons.edit_outlined, onTap: () => _showCategorySheet(context, ref, category: cat)),
            ReorderableDragStartListener(
              index: widget.index,
              child: Icon(Icons.drag_handle, size: 18, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FILE ROW (Right Pane — Product)
// ═══════════════════════════════════════════════════════════════

class _FileRow extends ConsumerWidget {
  final Product product;
  final int index;
  const _FileRow({super.key, required this.product, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LongPressDraggable<Product>(
      data: product,
      feedback: _DragGhost(icon: Icons.insert_drive_file, label: product.name),
      childWhenDragging: Opacity(opacity: 0.25, child: _tile(context, ref)),
      child: _tile(context, ref),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref) {
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              image: hasImage ? DecorationImage(image: NetworkImage(product.imageUrl!), fit: BoxFit.cover, onError: (_, __) {}) : null,
            ),
            child: !hasImage ? Icon(Icons.insert_drive_file, size: 14, color: Colors.grey.shade400) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${product.price.toStringAsFixed(0)} ₺', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text('Ürün', style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),

          // Actions
          _ActionSwitch(
            isAvailable: product.isAvailable,
            onChanged: (val) {
              final updated = product.copyWith(isAvailable: val);
              ref.read(productsProvider.notifier).updateProduct(updated);
            },
          ),
          _ActionIconButton(
            icon: Icons.edit_outlined,
            onTap: () => context.go('/products/${product.id}'),
          ),
          ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_handle, size: 18, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════

class _ExplorerItem {
  final Category? category;
  final Product? product;
  _ExplorerItem.folder(this.category) : product = null;
  _ExplorerItem.file(this.product) : category = null;
  bool get isFolder => category != null;
}

class _DragGhost extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DragGhost({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF78909C)),
            const SizedBox(width: 8),
            Flexible(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87, decoration: TextDecoration.none), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _MiniButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 16, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

class _ActionSwitch extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onChanged;
  const _ActionSwitch({required this.isAvailable, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Transform.scale(
        scale: 0.65,
        child: Switch(
          value: isAvailable,
          onChanged: onChanged,
          activeColor: Colors.green,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: IconButton(
        icon: Icon(icon, size: 16, color: Colors.black45),
        onPressed: onTap,
        splashRadius: 14,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }
}

Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) => Material(
      elevation: 3,
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: child,
    ),
    child: child,
  );
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY SHEET — Create / Edit
// ═══════════════════════════════════════════════════════════════

void _showCategorySheet(BuildContext context, WidgetRef ref, {Category? category, String? parentId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _CategorySheet(category: category, parentId: parentId),
  );
}

class _CategorySheet extends ConsumerStatefulWidget {
  final Category? category;
  final String? parentId;
  const _CategorySheet({this.category, this.parentId});
  @override
  ConsumerState<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<_CategorySheet> {
  final _name = TextEditingController();
  final _picker = ImagePicker();
  XFile? _picked;
  String? _preview;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _name.text = widget.category!.name;
      _preview = widget.category!.imageUrl;
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      String? imageUrl = widget.category?.imageUrl;
      if (_picked != null) {
        imageUrl = await ref.read(storageServiceProvider).uploadCategoryImage(_picked!);
      }
      if (widget.category == null) {
        await ref.read(categoriesProvider.notifier).addCategory(name: name, imageUrl: imageUrl, parentId: widget.parentId);
      } else {
        final updated = widget.category!.copyWith(name: name, imageUrl: imageUrl);
        await ref.read(categoriesProvider.notifier).updateCategory(updated);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(isEdit ? 'Düzenle' : 'Yeni Klasör', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              final p = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
              if (p != null) setState(() { _picked = p; _preview = null; });
            },
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE8E8E8)),
                image: _preview != null ? DecorationImage(image: NetworkImage(_preview!), fit: BoxFit.cover) : null,
              ),
              child: _picked == null && _preview == null ? Center(child: Icon(Icons.add_photo_alternate_outlined, size: 24, color: Colors.grey.shade400)) : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            autofocus: !isEdit,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Klasör adı', hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true, fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black54, width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isEdit ? 'Güncelle' : 'Oluştur', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

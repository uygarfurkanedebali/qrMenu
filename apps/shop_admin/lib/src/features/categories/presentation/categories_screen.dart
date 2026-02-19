/// Categories Screen — Hierarchical Category Management
/// 
/// Instagram-style visual category cards with subcategory support.
/// Main categories shown as banner cards, subcategories indented beneath their parent.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_core/shared_core.dart';
import '../../products/application/categories_provider.dart';
import '../../products/data/mock_storage_service.dart';
import '../../navigation/admin_menu_drawer.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Kategoriler', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sıralama özelliği yakında...')),
              );
            },
            tooltip: 'Sıralama Düzenle',
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: const AdminMenuDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCategorySheet(context),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.black87))),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Henüz kategori yok', style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Text('Yeni eklemek için + butonuna basın', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            );
          }

          // Build hierarchical list: main categories first, subcategories indented
          final mainCategories = categories.where((c) => c.parentId == null).toList();
          final List<Widget> items = [];

          for (final main in mainCategories) {
            items.add(_CategoryBannerCard(category: main, isSubcategory: false));
            // Find subcategories for this main category
            final subs = categories.where((c) => c.parentId == main.id).toList();
            for (final sub in subs) {
              items.add(_CategoryBannerCard(category: sub, isSubcategory: true));
            }
          }

          // Also show orphaned subcategories whose parent might not be in the list
          final knownMainIds = mainCategories.map((c) => c.id).toSet();
          final orphanedSubs = categories.where((c) => c.parentId != null && !knownMainIds.contains(c.parentId)).toList();
          for (final orphan in orphanedSubs) {
            items.add(_CategoryBannerCard(category: orphan, isSubcategory: true));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => items[index],
          );
        },
      ),
    );
  }

  void _openCategorySheet(BuildContext context, [Category? category]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CategoryEditSheet(category: category),
    );
  }
}

// ─── Banner Card ───────────────────────────────────────────────

class _CategoryBannerCard extends ConsumerWidget {
  final Category category;
  final bool isSubcategory;

  const _CategoryBannerCard({required this.category, required this.isSubcategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = category.imageUrl != null;

    return Padding(
      padding: EdgeInsets.only(left: isSubcategory ? 32 : 0),
      child: Container(
        height: isSubcategory ? 100 : 140,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Background (Image or Gradient Fallback)
            if (hasImage)
              Image.network(category.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _gradientFallback())
            else
              _gradientFallback(),

            // Layer 2: Gradient Overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.65)],
                ),
              ),
            ),

            // Layer 3: Category Name + Sub label
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isSubcategory)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Alt Kategori', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
                    ),
                  Row(
                    children: [
                      if (isSubcategory)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Text('↳', style: TextStyle(color: Colors.white70, fontSize: 18)),
                        ),
                      Expanded(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSubcategory ? 17 : 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (category.description != null && category.description!.isNotEmpty)
                    Text(
                      category.description!,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Layer 4: Action Buttons
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  _GlassIconButton(
                    icon: Icons.edit,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (ctx) => _CategoryEditSheet(category: category),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _GlassIconButton(
                    icon: Icons.delete_outline,
                    color: Colors.redAccent,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: const Text('Kategoriyi Sil?', style: TextStyle(color: Colors.black87)),
                          content: Text('${category.name} silinecek. Emin misiniz?', style: const TextStyle(color: Colors.black54)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Sil', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(categoriesProvider.notifier).deleteCategory(category.id);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientFallback() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isSubcategory
            ? [Colors.blueGrey.shade500, Colors.blueGrey.shade700]
            : [Colors.grey.shade700, Colors.grey.shade900],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  );
}

// ─── Glass Icon Button ─────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _GlassIconButton({required this.icon, required this.onTap, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.35),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

// ─── Category Edit Sheet (with Parent Dropdown) ────────────────

class _CategoryEditSheet extends ConsumerStatefulWidget {
  final Category? category;
  const _CategoryEditSheet({this.category});

  @override
  ConsumerState<_CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends ConsumerState<_CategoryEditSheet> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _pickedFile;
  String? _previewUrl;
  bool _isLoading = false;
  String? _selectedParentId; // null = Ana Kategori

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _previewUrl = widget.category!.imageUrl;
      _selectedParentId = widget.category!.parentId;
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
      // 1. Upload image if picked
      String? imageUrl = widget.category?.imageUrl;
      if (_pickedFile != null) {
        final storageService = ref.read(storageServiceProvider);
        imageUrl = await storageService.uploadCategoryImage(_pickedFile!);
      }

      // 2. Save category
      if (widget.category == null) {
        // Create new
        await ref.read(categoriesProvider.notifier).addCategory(
          name: name,
          imageUrl: imageUrl,
          parentId: _selectedParentId,
        );
      } else {
        // Update existing — use copyWith with clearParentId for null assignment
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
    final categoriesAsync = ref.watch(categoriesProvider);

    // Get main categories for the dropdown (exclude self if editing)
    final mainCategories = categoriesAsync.valueOrNull
        ?.where((c) => c.parentId == null && c.id != widget.category?.id)
        .toList() ?? [];

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
              Text(
                widget.category == null ? 'Yeni Kategori' : 'Kategori Düzenle',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Image Picker Area
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                image: hasLocalImage
                    ? DecorationImage(
                        image: NetworkImage(_pickedFile!.path),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : (hasNetworkImage
                        ? DecorationImage(image: NetworkImage(_previewUrl!), fit: BoxFit.cover)
                        : null),
              ),
              child: !hasLocalImage && !hasNetworkImage
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Görsel Seç', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                        ],
                      ),
                    )
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Değiştir', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Name Input
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Kategori Adı',
              labelStyle: const TextStyle(color: Colors.black54),
              hintText: 'Örn: Ana Yemekler',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Parent Category Dropdown ───
          DropdownButtonFormField<String?>(
            value: _selectedParentId,
            decoration: InputDecoration(
              labelText: 'Üst Kategori (Opsiyonel)',
              labelStyle: const TextStyle(color: Colors.black54),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Yok (Ana Kategori)', style: TextStyle(color: Colors.black54)),
              ),
              ...mainCategories.map((cat) => DropdownMenuItem<String?>(
                value: cat.id,
                child: Text(cat.name, style: const TextStyle(color: Colors.black87)),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedParentId = value;
              });
            },
          ),
          const SizedBox(height: 24),

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
                : Text(widget.category == null ? 'Oluştur' : 'Güncelle', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

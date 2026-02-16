import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_core/shared_core.dart';
import '../../products/application/categories_provider.dart';
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
              // Sort logic placeholder or separate screen
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sıralama yakında...')));
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
        onPressed: () => _showCategorySheet(context, ref),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Hata: $err')),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Henüz kategori yok', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryBannerCard(category: category);
            },
          );
        },
      ),
    );
  }

  void _showCategorySheet(BuildContext context, WidgetRef ref, [Category? category]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryEditSheet(category: category),
    );
  }
}

class _CategoryBannerCard extends ConsumerWidget {
  final Category category;

  const _CategoryBannerCard({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black, // Fallback color
        image: category.imageUrl != null
            ? DecorationImage(
                image: NetworkImage(category.imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (category.description != null)
                  Text(
                    category.description!,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Actions
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
                      backgroundColor: Colors.transparent,
                      builder: (context) => _CategoryEditSheet(category: category),
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
                      builder: (context) => AlertDialog(
                        title: const Text('Sil?'),
                        content: Text('${category.name} silinecek. Emin misiniz?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
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
          
          // No Image Fallback Gradient
          if (category.imageUrl == null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade800,
                      Colors.grey.shade900,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              )
            ),
            // Re-render content on top of fallback
             Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Re-render actions on top of fallback
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
                      backgroundColor: Colors.transparent,
                      builder: (context) => _CategoryEditSheet(category: category),
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
                      builder: (context) => AlertDialog(
                        title: const Text('Sil?'),
                        content: Text('${category.name} silinecek. Emin misiniz?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
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
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _GlassIconButton({required this.icon, required this.onTap, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.3),
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

class _CategoryEditSheet extends ConsumerStatefulWidget {
  final Category? category;

  const _CategoryEditSheet({this.category});

  @override
  ConsumerState<_CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends ConsumerState<_CategoryEditSheet> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Upload Image logic (Placeholder)
      String? imageUrl = widget.category?.imageUrl;
      if (_imageFile != null) {
        // TODO: Implement actual Supabase Storage upload
        // For now we just pretend or keep logic simple
        // imageUrl = await SupabaseStorage...
        // Assuming we have a service for this, or just ignoring for this specific task scope
        // as user said "Logic şimdilik dummy olabilir"
      }

      // 2. Save Category
      if (widget.category == null) {
        // Create
         await ref.read(categoriesProvider.notifier).addCategory(
            name: _nameController.text.trim(),
            // imageUrl: imageUrl, // Add support in provider
          );
      } else {
        // Update
        final updated = widget.category!.copyWith(
          name: _nameController.text.trim(),
          imageUrl: imageUrl, // Keep existing or new
        );
        await ref.read(categoriesProvider.notifier).updateCategory(updated);
      }

      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.category == null ? 'Yeni Kategori' : 'Kategori Düzenle',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),

          // Image Picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                image: _imageFile != null
                    ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                    : (widget.category?.imageUrl != null
                        ? DecorationImage(image: NetworkImage(widget.category!.imageUrl!), fit: BoxFit.cover)
                        : null),
              ),
              child: _imageFile == null && widget.category?.imageUrl == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Görsel Seç', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),

          // Name Input
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Kategori Adı',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFFAFAFA),
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          FilledButton(
            onPressed: _isLoading ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Kaydet', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

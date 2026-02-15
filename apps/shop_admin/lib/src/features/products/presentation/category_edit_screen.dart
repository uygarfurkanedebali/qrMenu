/// Category Edit Screen
///
/// Form for adding or editing a category.
/// Uploads category images using Phase 4 storage logic.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_core/shared_core.dart';
import '../data/mock_storage_service.dart';
import '../application/categories_provider.dart';
import 'package:shop_admin/src/features/auth/application/auth_provider.dart';

class CategoryEditScreen extends ConsumerStatefulWidget {
  final Category? category;
  final bool isSystemCategory; // New flag

  const CategoryEditScreen({
    super.key,
    this.category,
    this.isSystemCategory = false,
  });

  @override
  ConsumerState<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends ConsumerState<CategoryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 1. Initialize for System Category
    if (widget.isSystemCategory) {
      _nameController = TextEditingController(text: 'Tüm Ürünler (System)');
      _descController = TextEditingController(
        text: 'Tüm ürünlerin listelendiği ana kategori.',
      );
      // Fetch current banner from tenant provider if available
      final tenant = ref.read(currentTenantProvider);
      _imageUrl = tenant?.bannerUrl;
    } else {
      _nameController = TextEditingController(text: widget.category?.name);
      _descController = TextEditingController(
        text: widget.category?.description,
      );
      _imageUrl = widget.category?.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final service = ref.read(storageServiceProvider);

      // SWITCH: System Category -> Banner Upload
      final url = widget.isSystemCategory
          ? await service.uploadTenantBanner(image)
          : await service.uploadCategoryImage(image);

      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (widget.isSystemCategory) {
        // SAVE LOGIC: Update Tenant Banner
        final tenantId = ref.read(currentTenantIdProvider);
        if (tenantId == null) throw Exception('Tenant ID not found');

        // Use static method directly
        await ShopAuthService.updateTenantBanner(_imageUrl, tenantId);

        // Update local state to reflect changes immediately
        final currentTenant = ref.read(currentTenantProvider);
        if (currentTenant != null) {
          final updatedTenant = currentTenant.copyWith(bannerUrl: _imageUrl);
          ref.read(currentTenantProvider.notifier).state = updatedTenant;
        }
      } else if (widget.category == null) {
        // Add Normal Category
        await ref
            .read(categoriesProvider.notifier)
            .addCategory(
              name: _nameController.text,
              description: _descController.text.isEmpty
                  ? null
                  : _descController.text,
              imageUrl: _imageUrl,
            );
      } else {
        // Update Normal Category
        final updatedCategory = widget.category!.copyWith(
          name: _nameController.text,
          description: _descController.text.isEmpty
              ? null
              : _descController.text,
          imageUrl: _imageUrl,
        );
        await ref
            .read(categoriesProvider.notifier)
            .updateCategory(updatedCategory);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved successfully!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isSystemCategory
        ? 'Edit System Category'
        : (widget.category == null ? 'Add Category' : 'Edit Category');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : _imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo, size: 40),
                            Text(
                              widget.isSystemCategory
                                  ? 'Upload Banner Image'
                                  : 'Upload Category Image',
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
              if (widget.isSystemCategory)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Center(
                    child: Text(
                      'Bu banner "Tüm Ürünler" sayfasının tepesinde görünecektir.',
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              const Center(
                child: Text(
                  'Sadece JPG, PNG ve WEBP formatları desteklenir.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                readOnly:
                    widget.isSystemCategory, // Lock name for system category
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                readOnly:
                    widget.isSystemCategory, // Lock desc for system category
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.isSystemCategory
                            ? 'Save Banner'
                            : 'Save Category',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

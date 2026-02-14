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

class CategoryEditScreen extends ConsumerStatefulWidget {
  final Category? category;

  const CategoryEditScreen({super.key, this.category});

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
    _nameController = TextEditingController(text: widget.category?.name);
    _descController = TextEditingController(text: widget.category?.description);
    _imageUrl = widget.category?.imageUrl;
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
      final url = await service.uploadCategoryImage(image); // Phase 4 Logic
      
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final isGhostCategory = widget.category?.id == 'all_products';

      if (widget.category == null || isGhostCategory) {
        // Add New (or convert Ghost to Real)
        
        // Ensure [SYSTEM] tag for All Products
        String? finalDesc = _descController.text.isEmpty ? null : _descController.text;
        if (isGhostCategory) {
           if (finalDesc == null) {
             finalDesc = '[SYSTEM]';
           } else if (!finalDesc.contains('[SYSTEM]')) {
             finalDesc = '[SYSTEM] $finalDesc';
           }
        }

        await ref.read(categoriesProvider.notifier).addCategory(
          name: _nameController.text,
          description: finalDesc,
          imageUrl: _imageUrl,
        );
      } else {
        // Update
        final updatedCategory = widget.category!.copyWith(
          name: _nameController.text,
          description: _descController.text.isEmpty ? null : _descController.text,
          imageUrl: _imageUrl,
        );
        await ref.read(categoriesProvider.notifier).updateCategory(updatedCategory);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category saved!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      ),
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
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40),
                                Text('Upload Category Image'),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 8),
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
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

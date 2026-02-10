/// Product Edit Screen
/// 
/// Form for adding or editing products.
/// Uses dynamic tenant ID from auth state.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_core/shared_core.dart';
import '../data/mock_storage_service.dart';
import '../application/products_provider.dart';
import '../application/categories_provider.dart';
import '../../auth/application/auth_provider.dart';

class ProductEditScreen extends ConsumerStatefulWidget {
  final String? productId;

  const ProductEditScreen({super.key, this.productId});

  @override
  ConsumerState<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends ConsumerState<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  
  String? _selectedCategory;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.productId != null) {
      // Find product in provider
      final products = ref.read(productsProvider).valueOrNull;
      if (products != null) {
         try {
           final product = products.firstWhere((p) => p.id == widget.productId);
           _populateForm(product);
         } catch (_) {
           // Product not found locally
         }
      }
    }
  }
  
  void _populateForm(Product product) {
     if (_nameController.text.isNotEmpty) return; // Already populated
     
     _nameController.text = product.name;
     _priceController.text = product.price.toString();
     _descController.text = product.description ?? '';
     _selectedCategory = product.categoryId;
     _imageUrl = product.imageUrl;
     _isAvailable = product.isAvailable;
     setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final url = await ref.read(storageServiceProvider).uploadImage(image);
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
    
    // Get tenant ID from auth state
    final tenantId = ref.read(currentTenantIdProvider);
    if (tenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Not logged in')),
      );
      return;
    }
    
    setState(() => _isSaving = true);

    try {
      if (widget.productId == null) {
        // Add new product
        await ref.read(productsProvider.notifier).addProduct(
          name: _nameController.text,
          price: double.parse(_priceController.text),
          description: _descController.text.isEmpty ? null : _descController.text,
          categoryId: _selectedCategory,
          imageUrl: _imageUrl,
        );
      } else {
        // Update existing product
        final now = DateTime.now();
        final product = Product(
          id: widget.productId!,
          tenantId: tenantId,
          name: _nameController.text,
          price: double.parse(_priceController.text),
          description: _descController.text.isEmpty ? null : _descController.text,
          categoryId: _selectedCategory,
          imageUrl: _imageUrl,
          isAvailable: _isAvailable,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(productsProvider.notifier).updateProduct(product);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product saved successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = ref.watch(currentTenantProvider);
    
    // Show message if not logged in
    if (tenant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Product')),
        body: const Center(child: Text('Please log in first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Add Product' : 'Edit Product'),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'Demo Fill',
              onPressed: () {
                _nameController.text = 'Demo Burger';
                _priceController.text = '15.99';
                _descController.text = 'Delicious burger for testing.';
                setState(() {});
              },
            ),
        ],
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
                  height: 200,
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
                                errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image, size: 50)),
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40),
                                SizedBox(height: 8),
                                Text('Tap to upload image'),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 24),

              // Fields
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                   if (v == null || v.isEmpty) return 'Required';
                   if (double.tryParse(v) == null) return 'Must be a number';
                   return null;
                },
              ),
              const SizedBox(height: 16),

              // Real categories from Supabase
              Consumer(
                builder: (context, ref, _) {
                  final categoriesAsync = ref.watch(categoriesProvider);
                  return categoriesAsync.when(
                    loading: () => const InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('Loading categories...'),
                        ],
                      ),
                    ),
                    error: (err, _) => InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
                    ),
                    data: (categories) {
                      // Validate that _selectedCategory is still valid
                      if (_selectedCategory != null &&
                          !categories.any((c) => c.id == _selectedCategory)) {
                        // Selected category no longer exists, reset
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _selectedCategory = null);
                        });
                      }
                      return DropdownButtonFormField<String>(
                        value: _selectedCategory != null &&
                                categories.any((c) => c.id == _selectedCategory)
                            ? _selectedCategory
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: categories
                            .map((cat) => DropdownMenuItem(
                                  value: cat.id,  // Real UUID from database
                                  child: Text(cat.name),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v),
                        hint: categories.isEmpty
                            ? const Text('No categories yet')
                            : const Text('Select a category'),
                      );
                    },
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),
              
               SwitchListTile(
                title: const Text('Available'),
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
              ),

              const SizedBox(height: 32),
              
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

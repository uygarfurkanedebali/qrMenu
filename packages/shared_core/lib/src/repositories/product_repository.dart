/// Product Repository
/// 
/// Database operations for product management.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class ProductRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Fetch all products for a tenant
  Future<List<Product>> getProducts(String tenantId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('tenant_id', tenantId)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Fetch products by category
  Future<List<Product>> getProductsByCategory(String tenantId, String categoryId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('tenant_id', tenantId)
          .eq('category_id', categoryId)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Add a new product
  Future<Product> addProduct(Product product) async {
    try {
      final response = await _client
          .from('products')
          .insert(product.toJsonForInsert())
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  /// Update a product
  Future<Product> updateProduct(String id, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _client
          .from('products')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String id) async {
    try {
      await _client.from('products').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}

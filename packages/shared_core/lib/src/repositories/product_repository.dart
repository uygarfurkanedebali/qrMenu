/// Product Repository
/// 
/// Database operations for product management.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../config/env.dart';

class ProductRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Fetch all products for a tenant
  Future<List<Product>> getProducts(String tenantId) async {
    try {
      final response = await _client
          .from('products')
          .select('*, product_categories(category_id)')
          .eq('tenant_id', tenantId)
          .order('sort_order', ascending: true);

      final products = (response as List)
          .map((json) => Product.fromJson(json))
          .toList();

      // --- DEBUG BAŞLANGIÇ ---
      if (products.isNotEmpty) {
        print('🔎 TEST LOG: Toplam ${products.length} ürün çekildi.');
        final firstProduct = products.first;
        print('🔎 TEST LOG: İlk Ürün: ${firstProduct.name}');
        print('🔎 TEST LOG: İlk Ürün Kategori IDleri: ${firstProduct.categoryIds}');
        // Casting the first item to Map to access key
        print('🔎 TEST LOG: Ham JSON (product_categories): ${(response.first as Map)['product_categories']}');
      } else {
        print('🔎 TEST LOG: Hiç ürün bulunamadı!');
      }
      // --- DEBUG BİTİŞ ---

      return products;
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
  Future<Product> addProduct(Product product, {String? authToken}) async {
    try {
      // 💉 ISOLATED CLIENT STARTEGY (Phase 3)
      final clientToUse = authToken != null 
          ? SupabaseClient(Env.supabaseUrl, Env.supabaseAnonKey, headers: {'Authorization': 'Bearer $authToken'})
          : _client;

      if (authToken != null) {
        print('💉 [REPO] Using ISOLATED CLIENT for insert with explicit token.');
      }

      final response = await clientToUse
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
  Future<Product> updateProduct(String id, Map<String, dynamic> updates, {String? authToken}) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      // 💉 ISOLATED CLIENT STARTEGY (Phase 3)
      final clientToUse = authToken != null 
          ? SupabaseClient(Env.supabaseUrl, Env.supabaseAnonKey, headers: {'Authorization': 'Bearer $authToken'})
          : _client;

      if (authToken != null) {
        print('💉 [REPO] Using ISOLATED CLIENT for update with explicit token.');
      }
      
      final response = await clientToUse
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

/// Category Repository
/// 
/// Database operations for category management.
/// Categories group products within a tenant's menu.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class CategoryRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Fetch all categories for a tenant, ordered by sort_order
  Future<List<Category>> getCategories(String tenantId) async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('tenant_id', tenantId)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Fetch only visible categories for a tenant (for client menu)
  Future<List<Category>> getVisibleCategories(String tenantId) async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('tenant_id', tenantId)
          .eq('is_visible', true)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Add a new category
  Future<Category> addCategory({
    required String tenantId,
    required String name,
    String? description,
    String? imageUrl,
    int sortOrder = 0,
  }) async {
    try {
      final data = {
        'tenant_id': tenantId,
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'sort_order': sortOrder,
        'is_visible': true,
      };

      final response = await _client
          .from('categories')
          .insert(data)
          .select()
          .single();

      return Category.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  /// Update a category
  Future<Category> updateCategory(String id, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('categories')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Category.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String id) async {
    try {
      await _client.from('categories').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  /// Reorder categories (batch update)
  Future<void> reorderCategories(List<Category> categories) async {
    try {
      // Supabase doesn't support batch updates easily in one go for different values
      // So we'll loop. For < 50 categories this is fine.
      // Ideally we'd use a stored procedure or an upsert with unnest.
      for (int i = 0; i < categories.length; i++) {
        await _client
            .from('categories')
            .update({'sort_order': i})
            .eq('id', categories[i].id);
      }
    } catch (e) {
      throw Exception('Failed to reorder categories: $e');
    }
  }
}

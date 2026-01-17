/// Supabase Menu Repository
/// 
/// Fetches real menu data from Supabase database.
library;

import 'package:shared_core/shared_core.dart';
import '../domain/menu_models.dart';

/// Repository interface for menu operations
abstract class MenuRepository {
  /// Gets all categories with products for a tenant by slug
  Future<List<MenuCategory>> getMenuByTenantSlug(String slug);
}

/// Real implementation that fetches from Supabase
class SupabaseMenuRepository implements MenuRepository {
  @override
  Future<List<MenuCategory>> getMenuByTenantSlug(String slug) async {
    try {
      // First, get the tenant by slug
      final tenantResponse = await SupabaseService.client
          .from('tenants')
          .select('id, name')
          .eq('slug', slug)
          .maybeSingle();

      if (tenantResponse == null) {
        return [];
      }

      final tenantId = tenantResponse['id'] as String;

      // Fetch products for this tenant
      final productsResponse = await SupabaseService.client
          .from('products')
          .select('*')
          .eq('tenant_id', tenantId)
          .eq('is_available', true)
          .order('sort_order');

      final products = (productsResponse as List<dynamic>)
          .map((json) => Product.fromJson(json))
          .toList();

      if (products.isEmpty) {
        return [];
      }

      // Group products by category or create default category
      final Map<String, List<MenuProduct>> categoryProducts = {};
      
      for (final product in products) {
        final categoryId = product.categoryId ?? 'uncategorized';
        categoryProducts.putIfAbsent(categoryId, () => []);
        categoryProducts[categoryId]!.add(MenuProduct(
          id: product.id,
          tenantId: product.tenantId,
          categoryId: categoryId,
          name: product.name,
          description: product.description ?? '',
          price: product.price,
          imageUrl: product.imageUrl,
          isPopular: false,
          tags: [],
        ));
      }

      // Create menu categories
      final categories = <MenuCategory>[];
      int sortOrder = 0;

      // If all products are uncategorized, create a default category
      if (categoryProducts.containsKey('uncategorized')) {
        categories.add(MenuCategory(
          id: 'uncategorized',
          tenantId: tenantId,
          name: 'Menu',
          description: 'Our delicious offerings',
          sortOrder: sortOrder++,
          products: categoryProducts['uncategorized']!,
        ));
      }

      // Add other categories (fetch from categories table if needed)
      for (final entry in categoryProducts.entries) {
        if (entry.key != 'uncategorized') {
          categories.add(MenuCategory(
            id: entry.key,
            tenantId: tenantId,
            name: 'Category',
            description: '',
            sortOrder: sortOrder++,
            products: entry.value,
          ));
        }
      }

      return categories;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }
}

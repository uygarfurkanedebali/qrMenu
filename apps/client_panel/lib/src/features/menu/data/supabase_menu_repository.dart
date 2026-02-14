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
      // 1. Get Tenant ID
      final tenantResponse = await SupabaseService.client
          .from('tenants')
          .select('id')
          .eq('slug', slug)
          .maybeSingle();

      if (tenantResponse == null) return [];
      final tenantId = tenantResponse['id'] as String;

      // 2. Fetch Categories (Parallel fetch could be better but sequential is safer for now)
      final categoriesResponse = await SupabaseService.client
          .from('categories')
          .select()
          .eq('tenant_id', tenantId)
          .eq('is_visible', true)
          .order('sort_order', ascending: true);

      final categoriesData = List<Map<String, dynamic>>.from(categoriesResponse);

      // 3. Fetch Products
      final productsResponse = await SupabaseService.client
          .from('products')
          .select()
          .eq('tenant_id', tenantId)
          .eq('is_available', true)
          .order('sort_order', ascending: true);

      final productsData = List<Map<String, dynamic>>.from(productsResponse);

      // 4. Map Products to Categories
      final List<MenuCategory> menu = [];

      // Create a map for quick lookup if needed, but we'll iterate categories to preserve order
      // First, handle products with NO category (if any)
      final uncategorizedProducts = productsData
          .where((p) => p['category_id'] == null)
          .map((json) => MenuProduct(
                id: json['id'],
                tenantId: json['tenant_id'],
                categoryId: 'uncategorized',
                name: json['name'],
                description: json['description'],
                price: (json['price'] as num).toDouble(),
                imageUrl: json['image_url'],
                isAvailable: json['is_available'] ?? true,
                isPopular: json['is_popular'] ?? false,
              ))
          .toList();

      if (uncategorizedProducts.isNotEmpty) {
        menu.add(MenuCategory(
          id: 'uncategorized',
          tenantId: tenantId,
          name: 'Diğer Ürünler',
          description: null,
          iconUrl: null,
          sortOrder: -1,
          products: uncategorizedProducts,
        ));
      }

      // Now map real categories
      for (final catJson in categoriesData) {
        final catId = catJson['id'] as String;
        
        // Filter products for this category
        final catProducts = productsData
            .where((p) => p['category_id'] == catId)
            .map((json) => MenuProduct(
                  id: json['id'],
                  tenantId: json['tenant_id'],
                  categoryId: catId,
                  name: json['name'],
                  description: json['description'],
                  price: (json['price'] as num).toDouble(),
                  imageUrl: json['image_url'],
                  isAvailable: json['is_available'] ?? true,
                  isPopular: json['is_popular'] ?? false,
                ))
            .toList();

        // Only add category if it has products (optional, but good for menu cleanliness)
        // User didn't specify to hide empty categories, but usually we do.
        // Let's show them for now so user sees their categories even if empty.
        menu.add(MenuCategory(
          id: catId,
          tenantId: tenantId,
          name: catJson['name'],
          description: catJson['description'],
          iconUrl: catJson['image_url'], // Critical for Dynamic Banner!
          sortOrder: catJson['sort_order'] ?? 0,
          products: catProducts,
        ));
      }

      return menu;
    } catch (e) {
      print('Error fetching menu: $e');
      return [];
    }
  }
}

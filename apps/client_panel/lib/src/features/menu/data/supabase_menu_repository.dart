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
      // 1. Get Tenant Details (ID, Name, Banner)
      final tenantResponse = await SupabaseService.client
          .from('tenants')
          .select('id, name, banner_url')
          .eq('slug', slug)
          .maybeSingle();

      if (tenantResponse == null) return [];
      final tenantId = tenantResponse['id'] as String;
      final tenantBanner = tenantResponse['banner_url'] as String?;

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

      // 4. Map Products to Menu Objects
      final allMenuProducts = productsData.map((json) => MenuProduct(
        id: json['id'],
        tenantId: json['tenant_id'],
        categoryId: json['category_id'] ?? 'uncategorized',
        name: json['name'],
        description: json['description'],
        emoji: json['emoji'],
        variants: (json['variants'] as List<dynamic>?)
            ?.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
            .toList(),
        ingredients: (json['ingredients'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ?? const [],
        price: (json['price'] as num).toDouble(),
        imageUrl: json['image_url'],
        isAvailable: json['is_available'] ?? true,
        isPopular: json['is_popular'] ?? false,
        sortOrder: json['sort_order'] ?? 0,
      )).toList();

      final List<MenuCategory> menu = [];

      // ---------------------------------------------------------
      // 1. CHECK FOR DATABASE-BACKED "ALL PRODUCTS" (System Category)
      // ---------------------------------------------------------
      final systemCategory = categoriesData.firstWhere(
        (c) => (c['description'] as String?)?.contains('[SYSTEM]') ?? false,
        orElse: () => {},
      );

      // ---------------------------------------------------------
      // 2. MAP REAL CATEGORIES
      // ---------------------------------------------------------
      for (final catJson in categoriesData) {
        final catId = catJson['id'] as String;
        final desc = catJson['description'] as String?;
        final isSystemCategory = desc?.contains('[SYSTEM]') ?? false;
        
        List<MenuProduct> catProducts;

        if (isSystemCategory) {
           // If it's the system category, it contains ALL products
           catProducts = allMenuProducts;
        } else {
           // Otherwise, filter products for this specific category
           catProducts = allMenuProducts
              .where((p) => p.categoryId == catId) // TODO: Phase 3 Multi-Category Support
              .toList();
        }

        // Always add the category, even if it has no products yet
        menu.add(MenuCategory(
          id: catId,
          tenantId: tenantId,
          name: catJson['name'],
          description: desc?.replaceAll('[SYSTEM]', '').trim(), // Hide internal tag
          iconUrl: catJson['image_url'],
          parentId: catJson['parent_id'] as String?,
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

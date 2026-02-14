/// Products Provider (Supabase-backed)
/// 
/// Manages product state with real database operations.
/// Uses dynamic tenant ID from auth state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../../auth/application/auth_provider.dart';

/// Provider for the ProductRepository
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

/// Products provider using the authenticated tenant's ID
final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<Product>>(
  ProductsNotifier.new,
);

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    // Get tenant ID from auth state
    final tenantId = ref.watch(currentTenantIdProvider);
    
    if (tenantId == null) {
      // No tenant logged in, return empty
      return [];
    }
    
    try {
      final repository = ref.read(productRepositoryProvider);
      return await repository.getProducts(tenantId);
    } catch (e) {
      final errorStr = e.toString();
      // Check for auth/permission errors (RLS violations, 401, 403)
      if (errorStr.contains('401') || 
          errorStr.contains('403') ||
          errorStr.contains('JWT') ||
          errorStr.contains('permission denied') ||
          errorStr.contains('row-level security')) {
        // Auth error — don't auto-logout here, just return empty
        // The router guard will handle the redirect
        return [];
      }
      // Re-throw other errors so they show in the UI
      rethrow;
    }
  }

  /// Add a new product
  /// CRITICAL: tenant_id injection is MANDATORY — null = immediate abort
  Future<void> addProduct({
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    String? categoryId,
  }) async {
    // 1. İşlem başladığını bildir
    final previousState = state.valueOrNull ?? [];
    state = const AsyncValue.loading();

    try {
      // 2. Aktif dükkanı al
      final currentTenant = ref.read(currentTenantProvider);

      // 3. GÜVENLİK KONTROLÜ: Dükkan verisi var mı ve ID dolu mu?
      if (currentTenant == null || currentTenant.id.isEmpty) {
        print('❌ [FLUTTER] TENANT NULL veya EMPTY — ürün eklenemez!');
        throw Exception('Dükkan bilgisi yüklenemedi. Lütfen sayfayı yenileyip tekrar giriş yapın.');
      }

      final tenantId = currentTenant.id;
      print('📦 [FLUTTER] Ürün ekleniyor. Hedef Dükkan ID: $tenantId');

      // 4. Ürünü oluştur — tenant_id ZORUNLU enjekte
      final product = Product(
        id: '', // Server tarafından atanacak
        tenantId: tenantId,
        name: name,
        price: price,
        description: description,
        imageUrl: imageUrl,
        categoryId: categoryId,
        isAvailable: true,
        sortOrder: previousState.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('📤 [FLUTTER] Payload: ${product.toJsonForInsert()}');

      // 5. Repository'e gönder - Token Enjekte et (Phase 3)
      final token = ShopAuthService.currentSession?.accessToken;
      final repository = ref.read(productRepositoryProvider);
      
      if (token != null) {
        print('💉 [PROVIDER] Injecting Auth Token into Repository for addProduct...');
      } else {
        print('⚠️ [PROVIDER] No Auth Token found via ShopAuthService!');
      }

      await repository.addProduct(product, authToken: token);

      print('✅ [FLUTTER] Ürün başarıyla eklendi!');

      // 6. Listeyi yenile
      ref.invalidateSelf();
    } catch (e, st) {
      print('❌ [FLUTTER] Ürün ekleme hatası: $e');
      // Rollback
      state = AsyncData(previousState);
      rethrow;
    }
  }

  /// Delete a product (optimistic update)
  Future<void> deleteProduct(String productId) async {
    final previousState = state.valueOrNull ?? [];
    
    // Optimistic update
    state = AsyncData(
      previousState.where((p) => p.id != productId).toList(),
    );
    
    try {
      final repository = ref.read(productRepositoryProvider);
      await repository.deleteProduct(productId);
    } catch (e) {
      // Rollback on failure
      state = AsyncData(previousState);
      rethrow;
    }
  }

  /// Update a product
  Future<void> updateProduct(Product product) async {
    final previousState = state.valueOrNull ?? [];
    
    // Optimistic update
    state = AsyncData(
      previousState.map((p) => p.id == product.id ? product : p).toList(),
    );
    
    try {
      final token = ShopAuthService.currentSession?.accessToken;
      final repository = ref.read(productRepositoryProvider);
      
      if (token != null) {
        print('💉 [PROVIDER] Injecting Auth Token into Repository for updateProduct...');
      }

      await repository.updateProduct(product.id, product.toJson(), authToken: token);
    } catch (e) {
      // Rollback on failure
      state = AsyncData(previousState);
      rethrow;
    }
  }
}

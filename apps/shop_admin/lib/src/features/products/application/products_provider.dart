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

  /// Add a new product (uses tenant ID from auth state)
  Future<void> addProduct({
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    String? categoryId,
  }) async {
    final tenantId = ref.read(currentTenantIdProvider);
    if (tenantId == null) {
      throw Exception('Not logged in');
    }

    final previousState = state.valueOrNull ?? [];
    
    final product = Product(
      id: '', // Will be set by server
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
    
    // Optimistic update
    state = AsyncData([...previousState, product]);
    
    try {
      final repository = ref.read(productRepositoryProvider);
      await repository.addProduct(product);
      
      // Refresh from server to ensure consistency
      ref.invalidateSelf();
    } catch (e) {
      // Rollback on failure
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
      final repository = ref.read(productRepositoryProvider);
      await repository.updateProduct(product.id, product.toJson());
    } catch (e) {
      // Rollback on failure
      state = AsyncData(previousState);
      rethrow;
    }
  }
}

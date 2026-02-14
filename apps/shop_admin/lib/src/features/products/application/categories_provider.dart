/// Categories Provider (Supabase-backed)
/// 
/// Manages category state for the current tenant.
/// Used by ProductEditScreen to populate the category dropdown.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../../auth/application/auth_provider.dart';

/// Provider for the CategoryRepository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

/// Categories provider - fetches real categories from Supabase
/// Automatically re-fetches when tenant changes
final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
  CategoriesNotifier.new,
);

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final tenantId = ref.watch(currentTenantIdProvider);

    if (tenantId == null) {
      return [];
    }

    final repository = ref.read(categoryRepositoryProvider);
    return repository.getCategories(tenantId);
  }

  /// Add a new category
  Future<void> addCategory({
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    final tenantId = ref.read(currentTenantIdProvider);
    if (tenantId == null) throw Exception('Not logged in');

    final token = _getToken();
    final repository = ref.read(categoryRepositoryProvider);
    
    await repository.addCategory(
      tenantId: tenantId,
      name: name,
      description: description,
      imageUrl: imageUrl,
      sortOrder: (state.valueOrNull?.length ?? 0),
      authToken: token,
    );

    // Refresh from server
    ref.invalidateSelf();
  }



  /// Update a category
  Future<void> updateCategory(Category category) async {
    final token = _getToken();
    final repository = ref.read(categoryRepositoryProvider);
    await repository.updateCategory(category.id, category.toJson(), authToken: token);
    ref.invalidateSelf();
  }

  /// Reorder categories
  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final currentList = state.valueOrNull;
    if (currentList == null) return;

    // 1. Optimistic Update
    final items = List<Category>.from(currentList);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    
    state = AsyncData(items);

    // 2. Persist to DB
    try {
      final token = _getToken();
      final repository = ref.read(categoryRepositoryProvider);
      await repository.reorderCategories(items, authToken: token);
    } catch (e) {
      // Revert on failure
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    final token = _getToken();
    final repository = ref.read(categoryRepositoryProvider);
    await repository.deleteCategory(categoryId, authToken: token);
    ref.invalidateSelf();
  }

  String _getToken() {
    final session = ShopAuthService.currentSession;
    final token = session?.accessToken;
    if (token == null) {
      throw Exception('Session expired. Please login again.');
    }
    return token;
  }
}

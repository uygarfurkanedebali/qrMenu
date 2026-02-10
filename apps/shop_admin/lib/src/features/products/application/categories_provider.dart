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
  }) async {
    final tenantId = ref.read(currentTenantIdProvider);
    if (tenantId == null) throw Exception('Not logged in');

    final repository = ref.read(categoryRepositoryProvider);
    await repository.addCategory(
      tenantId: tenantId,
      name: name,
      description: description,
      sortOrder: (state.valueOrNull?.length ?? 0),
    );

    // Refresh from server
    ref.invalidateSelf();
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    final repository = ref.read(categoryRepositoryProvider);
    await repository.deleteCategory(categoryId);
    ref.invalidateSelf();
  }
}

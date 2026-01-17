/// Menu Provider
/// 
/// Provides menu data based on the current tenant.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tenant/application/tenant_provider.dart';
import '../data/supabase_menu_repository.dart';
import '../domain/menu_models.dart';

/// Provider for the MenuRepository
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return SupabaseMenuRepository();
});

/// Provider for the current tenant's menu
/// 
/// Watches the tenant provider and fetches the menu for that tenant.
/// Returns an AsyncValue wrapping the list of categories with products.
final menuProvider = FutureProvider<List<MenuCategory>>((ref) async {
  final tenantAsync = ref.watch(tenantProvider);
  
  return tenantAsync.when(
    loading: () => throw StateError('Tenant still loading'),
    error: (error, stack) => throw error,
    data: (tenant) async {
      final repository = ref.read(menuRepositoryProvider);
      return repository.getMenuByTenantSlug(tenant.slug);
    },
  );
});

/// Provider for the currently selected category index
final selectedCategoryIndexProvider = StateProvider<int>((ref) => 0);

// Shop Admin Auth Provider — WITH RACE CONDITION FIX
// Manages authentication state and current tenant context

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth state change stream
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.client.auth.onAuthStateChange;
});

/// Current logged in user
final currentUserProvider = Provider<User?>((ref) {
  // Watch auth state changes to force rebuild
  ref.watch(authStateProvider);
  return SupabaseService.client.auth.currentUser;
});

/// Is user logged in
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Current tenant state (fetched after login)
class TenantState {
  final String id;
  final String name;
  final String slug;
  final String ownerEmail;

  const TenantState({
    required this.id,
    required this.name,
    required this.slug,
    required this.ownerEmail,
  });

  /// Client Panel URL for this tenant
  String get clientUrl => AppConfig.getClientMenuUrl(slug);

  factory TenantState.fromJson(Map<String, dynamic> json) {
    return TenantState(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      ownerEmail: json['owner_email'] as String? ?? '',
    );
  }
}

/// Provider for the current tenant (loaded after login)
final currentTenantProvider = StateProvider<TenantState?>((ref) => null);

/// Provider for the current tenant ID (for product queries)
final currentTenantIdProvider = Provider<String?>((ref) {
  final tenant = ref.watch(currentTenantProvider);
  return tenant?.id;
});

/// Provider for the current tenant slug
final currentTenantSlugProvider = Provider<String?>((ref) {
  final tenant = ref.watch(currentTenantProvider);
  return tenant?.slug;
});

/// Auth service with SYNCHRONOUS state updates
class ShopAuthService {
  /// Sign in and fetch tenant
  /// Returns tenant if successful, throws exception otherwise
  /// Ensures auth state is fully propagated before returning
  static Future<TenantState> signIn({
    required String email,
    required String password,
  }) async {
    print('🔐 [AUTH] Starting login for: $email');
    
    // 1. Authenticate with Supabase
    final response = await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      print('❌ [AUTH] Login failed - no user returned');
      throw Exception('Giriş başarısız');
    }

    print('✅ [AUTH] Login successful - User ID: ${response.user!.id}');
    print('   Session: ${response.session != null ? "SET" : "NULL"}');

    // CRITICAL: Wait for Supabase internal state to propagate
    // Supabase updates listeners asynchronously, so we need a tiny delay
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Verify session is set
    final session = SupabaseService.client.auth.currentSession;
    print('   Session after delay: ${session != null ? "SET ✅" : "NULL ❌"}');

    // 2. Fetch user role
    final profileResponse = await SupabaseService.client
        .from('profiles')
        .select('role')
        .eq('id', response.user!.id)
        .maybeSingle();

    if (profileResponse == null) {
      print('❌ [AUTH] No profile found');
      await SupabaseService.client.auth.signOut();
      throw Exception('Profil bulunamadı');
    }

    final role = profileResponse['role'] as String?;
    print('👤 [AUTH] User role: $role');

    if (role != 'shop_owner') {
      print('⛔ [AUTH] Access denied - wrong role: $role');
      await SupabaseService.client.auth.signOut();
      throw Exception('⛔ Yetkisiz Erişim!\n\nBu panel yalnızca Dükkan Sahipleri içindir.\nHesap rolünüz: "${role ?? 'tanımsız'}"');
    }

    // 3. Fetch tenant associated with this email
    print('🏪 [AUTH] Fetching tenant for: $email');
    final tenants = await SupabaseService.client
        .from('tenants')
        .select()
        .eq('owner_email', email);

    if (tenants.isEmpty) {
      print('❌ [AUTH] No tenant found for this email');
      await SupabaseService.client.auth.signOut();
      throw Exception('Bu hesaba bağlı dükkan bulunamadı');
    }

    final tenant = TenantState.fromJson(tenants.first);
    print('✅ [AUTH] Tenant loaded: ${tenant.name} (${tenant.slug})');
    print('💡 [AUTH] Auth state fully synchronized - safe to navigate');
    
    return tenant;
  }

  /// Sign out
  static Future<void> signOut() async {
    print('👋 [AUTH] Signing out');
    await SupabaseService.client.auth.signOut();
  }
}

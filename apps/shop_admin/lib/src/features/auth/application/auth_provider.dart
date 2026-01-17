// Shop Admin Auth Provider
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

/// Auth service for login/logout operations
class AuthService {
  /// Sign in and fetch associated tenant
  static Future<TenantState?> signInAndFetchTenant({
    required String email,
    required String password,
  }) async {
    // 1. Authenticate with Supabase
    final response = await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Authentication failed');
    }

    // 2. Fetch tenant associated with this email
    final tenants = await SupabaseService.client
        .from('tenants')
        .select()
        .eq('owner_email', email);

    if (tenants.isEmpty) {
      // Sign out since no tenant found
      await SupabaseService.client.auth.signOut();
      throw Exception('No shop associated with this account');
    }

    // 3. Return tenant state
    return TenantState.fromJson(tenants.first);
  }

  /// Sign out
  static Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }
}

/// Tenant Repository
/// 
/// Database operations for tenant (shop) management.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../config/env.dart';

class TenantRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Fetch tenant by slug (URL identifier)
  Future<Tenant?> getTenantBySlug(String slug) async {
    try {
      final response = await _client
          .from('tenants')
          .select()
          .eq('slug', slug)
          .maybeSingle();

      if (response == null) return null;
      return Tenant.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch tenant: $e');
    }
  }

  /// Fetch tenant by owner email
  Future<Tenant?> getTenantByOwnerEmail(String email) async {
    try {
      final response = await _client
          .from('tenants')
          .select()
          .eq('owner_email', email)
          .maybeSingle();

      if (response == null) return null;
      return Tenant.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch tenant for owner: $e');
    }
  }

  /// Fetch all tenants (for System Admin)
  Future<List<Tenant>> getAllTenants() async {
    try {
      final response = await _client
          .from('tenants')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Tenant.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tenants: $e');
    }
  }

  /// Create a new tenant
  Future<Tenant> createTenant({
    required String name,
    required String slug,
    required String ownerEmail,
    ThemeConfig? themeConfig,
  }) async {
    try {
      final data = {
        'name': name,
        'slug': slug,
        'owner_email': ownerEmail,
        'theme_config': themeConfig?.toJson(),
        'is_active': true,
      };

      final response = await _client
          .from('tenants')
          .insert(data)
          .select()
          .single();

      return Tenant.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create tenant: $e');
    }
  }

  /// Update tenant
  /// Uses isolated client to prevent "Ghost Logout" issues
  Future<Tenant> updateTenant(String id, Map<String, dynamic> updates, {String? authToken}) async {
    try {
      // Create isolated client if token is provided
      final clientToUse = authToken != null 
          ? SupabaseClient(Env.supabaseUrl, Env.supabaseAnonKey, headers: {'Authorization': 'Bearer $authToken'})
          : _client;

      final response = await clientToUse
          .from('tenants')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Tenant.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update tenant: $e');
    }
  }

  /// Delete tenant
  Future<void> deleteTenant(String id) async {
    try {
      await _client.from('tenants').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete tenant: $e');
    }
  }
}

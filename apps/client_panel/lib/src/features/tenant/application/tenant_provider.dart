/// Tenant Provider - Resolves tenant from URL
/// 
/// This provider is responsible for:
/// 1. Reading the current URL (subdomain or path)
/// 2. Fetching the tenant from the repository
/// 3. Providing the tenant to the rest of the app
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

/// Provider for the TenantRepository
final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return TenantRepository();
});

/// Provider for the current tenant slug extracted from URL
final currentSlugProvider = StateProvider<String?>((ref) {
  // This will be set by the router when parsing the URL
  return null;
});

/// Async provider that fetches and caches the current tenant
final tenantProvider = FutureProvider<Tenant>((ref) async {
  final repository = ref.watch(tenantRepositoryProvider);
  final slug = ref.watch(currentSlugProvider);
  
  if (slug == null || slug.isEmpty) {
    throw TenantNotFoundException('No tenant slug provided');
  }
  
  final tenant = await repository.getTenantBySlug(slug);
  
  if (tenant == null) {
    throw TenantNotFoundException('Tenant not found: $slug');
  }
  
  return tenant;
});

/// Utility to extract tenant slug from URL
/// 
/// Supports two modes:
/// 1. Path-based: /shop-name/menu (for local development)
/// 2. Subdomain-based: shop-name.qrinfinity.com (for production)
class TenantResolver {
  /// Extracts the tenant slug from the current URL
  /// 
  /// For local development, uses path: localhost:8080/kebab-shop
  /// For production, uses subdomain: kebab-shop.qrinfinity.com
  static String? extractSlugFromUri(Uri uri) {
    // PRIORITY 1: Path-based routing (most reliable)
    // Pattern: /shop-name or /shop-name/menu or /shop-name/shopadmin
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      final firstSegment = pathSegments.first;
      // Ignore reserved paths
      if (firstSegment != 'systemadmin' && 
          firstSegment != 'menu' && 
          firstSegment != 'shopadmin' &&
          firstSegment.isNotEmpty) {
        return firstSegment;
      }
    }
    
    // PRIORITY 2: Subdomain pattern (legacy support)
    // Pattern: shop-name.qrinfinity.com or shop-name.localhost
    final host = uri.host;
    final hostParts = host.split('.');
    
    if (hostParts.length >= 3 && hostParts[0] != 'www') {
      // Only use subdomain if it looks like: subdomain.domain.tld
      final potentialSlug = hostParts[0];
      // Ignore localhost and IP addresses
      if (potentialSlug != 'localhost' && 
          potentialSlug != '127' &&
          !potentialSlug.contains('192') &&
          !potentialSlug.startsWith('qr')) {  // Ignore qrmenutest etc
        return potentialSlug;
      }
    }
    
    return null;
  }
  
  /// Gets the slug from the current browser URL
  static String? getCurrentSlug() {
    if (kIsWeb) {
      return extractSlugFromUri(Uri.base);
    }
    // For mobile, you might get this from deep links or navigation
    return null;
  }
}

/// Exception thrown when a tenant cannot be found
class TenantNotFoundException implements Exception {
  final String message;
  
  const TenantNotFoundException(this.message);
  
  @override
  String toString() => 'TenantNotFoundException: $message';
}

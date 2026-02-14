/// Environment Configuration
/// 
/// Stores Supabase credentials and app URLs.
/// Replace placeholder values with your actual keys.
library;

// Removed dart:html import for Wasm compatibility

class Env {
  /// Supabase Project URL
  /// Example: https://xxxx.supabase.co
  static const String supabaseUrl = 'https://jswvvrxpjvsdqcayynzi.supabase.co';

  /// Supabase Anon (Public) Key
  /// Used for client-side access with RLS protection
  static const String supabaseAnonKey = 'sb_publishable_yTzYbYSrqu5KBh0DapG7Xg_mwbns3i5';

  /// Check if credentials are configured
  static bool get isConfigured =>
      supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
}

/// App Configuration
/// 
/// Dynamic URL configuration based on browser location.
/// No hardcoded IPs or domains - everything is derived from window.location.
class AppConfig {
  /// Get the base URL dynamically from browser/platform
  /// Returns: http://domain.com or http://192.168.1.100:80
  static String get baseUrl {
    return '${Uri.base.scheme}://${Uri.base.host}${Uri.base.hasPort ? ':${Uri.base.port}' : ''}';
  }

  /// Get the current origin (same as baseUrl)
  static String get origin => baseUrl;

  /// Get the System Admin URL
  /// Returns: {origin}/systemadmin
  static String get systemAdminUrl => '$origin/systemadmin';

  /// Get the Shop Admin URL for a specific tenant
  /// Returns: {origin}/{slug}/shopadmin
  static String getShopAdminUrl([String? slug]) {
    if (slug != null && slug.isNotEmpty) {
      return '$origin/$slug/shopadmin';
    }
    return '$origin/shopadmin';
  }

  /// Shop Admin Base URL template (for display purposes)
  /// Returns: {origin}/{slug}/shopadmin
  static String get shopAdminBaseUrl => '$origin/{slug}/shopadmin';

  /// Get the Client Menu URL for a specific tenant
  /// Returns: {origin}/{slug}/menu
  static String getClientMenuUrl(String slug) {
    return '$origin/$slug/menu';
  }

  /// Get Client Menu direct URL (short form)
  /// Returns: {origin}/{slug}
  static String getClientDirectUrl(String slug) {
    return '$origin/$slug';
  }

  /// Client Panel Base URL (for display purposes)
  static String get clientPanelBaseUrl => origin;

  /// Build a full URL path relative to origin
  static String buildPath(String path) {
    if (path.startsWith('/')) {
      return '$origin$path';
    }
    return '$origin/$path';
  }
}

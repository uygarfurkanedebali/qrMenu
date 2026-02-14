// Shop Admin Auth Provider — NO AUTO-LOGOUT VERSION
// Manages authentication state and current tenant context
// CRITICAL: Never calls signOut() automatically - lets UI handle errors

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
  // Shop Settings
  final String primaryColor;
  final String fontFamily;
  final String currencySymbol;
  final String? phoneNumber;
  final String? instagramHandle;
  final String? wifiName;
  final String? wifiPassword;

  const TenantState({
    required this.id,
    required this.name,
    required this.slug,
    required this.ownerEmail,
    this.primaryColor = '#FF5722',
    this.fontFamily = 'Roboto',
    this.currencySymbol = '₺',
    this.phoneNumber,
    this.instagramHandle,
    this.wifiName,
    this.wifiPassword,
  });

  /// Client Panel URL for this tenant
  String get clientUrl => AppConfig.getClientMenuUrl(slug);

  factory TenantState.fromJson(Map<String, dynamic> json) {
    return TenantState(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      ownerEmail: json['owner_email'] as String? ?? '',
      primaryColor: json['primary_color'] as String? ?? '#FF5722',
      fontFamily: json['font_family'] as String? ?? 'Roboto',
      currencySymbol: json['currency_symbol'] as String? ?? '₺',
      phoneNumber: json['phone_number'] as String?,
      instagramHandle: json['instagram_handle'] as String?,
      wifiName: json['wifi_name'] as String?,
      wifiPassword: json['wifi_password'] as String?,
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

/// Auth service - TOLERANT VERSION WITH LOGIN SHIELD
/// NEVER calls signOut() automatically
/// Throws exceptions for UI to handle
/// Includes shield to prevent ghost signedOut events during login
class ShopAuthService {
  /// Login shield flag - prevents ghost signedOut events during login
  static bool _isPerformingLogin = false;
  
  /// Manual session cache - buffers against Supabase race conditions
  static Session? _manualSession;
  
  /// Check if login is currently in progress (for AuthNotifier)
  static bool get isPerformingLogin => _isPerformingLogin;
  
  /// Get current session (prioritizes manual cache during race conditions)
  static Session? get currentSession => _manualSession ?? SupabaseService.client.auth.currentSession;
  
  /// Sign in and fetch tenant
  /// IMPORTANT: Does NOT auto-logout on validation failure
  /// Throws exceptions with user-friendly messages
  /// PROTECTED: Ignores ghost signedOut events during execution
  static Future<TenantState> signIn({
    required String email,
    required String password,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // 🛡️ ACTIVATE LOGIN SHIELD
      _isPerformingLogin = true;
      print('═══════════════════════════════════════════════════════');
      print('🛡️ [AUTH SHIELD] LOGIN SHIELD ACTIVATED');
      print('🕒 [AUTH] ${startTime.toIso8601String()}');
      print('🔐 [AUTH] signIn() STARTED for: $email');
      print('═══════════════════════════════════════════════════════');
      
      // 1. Authenticate with Supabase
      print('⏳ [AUTH] Step 1/3: Calling Supabase signInWithPassword...');
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        print('❌ [AUTH] FAILED - No user returned from Supabase');
        throw Exception('Giriş başarısız - kullanıcı bilgisi alınamadı');
      }

      // 🛡️ FORCE SESSION UPDATE
      // Manually ensuring session is set to override any ghost events
      _manualSession = response.session;
      print('🛡️ [AUTH SHIELD] Manual session cached: ${_manualSession?.user.id}');

      print('✅ [AUTH] Supabase signIn SUCCESS');
      print('   User ID: ${response.user!.id}');
      print('   Session exists: ${response.session != null}');
      print('   Session token: ${response.session?.accessToken?.substring(0, 20) ?? "NULL"}...');

      // CRITICAL: Wait for Supabase internal state to propagate
      print('⏳ [AUTH] Waiting 50ms for Supabase state propagation...');
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Verify session is set (checking our getter now)
      final session = ShopAuthService.currentSession;
      print('🔍 [AUTH] Session verification after delay:');
      print('   currentSession exists: ${session != null}');
      print('   currentUser exists: ${SupabaseService.client.auth.currentUser != null}');

      // 2. Fetch user role (NO AUTO-LOGOUT if fails)
      print('⏳ [AUTH] Step 2/3: Fetching user profile...');
      try {
        final profileResponse = await SupabaseService.client
            .from('profiles')
            .select('role')
            .eq('id', response.user!.id)
            .maybeSingle();

        if (profileResponse == null) {
          print('❌ [AUTH] Profile fetch FAILED - NULL response (NOT signing out)');
          throw Exception('Profil bulunamadı.\n\nLütfen sistem yöneticinizle iletişime geçin.');
        }

        final role = profileResponse['role'] as String?;
        print('✅ [AUTH] Profile fetched successfully');
        print('   User role: $role');

        if (role != 'shop_owner') {
          print('⛔ [AUTH] Access DENIED - Wrong role: $role (NOT signing out)');
          throw Exception('⛔ Yetkisiz Erişim!\n\nBu panel yalnızca Dükkan Sahipleri içindir.\nHesap rolünüz: "${role ?? 'tanımsız'}"\n\nLütfen doğru hesapla giriş yapın.');
        }
        
        print('✅ [AUTH] Role verification PASSED - user is shop_owner');
      } catch (e) {
        if (e is Exception && e.toString().contains('Exception:')) {
          rethrow;
        }
        print('❌ [AUTH] Profile check exception: $e');
        throw Exception('Profil doğrulaması başarısız: ${e.toString()}');
      }

      // 3. Fetch tenant (NO AUTO-LOGOUT if fails)
      print('⏳ [AUTH] Step 3/3: Fetching tenant for email: $email');
      try {
        final tenants = await SupabaseService.client
            .from('tenants')
            .select()
            .eq('owner_email', email);

        if (tenants.isEmpty) {
          print('❌ [AUTH] Tenant fetch FAILED - Empty result (NOT signing out)');
          throw Exception('Bu hesaba bağlı dükkan bulunamadı.\n\nLütfen sistem yöneticinizle iletişime geçin.');
        }

        final tenant = TenantState.fromJson(tenants.first);
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        
        print('✅ [AUTH] Tenant loaded successfully!');
        print('   Tenant ID: ${tenant.id}');
        print('   Tenant name: ${tenant.name}');
        print('   Tenant slug: ${tenant.slug}');
        print('   Owner email: ${tenant.ownerEmail}');
        print('💡 [AUTH] Auth state fully synchronized - SAFE TO NAVIGATE');
        print('⏱️  [AUTH] Total signIn duration: ${duration.inMilliseconds}ms');
        print('═══════════════════════════════════════════════════════');
        
        return tenant;
      } catch (e) {
        if (e is Exception && e.toString().contains('Exception:')) {
          rethrow;
        }
        print('❌ [AUTH] Tenant fetch exception: $e');
        throw Exception('Dükkan bilgisi yüklenemedi: ${e.toString()}');
      }
    } finally {
      // 🛡️ DEACTIVATE LOGIN SHIELD - Always runs, even on error
      print('🛡️ [AUTH SHIELD] LOGIN SHIELD DEACTIVATED');
      _isPerformingLogin = false;
    }
  }

  /// Sign out (manual only)
  static Future<void> signOut() async {
    print('═══════════════════════════════════════════════════════');
    print('👋 [AUTH] MANUAL SIGN OUT initiated');
    print('═══════════════════════════════════════════════════════');
    
    // Clear manual session cache
    _manualSession = null;
    
    await SupabaseService.client.auth.signOut();
    print('✅ [AUTH] Sign out complete');
  }
}

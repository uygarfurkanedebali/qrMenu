/// Shop Admin Router — RACE CONDITION FIX
/// 
/// Uses refreshListenable to watch auth state changes
/// Checks both provider state AND Supabase session directly
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../layouts/admin_layout.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/products/presentation/products_list_screen.dart';
import '../features/products/presentation/product_edit_screen.dart';
import '../features/menu_manager/presentation/menu_explorer_screen.dart';
import '../features/products/presentation/quick_product_manager_screen.dart';
import '../features/settings/presentation/settings_screen.dart'; // Exporting ShopSettingsScreen class
import '../features/qr_studio/presentation/qr_studio_screen.dart';
import '../features/auth/application/auth_provider.dart';

/// Tracks whether role has been verified for the current session
final roleVerifiedProvider = StateProvider<bool>((ref) => false);

/// Tracks role check error messages to display on login screen
final roleErrorProvider = StateProvider<String?>((ref) => null);

/// Auth change notifier for router refresh
/// PROTECTED: Ignores ghost signedOut events during login
class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    // Listen to Supabase auth state changes
    SupabaseService.client.auth.onAuthStateChange.listen((event) {
      print('🔔 [AUTH NOTIFIER] Auth state changed: ${event.event}');
      
      // 🛡️ LOGIN SHIELD: Ignore ghost signedOut during active login
      if (ShopAuthService.isPerformingLogin && event.event == AuthChangeEvent.signedOut) {
        print('🛡️ [AUTH SHIELD] BLOCKED ghost signedOut event!');
        print('   Login in progress - ignoring premature logout signal');
        
        // 💉 STRATEGY A REVISED: RESURRECTION IN LISTENER
        // Ghost logout happened. We have the session in ShopAuthService.
        // We must tell Supabase client to wake up.
        final validSession = ShopAuthService.currentSession;
        if (validSession != null && validSession.refreshToken != null) {
           print('👻 [AUTH FIX] Listener detected ghost logout! Bypassing API to resurrect client...');
           // We execute this asynchronously
           SupabaseService.client.auth.setSession(validSession.refreshToken!).then((_) {
               print('✅ [AUTH FIX] Client memory resurrected successfully!');
           }).catchError((err) {
               print('❌ [AUTH FIX] Local memory injection failed: $err');
           });
        }
        
        return; // DO NOT notifyListeners - prevents router kick
      }
      
      print('🔔 [AUTH NOTIFIER] Notifying listeners (router will refresh)');
      notifyListeners(); // Trigger router refresh
    });
  }
}

final authNotifierProvider = Provider<AuthNotifier>((ref) => AuthNotifier());

/// Helper function to extract shopId from the current web URL if available
String? _extractShopIdFromUrl(String url) {
  try {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    if (segments.isNotEmpty && segments.first != 'login' && segments.first != 'shopadmin') {
      return segments.first;
    }
  } catch (_) {}
  return null;
}

// GoRouter with refresh listenable
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);
  
  return GoRouter(
    initialLocation: '/shopadmin', // DIRECT ENTRY POINT -> PROTECTED BY REDIRECT
    refreshListenable: authNotifier, // CRITICAL: Router rebuilds on auth changes
    redirect: (context, state) {
      print('╔═══════════════════════════════════════════════════════╗');
      print('║ 🧭 [ROUTER] REDIRECT CHECK                            ║');
      print('╠═══════════════════════════════════════════════════════╣');
      print('║ Time: ${DateTime.now().toIso8601String()}');
      
      // ROBUST CHECK: Use both Supabase session (via wrapper) AND provider state
      // Using ShopAuthService.currentSession handles race conditions where Supabase
      // might temporarily show null session during ghost events.
      final session = ShopAuthService.currentSession;
      final roleVerified = ref.read(roleVerifiedProvider);
      
      final isLoggedIn = session != null;
      final isOnLoginPage = state.matchedLocation.endsWith('/login');

      print('║ Location: ${state.matchedLocation}');
      print('║ Target URI: ${state.uri}');
      print('╠═══════════════════════════════════════════════════════╣');
      print('║ STATE CHECKS:');
      print('║   • Session exists: ${isLoggedIn ? "✅ YES" : "❌ NO"}');
      if (session != null) {
        print('║     - User ID: ${session.user.id}');
        print('║     - Expires: ${session.expiresAt != null ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000).toIso8601String() : "NULL"}');
      }
      print('║   • Role verified: ${roleVerified ? "✅ TRUE" : "❌ FALSE"}');
      print('║   • On login page: ${isOnLoginPage ? "YES" : "NO"}');
      print('╠═══════════════════════════════════════════════════════╣');

      String? decision;

      // Rule 1: Not logged in → force login page
      if (!isLoggedIn && !isOnLoginPage) {
        decision = '/login';
        print('║ DECISION RULE 1: Not authenticated');
        print('║   → Redirecting to: /login');
      }
      // Rule 2: Logged in + on login page + role verified → go to dashboard
      else if (isLoggedIn && isOnLoginPage && roleVerified) {
        final tenant = ref.read(currentTenantProvider);
        final shopId = tenant?.slug ?? _extractShopIdFromUrl(state.uri.toString());
        decision = (shopId != null && shopId.isNotEmpty) ? '/$shopId/shopadmin' : '/shopadmin';
        
        // Prevent infinite redirect to itself if already there
        if (state.matchedLocation == decision) {
           decision = null;
        }

        print('║ DECISION RULE 2: Authenticated & verified');
        print('║   → Redirecting to: \$decision');
      }
      // Rule 3: Logged in but trying to access protected route without role verification
      else if (isLoggedIn && !isOnLoginPage && !roleVerified) {
        decision = '/login';
        print('║ DECISION RULE 3: Session exists but role NOT verified');
        print('║   → Redirecting to: /login (need verification)');
      }
      // No redirect needed
      else {
        print('║ DECISION: No redirect needed');
        print('║   ✅ Allowing navigation to: ${state.matchedLocation}');
      }

      print('╚═══════════════════════════════════════════════════════╝');
      return decision;
    },
    routes: [
      // We can also have a generic /login fallback
      GoRoute(
        path: '/login',
        redirect: (context, state) {
          final slug = _extractShopIdFromUrl(state.uri.toString()) ?? ref.read(currentTenantProvider)?.slug;
          if (slug != null && slug.isNotEmpty) {
             return '/$slug/shopadmin/login';
          }
          return null; // Stay on generic /login if no tenant
        },
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Generic fallback for unauthenticated
      GoRoute(
        path: '/shopadmin/login',
        redirect: (context, state) {
          final slug = _extractShopIdFromUrl(state.uri.toString()) ?? ref.read(currentTenantProvider)?.slug;
          if (slug != null && slug.isNotEmpty) {
             return '/$slug/shopadmin/login';
          }
          return '/login'; 
        },
      ),
      
      // Tenant-aware Login Route (outside shell)
      GoRoute(
        path: '/:shopId/shopadmin/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Dashboard Shell with nested routes
      ShellRoute(
        builder: (context, state, child) {
          return AdminLayout(child: child); // REPLACED DashboardScreen -> AdminLayout
        },
        routes: [
          // Tenant-aware Admin Route (New)
          GoRoute(
            path: '/:shopId/shopadmin',
            pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()),
            routes: [
              GoRoute(
                path: 'products',
                pageBuilder: (context, state) => const NoTransitionPage(child: ProductsListScreen()),
                routes: [
                  GoRoute(path: 'new', builder: (context, state) => const ProductEditScreen()),
                  GoRoute(path: ':id', builder: (context, state) => ProductEditScreen(productId: state.pathParameters['id'])),
                ],
              ),
              GoRoute(path: 'orders', pageBuilder: (context, state) => const NoTransitionPage(child: _PlaceholderParams(title: 'Order Management'))),
              GoRoute(path: 'categories', pageBuilder: (context, state) => const NoTransitionPage(child: MenuExplorerScreen())),
              GoRoute(path: 'menu-manager', pageBuilder: (context, state) => const NoTransitionPage(child: MenuExplorerScreen())),
              GoRoute(path: 'quick-products', pageBuilder: (context, state) => const NoTransitionPage(child: QuickProductManagerScreen())),
              GoRoute(path: 'settings', pageBuilder: (context, state) => const NoTransitionPage(child: ShopSettingsScreen())),
              GoRoute(path: 'qr-studio', pageBuilder: (context, state) => const NoTransitionPage(child: QrStudioScreen())),
            ],
          ),
          
          // Fallback Generic Admin Route (Backward compatibility & default login)
          GoRoute(
            path: '/shopadmin',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
            routes: [
              GoRoute(
                path: 'products',
                pageBuilder: (context, state) => const NoTransitionPage(child: ProductsListScreen()),
                routes: [
                  GoRoute(path: 'new', builder: (context, state) => const ProductEditScreen()),
                  GoRoute(path: ':id', builder: (context, state) => ProductEditScreen(productId: state.pathParameters['id'])),
                ],
              ),
              GoRoute(path: 'orders', pageBuilder: (context, state) => const NoTransitionPage(child: _PlaceholderParams(title: 'Order Management'))),
              GoRoute(path: 'categories', pageBuilder: (context, state) => const NoTransitionPage(child: MenuExplorerScreen())),
              GoRoute(path: 'menu-manager', pageBuilder: (context, state) => const NoTransitionPage(child: MenuExplorerScreen())),
              GoRoute(path: 'quick-products', pageBuilder: (context, state) => const NoTransitionPage(child: QuickProductManagerScreen())),
              GoRoute(path: 'settings', pageBuilder: (context, state) => const NoTransitionPage(child: ShopSettingsScreen())),
              GoRoute(path: 'qr-studio', pageBuilder: (context, state) => const NoTransitionPage(child: QrStudioScreen())),
            ],
          ),

          // Old route redirects
          GoRoute(
            path: '/dashboard',
            redirect: (context, state) {
              final shopId = ref.read(currentTenantProvider)?.slug ?? _extractShopIdFromUrl(state.uri.toString());
              return (shopId != null && shopId.isNotEmpty) ? '/$shopId/shopadmin' : '/shopadmin';
            },
          ),
          GoRoute(
            path: '/products',
            redirect: (context, state) {
              final shopId = ref.read(currentTenantProvider)?.slug ?? _extractShopIdFromUrl(state.uri.toString());
              return (shopId != null && shopId.isNotEmpty) ? '/$shopId/shopadmin/products' : '/shopadmin/products';
            },
          ),
        ],
      ),
    ],
  );
});

/// Placeholder widget for empty routes
class _PlaceholderParams extends StatelessWidget {
  final String title;

  const _PlaceholderParams({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text('Coming Soon'),
          ],
        ),
      ),
    );
  }
}

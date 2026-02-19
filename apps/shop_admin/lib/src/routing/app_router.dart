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

// GoRouter with refresh listenable
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);
  
  return GoRouter(
    initialLocation: '/', // Root is now handled by dynamic base_href from Python server
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final session = ShopAuthService.currentSession;
      final roleVerified = ref.read(roleVerifiedProvider);
      
      final isLoggedIn = session != null;
      final isOnLoginPage = state.matchedLocation == '/login';

      String? decision;

      // Rule 1: Not logged in → force login page
      if (!isLoggedIn && !isOnLoginPage) {
        decision = '/login';
      }
      // Rule 2: Logged in + on login page + role verified → go to dashboard
      else if (isLoggedIn && isOnLoginPage && roleVerified) {
        decision = '/';
      }
      // Rule 3: Logged in but trying to access protected route without role verification
      else if (isLoggedIn && !isOnLoginPage && !roleVerified) {
        decision = '/login';
      }

      return decision;
    },
    routes: [
      // Generic fallback for unauthenticated
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Dashboard Shell with nested routes
      ShellRoute(
        builder: (context, state, child) {
          return AdminLayout(child: child); 
        },
        routes: [
          // Elegant Root Dashboard Route
          GoRoute(
            path: '/',
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

/// Shop Admin Router — RACE CONDITION FIX
/// 
/// Uses refreshListenable to watch auth state changes
/// Checks both provider state AND Supabase session directly
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/products/presentation/products_list_screen.dart';
import '../features/products/presentation/product_edit_screen.dart';
import '../features/auth/application/auth_provider.dart';

/// Tracks whether role has been verified for the current session
final roleVerifiedProvider = StateProvider<bool>((ref) => false);

/// Tracks role check error messages to display on login screen
final roleErrorProvider = StateProvider<String?>((ref) => null);

/// Auth change notifier for router refresh
class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    // Listen to Supabase auth state changes
    SupabaseService.client.auth.onAuthStateChange.listen((event) {
      print('🔔 [AUTH NOTIFIER] Auth state changed: ${event.event}');
      notifyListeners(); // Trigger router refresh
    });
  }
}

final authNotifierProvider = Provider<AuthNotifier>((ref) => AuthNotifier());

// GoRouter with refresh listenable
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);
  
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier, // CRITICAL: Router rebuilds on auth changes
    redirect: (context, state) {
      // ROBUST CHECK: Use both Supabase session AND provider state
      final session = SupabaseService.client.auth.currentSession;
      final roleVerified = ref.read(roleVerifiedProvider);
      
      final isLoggedIn = session != null;
      final isOnLoginPage = state.matchedLocation == '/login';

      print('🧭 [ROUTER] Redirect check:');
      print('   location: ${state.matchedLocation}');
      print('   session: ${session != null ? "EXISTS ✅" : "NULL ❌"}');
      print('   roleVerified: $roleVerified');

      // Rule 1: Not logged in → force login page
      if (!isLoggedIn && !isOnLoginPage) {
        print('   ➡️  Redirecting to /login (no session)');
        return '/login';
      }

      // Rule 2: Logged in + on login page + role verified → go to products
      if (isLoggedIn && isOnLoginPage && roleVerified) {
        print('   ➡️  Redirecting to /products (authenticated & verified)');
        return '/products';
      }

      // Rule 3: Logged in but trying to access protected route without role verification
      if (isLoggedIn && !isOnLoginPage && !roleVerified) {
        print('   ➡️  Redirecting to /login (session exists but role not verified)');
        return '/login';
      }

      // No redirect needed
      print('   ✅ No redirect needed');
      return null;
    },
    routes: [
      // Login route (outside shell)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Root redirect
      GoRoute(
        path: '/',
        redirect: (_, __) => '/products',
      ),
      
      // Dashboard Shell with nested routes
      ShellRoute(
        builder: (context, state, child) {
          return DashboardScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderParams(title: 'Dashboard Overview'),
            ),
          ),
          GoRoute(
            path: '/products',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProductsListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ProductEditScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  return ProductEditScreen(productId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderParams(title: 'Order Management'),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderParams(title: 'Shop Settings'),
            ),
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

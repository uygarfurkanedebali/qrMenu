/// Shop Admin Router — SIMPLIFIED REDIRECT LOGIC
/// 
/// Simple rule: If logged in, go to /products. If not, go to /login.
/// Role checking is done in login screen, not in router redirect.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/products/presentation/products_list_screen.dart';
import '../features/products/presentation/product_edit_screen.dart';

/// Tracks whether role has been verified for the current session
final roleVerifiedProvider = StateProvider<bool>((ref) => false);

/// Tracks role check error messages to display on login screen
final roleErrorProvider = StateProvider<String?>((ref) => null);

// SIMPLIFIED GoRouter configuration
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final session = SupabaseService.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isOnLoginPage = state.matchedLocation == '/login';

      print('🧭 [ROUTER] Redirect check:');
      print('   isLoggedIn: $isLoggedIn');
      print('   current location: ${state.matchedLocation}');
      print('   roleVerified: ${ref.read(roleVerifiedProvider)}');

      // Simple rules:
      // 1. Not logged in and not on login page → go to login
      if (!isLoggedIn && !isOnLoginPage) {
        print('   ➡️  Redirecting to /login (not authenticated)');
        return '/login';
      }

      // 2. Logged in and on login page AND role verified → go to products
      if (isLoggedIn && isOnLoginPage && ref.read(roleVerifiedProvider)) {
        print('   ➡️  Redirecting to /products (already authenticated)');
        return '/products';
      }

      // 3. No redirect needed
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

/// Shop Admin Router
/// 
/// Defines the navigation structure for the admin panel.
/// STRICT ROLE GUARD: Only shop_owner role allowed.
/// Admin sessions are rejected and signed out.
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

// GoRouter configuration with STRICT role-based redirect
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final session = SupabaseService.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isLoggingIn = state.matchedLocation == '/login';

      // Not logged in and not on login page -> redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // Logged in and on login page -> check role before allowing through
      if (isLoggedIn && isLoggingIn) {
        final roleVerified = ref.read(roleVerifiedProvider);
        if (roleVerified) {
          return '/products';
        }
        
        // Role not yet verified — check it now
        try {
          final user = SupabaseService.client.auth.currentUser;
          if (user == null) return '/login';

          final response = await SupabaseService.client
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();

          if (response == null) {
            // No profile → sign out
            await SupabaseService.client.auth.signOut();
            ref.read(roleErrorProvider.notifier).state = 'Profil bulunamadı.';
            return '/login';
          }

          final role = response['role'] as String?;
          
          if (role != 'shop_owner') {
            // NOT a shop owner (could be admin or customer) → reject
            await SupabaseService.client.auth.signOut();
            ref.read(roleVerifiedProvider.notifier).state = false;
            ref.read(roleErrorProvider.notifier).state = 
                '⛔ Yetkisiz Erişim!\n\n'
                'Bu panel yalnızca Dükkan Sahipleri içindir.\n'
                'Hesap rolünüz: "${role ?? 'tanımsız'}"';
            return '/login';
          }

          // Role is shop_owner → allow through
          ref.read(roleVerifiedProvider.notifier).state = true;
          ref.read(roleErrorProvider.notifier).state = null;
          return '/products';
        } catch (e) {
          // On error, sign out for safety
          try { await SupabaseService.client.auth.signOut(); } catch (_) {}
          ref.read(roleErrorProvider.notifier).state = 'Rol doğrulama hatası: $e';
          return '/login';
        }
      }

      // No redirect needed
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

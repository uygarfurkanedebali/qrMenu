import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/landing/presentation/landing_page_screen.dart';
import '../features/landing/presentation/global_login_screen.dart';
import '../features/landing/presentation/apply_screen.dart';

/// Provider for the GoRouter instance in Landing Page
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingPageScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const GlobalLoginScreen(),
      ),
      GoRoute(
        path: '/apply',
        builder: (context, state) => const ApplyScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Sayfa bulunamadı: ${state.error?.message}'),
      ),
    ),
  );
});

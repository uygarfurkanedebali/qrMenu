/// App Router Configuration
/// 
/// Configures GoRouter with tenant-aware routing.
/// Handles loading states, 404 errors, and menu navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/tenant/application/tenant_provider.dart';
import '../features/menu/presentation/menu_screen.dart';
import '../features/menu/presentation/loading_screen.dart';
import '../features/menu/presentation/not_found_screen.dart';
import '../features/landing/presentation/landing_page_screen.dart';

/// Provider for the GoRouter instance
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Root route - matches the base_href injected (e.g. /<slug>/ or /<slug>/menu/)
      GoRoute(
        path: '/',
        builder: (context, state) {
          // the python deployment sets the base_href to /slug/
          // TenantResolver pulls it from the browser URL transparently
          final slug = TenantResolver.getCurrentSlug();
          if (slug != null && slug.isNotEmpty) {
            return TenantShell(slug: slug);
          }
          return const LandingPageScreen();
        },
      ),
    ],
    
    // Error handler
    errorBuilder: (context, state) => NotFoundScreen(
      errorMessage: state.error?.message,
    ),
  );
});

/// Shell widget that handles tenant loading
/// 
/// This widget:
/// 1. Sets the current slug in the provider
/// 2. Watches the tenant loading state
/// 3. Shows appropriate screen based on state
class TenantShell extends ConsumerStatefulWidget {
  final String slug;
  
  const TenantShell({super.key, required this.slug});

  @override
  ConsumerState<TenantShell> createState() => _TenantShellState();
}

class _TenantShellState extends ConsumerState<TenantShell> {
  @override
  void initState() {
    super.initState();
    // Set the slug in the provider after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentSlugProvider.notifier).state = widget.slug;
    });
  }

  @override
  void didUpdateWidget(TenantShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      ref.read(currentSlugProvider.notifier).state = widget.slug;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantAsync = ref.watch(tenantProvider);
    
    return tenantAsync.when(
      loading: () => const LoadingScreen(),
      error: (error, stack) => NotFoundScreen(
        errorMessage: error is TenantNotFoundException 
            ? 'Shop "${widget.slug}" not found' 
            : 'An error occurred',
      ),
      data: (tenant) => const MenuScreen(),
    );
  }
}

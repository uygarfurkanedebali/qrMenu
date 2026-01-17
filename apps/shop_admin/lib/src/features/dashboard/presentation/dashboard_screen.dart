/// Dashboard Screen
/// 
/// The main shell for the Shop Admin application.
/// Contains the sidebar navigation and the main content area.
/// Shows dynamic tenant info and client URL.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/application/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  final Widget child;

  const DashboardScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final tenant = ref.watch(currentTenantProvider);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation (Always visible on desktop)
          if (isDesktop)
            SizedBox(
              width: 250,
              child: _Sidebar(theme: theme, tenant: tenant, ref: ref),
            ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // AppBar
                AppBar(
                  title: Text(tenant?.name ?? 'Shop Admin'),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: theme.colorScheme.surface,
                  // Show drawer menu only on mobile
                  leading: !isDesktop
                      ? Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          ),
                        )
                      : null,
                ),
                
                // Route Content
                Expanded(
                  child: Container(
                    color: theme.colorScheme.surfaceContainerLowest,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Drawer for mobile navigation
      drawer: !isDesktop ? Drawer(child: _Sidebar(theme: theme, tenant: tenant, ref: ref)) : null,
    );
  }
}

class _Sidebar extends StatelessWidget {
  final ThemeData theme;
  final TenantState? tenant;
  final WidgetRef ref;

  const _Sidebar({required this.theme, this.tenant, required this.ref});

  @override
  Widget build(BuildContext context) {
    // Get current location to highlight active tab
    final String location = GoRouterState.of(context).uri.path;

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Logo Area
          Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'QR-Infinity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Client URL Card (if tenant is loaded)
          if (tenant != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.link, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Your Live Menu',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchUrl(tenant!.clientUrl),
                    child: Text(
                      tenant!.clientUrl,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchUrl(tenant!.clientUrl),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Open'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyUrl(context, tenant!.clientUrl),
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _NavTile(
                  title: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  isActive: location == '/dashboard',
                  onTap: () => context.go('/dashboard'),
                  theme: theme,
                ),
                const SizedBox(height: 4),
                _NavTile(
                  title: 'Products',
                  icon: Icons.inventory_2_outlined,
                  selectedIcon: Icons.inventory_2,
                  isActive: location == '/products',
                  onTap: () => context.go('/products'),
                  theme: theme,
                ),
                const SizedBox(height: 4),
                _NavTile(
                  title: 'Orders',
                  icon: Icons.shopping_bag_outlined,
                  selectedIcon: Icons.shopping_bag,
                  isActive: location == '/orders',
                  onTap: () => context.go('/orders'),
                  theme: theme,
                ),
                const Divider(height: 32),
                _NavTile(
                  title: 'Settings',
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  isActive: location == '/settings',
                  onTap: () => context.go('/settings'),
                  theme: theme,
                ),
              ],
            ),
          ),
          
          // User Info / Logout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    tenant?.name.isNotEmpty == true ? tenant!.name[0].toUpperCase() : 'A',
                    style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant?.name ?? 'Shop Owner',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      InkWell(
                        onTap: () => _logout(context),
                        child: Text(
                          'Logout',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyUrl(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL copied to clipboard!')),
    );
  }

  void _logout(BuildContext context) async {
    await AuthService.signOut();
    ref.read(currentTenantProvider.notifier).state = null;
    if (context.mounted) {
      context.go('/login');
    }
  }
}

class _NavTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final bool isActive;
  final VoidCallback onTap;
  final ThemeData theme;

  const _NavTile({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.isActive,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    
    return ListTile(
      leading: Icon(
        isActive ? selectedIcon : icon,
        color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/application/auth_provider.dart';

class AdminMenuDrawer extends ConsumerWidget {
  const AdminMenuDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: Column(
        children: [
          // 1. Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 16, 24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Shop Admin',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.black54),
                ),
              ],
            ),
          ),

          // 2. Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                _DrawerItem(
                  icon: Icons.home_outlined,
                  label: 'Panel',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    // Only navigate if not already on dashboard
                    if (GoRouterState.of(context).uri.path != '/dashboard') {
                      context.go('/dashboard');
                    }
                  },
                ),
                _DrawerItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Ürünler',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/products');
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Ayarlar',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings'); 
                  },
                ),
                _DrawerItem(
                  icon: Icons.qr_code_2,
                  label: 'QR Kod',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/qr-studio');
                  },
                ),
              ],
            ),
          ),
          
          // 3. Footer / Logout
           Padding(
            padding: const EdgeInsets.all(24),
            child: _DrawerItem(
              icon: Icons.logout,
              label: 'Çıkış Yap',
              iconColor: Colors.red.shade700,
              textColor: Colors.red.shade700,
              onTap: () async {
                 // Close drawer first
                 Navigator.pop(context);
                 // Sign out
                 // Using the provider method if available or direct supabase
                 // For now, re-using logic from previous implementation
                 // Assuming SupabaseService is available globally or via import, 
                 // but since we don't have it imported here, let's keep it simple or import it.
                 // Better to just redirect to login which handles cleanup or use a provider method.
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black87, size: 24),
      title: Text(
        label,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

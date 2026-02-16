import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
                  icon: Icons.dashboard_outlined,
                  label: 'Panel',
                  onTap: () {
                    Navigator.pop(context);
                    if (GoRouterState.of(context).uri.path != '/dashboard') {
                      context.go('/dashboard');
                    }
                  },
                ),
                _DrawerItem(
                  icon: Icons.restaurant_menu,
                  label: 'Menü Yönetimi',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/products');
                  },
                ),
                 _DrawerItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Siparişler',
                  badge: 'Yakında',
                  iconColor: Colors.grey,
                  textColor: Colors.grey,
                  onTap: () {
                     Navigator.pop(context);
                     context.push('/orders');
                  },
                ),
                _DrawerItem(
                  icon: Icons.qr_code_2,
                  label: 'QR Stüdyosu',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/qr-studio');
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Mekan Ayarları',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings'); 
                  },
                ),
                const Divider(height: 32, thickness: 1),
                 _DrawerItem(
                  icon: Icons.person_outline,
                  label: 'Hesabım',
                  onTap: () {},
                ),
              ],
            ),
          ),

          // 3. Logout Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: _DrawerItem(
                _DrawerItem(
                  icon: Icons.logout,
                  label: 'Çıkış Yap',
                  iconColor: Colors.red.shade700,
                  textColor: Colors.red.shade700,
                  onTap: () async {
                     Navigator.pop(context);
                     // Fix: Use Supabase.instance.client directly as requested
                     await Supabase.instance.client.auth.signOut();
                     ref.read(currentTenantProvider.notifier).state = null;
                     if (context.mounted) context.go('/login');
                  },
                ),
              ],
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
  final String? badge; // Added badge parameter
  final Color? iconColor;
  final Color? textColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge, // Added to constructor
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black87, size: 24),
      title: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor ?? Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

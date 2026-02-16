import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../../auth/application/auth_provider.dart';

class AdminMenuDrawer extends ConsumerWidget {
  const AdminMenuDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(currentTenantProvider);
    final theme = Theme.of(context);

    // Common Text Style
    final TextStyle menuTextStyle = theme.textTheme.bodyLarge!.copyWith(
      fontWeight: FontWeight.w500,
      color: Colors.black87,
    );

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(0), bottomLeft: Radius.circular(0)),
      ),
      child: Column(
        children: [
          // 1. Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo / Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Icon(Icons.store_mall_directory_outlined, size: 30, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                
                // Shop Name
                Text(
                  tenant?.name ?? 'Mağaza Adı',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Edit Profile Button
                InkWell(
                  onTap: () {
                    context.pop(); // Close drawer
                    context.go('/settings');
                  },
                  child: Text(
                    'Profili Düzenle',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                    context.pop();
                    context.go('/dashboard');
                  },
                  textStyle: menuTextStyle,
                ),
                _DrawerItem(
                  icon: Icons.analytics_outlined,
                  label: 'Analizler',
                  onTap: () {}, // Future
                  textStyle: menuTextStyle,
                ),
                _DrawerItem(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Siparişler',
                  onTap: () {
                     context.pop();
                     context.go('/orders');
                  },
                  textStyle: menuTextStyle,
                  badge: 'Yakında',
                ),
                _DrawerItem(
                  icon: Icons.restaurant_menu,
                  label: 'Menü Yönetimi',
                  onTap: () {
                    context.pop();
                    context.go('/products');
                  },
                  textStyle: menuTextStyle,
                ),
                _DrawerItem(
                  icon: Icons.qr_code_2,
                  label: 'QR Kodlarım',
                  onTap: () {}, // Handled in dashboard usually, but can act as shortcut
                  textStyle: menuTextStyle,
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Mekan Ayarları',
                  onTap: () {
                    context.pop();
                    context.go('/settings');
                  },
                  textStyle: menuTextStyle,
                ),
                const Divider(height: 32, thickness: 1),
                 _DrawerItem(
                  icon: Icons.person_outline,
                  label: 'Hesabım',
                  onTap: () {},
                  textStyle: menuTextStyle,
                ),
              ],
            ),
          ),

          // 3. Logout Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: _DrawerItem(
              icon: Icons.logout,
              label: 'Çıkış Yap',
              onTap: () async {
                await SupabaseService.client.auth.signOut();
                ref.read(currentTenantProvider.notifier).state = null;
                if (context.mounted) {
                   context.go('/login');
                }
              },
              textStyle: menuTextStyle.copyWith(color: Colors.red.shade700),
              iconColor: Colors.red.shade700,
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
  final TextStyle textStyle;
  final Color? iconColor;
  final String? badge;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.textStyle,
    this.iconColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black54, size: 22),
      title: Row(
        children: [
          Text(label, style: textStyle),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                badge!,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
              ),
            ),
          ]
        ],
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      visualDensity: VisualDensity.compact,
    );
  }
}

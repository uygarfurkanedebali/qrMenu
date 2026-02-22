import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/presentation/dashboard_screen.dart';
import '../settings/presentation/settings_screen.dart';
import '../settings/presentation/appearance_settings_screen.dart';
import '../qr_studio/presentation/qr_studio_screen.dart';
import '../menu_manager/presentation/menu_explorer_screen.dart';
import '../products/presentation/quick_product_manager_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdminMenuDrawer extends StatelessWidget {
  const AdminMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // --- HEADER ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.black,
                  radius: 20,
                  child: Icon(Icons.store, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        'assets/logo/qvitrinfull.svg',
                        height: 40,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Yönetici Paneli",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // --- MENU ITEMS ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              children: [
                _DrawerItem(
                  title: "Panel",
                  icon: Icons.dashboard_outlined,
                  onTap: () {
                    Navigator.pop(context); // Önce menüyü kapat
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DashboardScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  title: "Menü Yöneticisi",
                  icon: Icons.folder_open,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MenuExplorerScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  title: "Hızlı Ürün Yönetimi",
                  icon: Icons.flash_on,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const QuickProductManagerScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  title: "Siparişler",
                  icon: Icons.receipt_long_outlined,
                  badge: "Yakında",
                  color: Colors.grey,
                  onTap: () {}, // Henüz işlevsiz
                ),
                const Divider(height: 30, thickness: 0.5),
                _DrawerItem(
                  title: "QR Stüdyosu",
                  icon: Icons.qr_code_2,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const QrStudioScreen()));
                  },
                ),
                _DrawerItem(
                  title: "Görünüm ve Tema",
                  icon: Icons.palette_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AppearanceSettingsScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  title: "Mekan Ayarları",
                  icon: Icons.settings_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ShopSettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // --- FOOTER ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: _DrawerItem(
              title: "Çıkış Yap",
              icon: Icons.logout,
              color: Colors.red,
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                // Login sayfasına yönlendir (main.dart auth state'i dinliyorsa otomatik olur)
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- DRAWER ITEM WIDGET ---
class _DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final Color? color;

  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.badge,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? Colors.black87;

    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(
        title,
        style: TextStyle(
          color: itemColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge!,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}

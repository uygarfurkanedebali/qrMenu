import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../../auth/application/auth_provider.dart';
import '../../products/application/products_provider.dart';

class DashboardOverviewScreen extends ConsumerWidget {
  const DashboardOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(currentTenantProvider);
    final productsAsync = ref.watch(productsProvider);
    final theme = Theme.of(context);

    if (tenant == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int productCount = productsAsync.valueOrNull?.length ?? 0;
    
    // Dummy stats for now
    final int activeOrders = 0; 
    final int totalViews = 1250; 

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Off-white background
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Header Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoş Geldiniz,',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tenant.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Profile/Settings Icon
                   Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => context.go('/settings'),
                      icon: const Icon(Icons.person_outline, color: Colors.black87),
                      tooltip: 'Profil',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Summary Stats Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive: Stack on small screens, Row on large
                  if (constraints.maxWidth < 600) {
                     return Column(
                       children: [
                         _StatCard(
                            label: 'Toplam Ürün',
                            value: '$productCount',
                            icon: Icons.inventory_2_outlined,
                            color: Colors.blue,
                         ),
                         const SizedBox(height: 12),
                         _StatCard(
                            label: 'Aktif Sipariş',
                            value: '$activeOrders',
                            icon: Icons.shopping_bag_outlined,
                            color: Colors.orange,
                         ),
                          const SizedBox(height: 12),
                         _StatCard(
                            label: 'Görüntülenme',
                            value: '$totalViews',
                            icon: Icons.visibility_outlined,
                            color: Colors.purple,
                         ),
                       ],
                     );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Toplam Ürün',
                          value: '$productCount',
                          icon: Icons.inventory_2_outlined,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          label: 'Aktif Sipariş',
                          value: '$activeOrders',
                          icon: Icons.shopping_bag_outlined,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          label: 'Görüntülenme',
                          value: '$totalViews',
                          icon: Icons.visibility_outlined,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 3. Quick Actions Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Text(
                'Hızlı İşlemler',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // 4. Quick Actions Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid.count(
              crossAxisCount: MediaQuery.of(context).size.width > 900 
                  ? 4 
                  : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _QuickActionCard(
                  title: 'Ürün Yönetimi',
                  icon: Icons.inventory_2,
                  color: Colors.blue,
                  onTap: () => context.go('/products'),
                ),
                _QuickActionCard(
                  title: 'Kategoriler',
                  icon: Icons.category,
                  color: Colors.indigo,
                  onTap: () => context.go('/categories'),
                ),
                _QuickActionCard(
                  title: 'QR İşlemleri',
                  icon: Icons.qr_code_2,
                  color: Colors.black87,
                  onTap: () => _showQrDialog(context, tenant),
                ),
                _QuickActionCard(
                  title: 'Wifi Ayarları',
                  icon: Icons.wifi,
                  color: Colors.teal,
                  onTap: () => context.go('/settings'),
                ),
                _QuickActionCard(
                  title: 'Siparişler',
                  icon: Icons.shopping_cart,
                  color: Colors.orange,
                  onTap: () => context.go('/orders'),
                ),
                _QuickActionCard(
                  title: 'Önizleme',
                  icon: Icons.visibility,
                  color: Colors.deepPurple,
                  onTap: () => _launchUrl(tenant.clientUrl),
                ),
              ],
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  void _showQrDialog(BuildContext context, TenantState tenant) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Menü QR Kodu',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              QrImageView(
                data: tenant.clientUrl,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 24),
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                         Clipboard.setData(ClipboardData(text: tenant.clientUrl));
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link kopyalandı!')));
                         Navigator.pop(context);
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Linki Kopyala'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        _launchUrl(tenant.clientUrl);
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Menüyü Aç'),
                    ),
                  ],
               )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
       child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
             boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.08),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

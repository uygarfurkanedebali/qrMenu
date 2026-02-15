/// Menu Screen — Modern QR Menu
///
/// Dynamic theme from tenant settings, hero header with socials, 
/// sticky category tabs, Wi-Fi pill, and currency-aware product cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../tenant/application/tenant_provider.dart';
import '../../cart/application/cart_provider.dart';
import '../../cart/presentation/cart_bottom_sheet.dart';
import '../application/menu_provider.dart';
import '../domain/menu_models.dart';
import 'widgets/product_card.dart';
import 'widgets/category_tabs.dart';
import 'paper_menu_layout.dart';

/// Main menu screen that displays the restaurant menu
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantAsync = ref.watch(tenantProvider);

    return tenantAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (tenant) => _ThemedMenuScreen(tenant: tenant),
    );
  }
}

/// Menu screen with tenant theme applied dynamically
class _ThemedMenuScreen extends ConsumerWidget {
  final Tenant tenant;

  const _ThemedMenuScreen({required this.tenant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Build dynamic theme from tenant's primary color
    final primaryColor = ThemeFactory.parseHexColor(
      tenant.primaryColor,
      fallback: const Color(0xFFFF5722),
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      fontFamily: tenant.fontFamily,
    );

    return Theme(
      data: theme,
      child: _MenuContent(tenant: tenant, theme: theme),
    );
  }
}

/// The actual menu content with Sliver architecture
class _MenuContent extends ConsumerStatefulWidget {
  final Tenant tenant;
  final ThemeData theme;

  const _MenuContent({required this.tenant, required this.theme});

  @override
  ConsumerState<_MenuContent> createState() => _MenuContentState();
}

class _MenuContentState extends ConsumerState<_MenuContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _selectCategory(String? categoryId) {
    ref.read(selectedCategoryIdProvider.notifier).state = categoryId;
    _scrollToTop();
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);

    // Check Layout Mode
    final layoutMode = widget.tenant.designConfig['layout'] as String? ?? 'grid';
    final isPaperMode = layoutMode == 'paper';

    return Scaffold(
      backgroundColor: widget.theme.colorScheme.surface,
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading menu: $error')),
        data: (allCategories) {
          if (isPaperMode) {
             return PaperMenuLayout(
               tenant: widget.tenant,
               categories: allCategories,
             );
          }

          // FILTERING LOGIC
          final isFiltered = selectedCategoryId != null && selectedCategoryId != 'all';
          
          final displayedCategories = isFiltered
              ? allCategories.where((c) => c.id == selectedCategoryId).toList()
              : allCategories;
              
          // Identify selected category object for banner swap
          final selectedCategory = isFiltered && displayedCategories.isNotEmpty 
              ? displayedCategories.first 
              : null;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Hero Header with Dynamic Banner & Back Button logic
              _buildHeroHeader(context, ref, selectedCategory),

              // Social Action Bar + Wi-Fi
              SliverToBoxAdapter(child: _ActionBar(tenant: widget.tenant, theme: widget.theme)),

              // TOP SECTION: Category Grid (Only in standard mode)
              if (!isFiltered && allCategories.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = allCategories[index];
                        // Fallback image if category has no image
                        final imageUrl = category.iconUrl ?? 
                            'https://source.unsplash.com/random/800x600?food,${category.name}'; 

                        return InkWell(
                          onTap: () => _selectCategory(category.id),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black .withValues(alpha: 0.2), // Slight dark tint overall
                                    Colors.black.withValues(alpha: 0.6),
                                  ],
                                ),
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                category.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: allCategories.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                      childAspectRatio: 3.5,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                  ),
                ),

              // Menu items (Filtered List)
              ..._buildMenuSlivers(context, ref, displayedCategories),

              // Footer
              SliverToBoxAdapter(child: _Footer(tenant: widget.tenant, theme: widget.theme)),
            ],
          );
        },
      ),
      floatingActionButton: !isPaperMode ? _CartFab(theme: widget.theme, cartItemCount: cartItemCount) : null,
    );
  }

  SliverAppBar _buildHeroHeader(BuildContext context, WidgetRef ref, MenuCategory? selectedCategory) {
    final bool isCategorySelected = selectedCategory != null;
    
    String? activeBannerUrl;
    if (isCategorySelected && selectedCategory.iconUrl != null && selectedCategory.iconUrl!.isNotEmpty) {
      activeBannerUrl = selectedCategory.iconUrl;
    } else {
      activeBannerUrl = widget.tenant.bannerUrl;
    }
    
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: widget.theme.colorScheme.primary,
      automaticallyImplyLeading: false, 
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Text(
          isCategorySelected ? selectedCategory.name : widget.tenant.name,
          style: TextStyle(
            color: widget.theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            fontFamily: widget.tenant.fontFamily,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.primary,
            image: activeBannerUrl != null && activeBannerUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(activeBannerUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.4),
                      BlendMode.darken,
                    ),
                  )
                : null,
            gradient: activeBannerUrl == null || activeBannerUrl.isEmpty
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.theme.colorScheme.primary,
                      widget.theme.colorScheme.primary.withValues(alpha: 0.8),
                      widget.theme.colorScheme.tertiary.withValues(alpha: 0.6),
                    ],
                  )
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (activeBannerUrl == null || activeBannerUrl.isEmpty || true) 
                Positioned(
                  right: -30,
                  top: -30,
                  child: Opacity(
                    opacity: 0.08,
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 250,
                      color: widget.theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              if (!isCategorySelected)
                Positioned(
                  left: 20,
                  bottom: 55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_2, size: 14, color: Colors.white.withValues(alpha: 0.9)),
                            const SizedBox(width: 4),
                            Text(
                              'Dijital Menü',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
               if (isCategorySelected)
                 Positioned(
                   top: 60, // Adjust for safe area approx
                   left: 16,
                   child: Material(
                     color: Colors.black.withValues(alpha: 0.3), // Semi-transparent dark bg
                     shape: const CircleBorder(),
                     child: InkWell(
                       customBorder: const CircleBorder(),
                       onTap: () => _selectCategory(null),
                       child: const Padding(
                         padding: EdgeInsets.all(8.0),
                         child: Icon(
                           Icons.arrow_back,
                           color: Colors.white,
                           size: 24,
                         ),
                       ),
                     ),
                   ),
                 ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuSlivers(
      BuildContext context, WidgetRef ref, List<MenuCategory> categories) {
    if (categories.isEmpty) {
      return [
        const SliverFillRemaining(
          child: Center(child: Text('Görüntülenecek ürün yok')),
        ),
      ];
    }

    return [
      ...categories.map((category) {
      return SliverMainAxisGroup(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: widget.theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                if (category.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    category.description!,
                    style: widget.theme.textTheme.bodyMedium?.copyWith(
                      color: widget.theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const Divider(height: 24),
              ],
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = category.products[index];
              return ProductCard(
                product: product,
                currencySymbol: widget.tenant.currencySymbol,
                onAddToCart: () {
                  ref.read(cartProvider.notifier).addItem(product);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} sepete eklendi'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'Sepeti Gör',
                        onPressed: () => showCartBottomSheet(context),
                      ),
                    ),
                  );
                },
              );
            },
            childCount: category.products.length,
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 16)), // Spacing between categories
      ]);
      }),
      const SliverToBoxAdapter(child: SizedBox(height: 80)), // Bottom padding
    ];
  }
}

// ═══════════════════════════════════════════════════════
// ACTION BAR — Social Icons + Wi-Fi Pill
// ═══════════════════════════════════════════════════════

class _ActionBar extends StatelessWidget {
  final Tenant tenant;
  final ThemeData theme;

  const _ActionBar({required this.tenant, required this.theme});

  @override
  Widget build(BuildContext context) {
    final hasPhone = tenant.phoneNumber != null && tenant.phoneNumber!.isNotEmpty;
    final hasInsta = tenant.instagramHandle != null && tenant.instagramHandle!.isNotEmpty;
    final hasWifi = tenant.wifiName != null && tenant.wifiName!.isNotEmpty;
    final hasAnySocial = hasPhone || hasInsta;

    if (!hasAnySocial && !hasWifi) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          if (hasPhone) ...[
            _SocialIcon(
              icon: Icons.phone,
              label: 'Ara',
              color: Colors.green,
              onTap: () => _launchUrl('tel:${tenant.phoneNumber}'),
            ),
            const SizedBox(width: 8),
            _SocialIcon(
              icon: Icons.message,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              onTap: () {
                final phone = tenant.phoneNumber!.replaceAll(RegExp(r'[^0-9]'), '');
                _launchUrl('https://wa.me/$phone');
              },
            ),
            const SizedBox(width: 8),
          ],
          if (hasInsta) ...[
            _SocialIcon(
              icon: Icons.camera_alt,
              label: 'Instagram',
              color: const Color(0xFFE1306C),
              onTap: () => _launchUrl('https://instagram.com/${tenant.instagramHandle}'),
            ),
          ],

          const Spacer(),

          if (hasWifi)
            _WifiPill(
              wifiName: tenant.wifiName!,
              wifiPassword: tenant.wifiPassword ?? '',
              theme: theme,
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
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WifiPill extends StatelessWidget {
  final String wifiName;
  final String wifiPassword;
  final ThemeData theme;

  const _WifiPill({
    required this.wifiName,
    required this.wifiPassword,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (wifiPassword.isNotEmpty) {
            Clipboard.setData(ClipboardData(text: wifiPassword));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('Wi-Fi şifresi kopyalandı: $wifiPassword'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green.shade700,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                wifiName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              if (wifiPassword.isNotEmpty) ...[
                const SizedBox(width: 4),
                Icon(Icons.content_copy, size: 12, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CartFab extends StatelessWidget {
  final ThemeData theme;
  final int cartItemCount;

  const _CartFab({required this.theme, required this.cartItemCount});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => showCartBottomSheet(context),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      icon: Badge(
        isLabelVisible: cartItemCount > 0,
        label: Text(
          cartItemCount.toString(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.error,
        textColor: theme.colorScheme.onError,
        child: const Icon(Icons.shopping_cart),
      ),
      label: Text(
        cartItemCount > 0 ? 'Sepet ($cartItemCount)' : 'Sepet',
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final Tenant tenant;
  final ThemeData theme;

  const _Footer({required this.tenant, required this.theme});

  @override
  Widget build(BuildContext context) {
    final hasInsta = tenant.instagramHandle != null && tenant.instagramHandle!.isNotEmpty;
    final hasPhone = tenant.phoneNumber != null && tenant.phoneNumber!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          Text(
            tenant.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          if (hasPhone || hasInsta)
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (hasPhone)
                  Text(
                    '📞 ${tenant.phoneNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (hasInsta)
                  Text(
                    '📷 @${tenant.instagramHandle}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2, size: 16, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(
                'Powered by QR-Infinity',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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

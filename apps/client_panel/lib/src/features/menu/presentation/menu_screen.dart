/// Menu Screen
/// 
/// The main menu display screen using Sliver architecture.
/// Shows products grouped by category with the tenant's theme.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../../tenant/application/tenant_provider.dart';
import '../../cart/application/cart_provider.dart';
import '../../cart/presentation/cart_bottom_sheet.dart';
import '../application/menu_provider.dart';
import '../domain/menu_models.dart';
import 'widgets/product_card.dart';
import 'widgets/category_tabs.dart';

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

/// Menu screen with tenant theme applied
class _ThemedMenuScreen extends ConsumerWidget {
  final Tenant tenant;

  const _ThemedMenuScreen({required this.tenant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Apply the tenant's theme (or default if none set)
    final theme = ThemeFactory.createTheme(
      tenant.themeConfig ?? const ThemeConfig(),
    );

    return Theme(
      data: theme,
      child: _MenuContent(tenant: tenant, theme: theme),
    );
  }
}

/// The actual menu content with Sliver architecture
class _MenuContent extends ConsumerWidget {
  final Tenant tenant;
  final ThemeData theme;

  const _MenuContent({required this.tenant, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuProvider);
    final selectedCategoryIndex = ref.watch(selectedCategoryIndexProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      body: menuAsync.when(
        loading: () => CustomScrollView(
          slivers: [
            _buildAppBar(context),
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (error, stack) => CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverFillRemaining(
              child: Center(child: Text('Error loading menu: $error')),
            ),
          ],
        ),
        data: (categories) => CustomScrollView(
          slivers: [
            // SliverAppBar with hero banner
            _buildAppBar(context),

            // Sticky category tabs
            if (categories.isNotEmpty)
              SliverPersistentHeader(
                pinned: true,
                delegate: CategoryHeaderDelegate(
                  categories: categories,
                  selectedIndex: selectedCategoryIndex,
                  onCategorySelected: (index) {
                    ref.read(selectedCategoryIndexProvider.notifier).state =
                        index;
                  },
                ),
              ),

            // Menu items grouped by category
            ..._buildMenuSlivers(context, ref, categories, selectedCategoryIndex),

            // Footer
            SliverToBoxAdapter(
              child: _Footer(tenant: tenant, theme: theme),
            ),
          ],
        ),
      ),
      floatingActionButton: _CartFab(
        theme: theme,
        cartItemCount: cartItemCount,
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          tenant.name,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.7),
                theme.colorScheme.secondary.withValues(alpha: 0.5),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 200,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              // Welcome text
              Positioned(
                left: 16,
                bottom: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuSlivers(
      BuildContext context, WidgetRef ref, List<MenuCategory> categories, int selectedIndex) {
    if (categories.isEmpty) {
      return [
        const SliverFillRemaining(
          child: Center(child: Text('No menu items available')),
        ),
      ];
    }

    // Show only the selected category's products
    final category = categories[selectedIndex];

    return [
      // Category header
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (category.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  category.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

      // Products list
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = category.products[index];
            return ProductCard(
              product: product,
              onAddToCart: () {
                // Add to cart using provider
                ref.read(cartProvider.notifier).addItem(product);
                
                // Show feedback
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} added to cart'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'View Cart',
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

      // Bottom spacing
      const SliverToBoxAdapter(
        child: SizedBox(height: 80), // Space for FAB
      ),
    ];
  }
}

/// Cart FAB with badge
class _CartFab extends StatelessWidget {
  final ThemeData theme;
  final int cartItemCount;

  const _CartFab({required this.theme, required this.cartItemCount});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => showCartBottomSheet(context),
      backgroundColor: theme.colorScheme.secondary,
      foregroundColor: theme.colorScheme.onSecondary,
      icon: Badge(
        isLabelVisible: cartItemCount > 0,
        label: Text(
          cartItemCount.toString(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.error,
        textColor: theme.colorScheme.onError,
        child: const Icon(Icons.shopping_cart),
      ),
      label: Text(
        cartItemCount > 0 ? 'Cart ($cartItemCount)' : 'Cart',
      ),
    );
  }
}

/// Footer widget
class _Footer extends StatelessWidget {
  final Tenant tenant;
  final ThemeData theme;

  const _Footer({required this.tenant, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_2,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Powered by QR-Infinity',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tenant.name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

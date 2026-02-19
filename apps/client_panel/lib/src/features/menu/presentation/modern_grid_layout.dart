/// Modern Grid Layout — Hierarchical Category Menu
///
/// Screen A: 2-column grid of main categories with banner images.
/// Screen B: Subcategory chips (pinned) + filtered product list.
/// Apple-style white theme aesthetics.
library;

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../domain/menu_models.dart';
import '../../cart/presentation/cart_bottom_sheet.dart';

class ModernGridLayout extends StatefulWidget {
  final Tenant tenant;
  final List<MenuCategory> categories;
  final ThemeData theme;

  const ModernGridLayout({
    super.key,
    required this.tenant,
    required this.categories,
    required this.theme,
  });

  @override
  State<ModernGridLayout> createState() => _ModernGridLayoutState();
}

class _ModernGridLayoutState extends State<ModernGridLayout> {
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;

  List<MenuCategory> get _mainCategories =>
      widget.categories.where((c) => c.parentId == null).toList();

  List<MenuCategory> _getSubCategories(String mainCategoryId) =>
      widget.categories.where((c) => c.parentId == mainCategoryId).toList();

  void _openCategory(String mainCategoryId) {
    final subs = _getSubCategories(mainCategoryId);
    setState(() {
      _selectedMainCategoryId = mainCategoryId;
      _selectedSubCategoryId = subs.isNotEmpty ? subs.first.id : null;
    });
  }

  void _goBack() {
    setState(() {
      _selectedMainCategoryId = null;
      _selectedSubCategoryId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedMainCategoryId != null) {
      return _buildScreenB(context);
    }
    return _buildScreenA(context);
  }

  // ═══════════════════════════════════════════════════════════════
  // SCREEN A — Main Categories Grid
  // ═══════════════════════════════════════════════════════════════
  Widget _buildScreenA(BuildContext context) {
    final mainCats = _mainCategories;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Text(
                widget.tenant.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  fontFamily: widget.tenant.fontFamily,
                  shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)],
                ),
              ),
              background: _buildBannerBackground(widget.tenant.bannerUrl),
            ),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
              child: Text(
                'Kategoriler',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          // 2-Column Grid
          if (mainCats.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('Kategori bulunamadı', style: TextStyle(color: Colors.black45))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _MainCategoryCard(
                    category: mainCats[index],
                    onTap: () => _openCategory(mainCats[index].id),
                  ),
                  childCount: mainCats.length,
                ),
              ),
            ),

          // Footer
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Powered by QR-Infinity',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SCREEN B — Subcategories & Products
  // ═══════════════════════════════════════════════════════════════
  Widget _buildScreenB(BuildContext context) {
    final mainCat = widget.categories
        .where((c) => c.id == _selectedMainCategoryId)
        .firstOrNull;
    final subCategories = _getSubCategories(_selectedMainCategoryId!);
    final selectedProducts = _selectedSubCategoryId != null
        ? widget.categories
            .where((c) => c.id == _selectedSubCategoryId)
            .expand((c) => c.products)
            .toList()
        : <MenuProduct>[];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header with back button
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Text(
                mainCat?.name ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: widget.tenant.fontFamily,
                  shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)],
                ),
              ),
              background: _buildBannerBackground(mainCat?.iconUrl ?? widget.tenant.bannerUrl),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Material(
                color: Colors.black.withOpacity(0.3),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _goBack,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),

          // Subcategory Chips (pinned)
          if (subCategories.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SubCategoryChipsDelegate(
                subCategories: subCategories,
                selectedId: _selectedSubCategoryId,
                onSelected: (id) {
                  setState(() => _selectedSubCategoryId = id);
                },
              ),
            ),

          // Empty state or product list
          if (subCategories.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Bu kategoride alt kategori yok',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else if (selectedProducts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Bu alt kategoride ürün yok',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Product count header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  '${selectedProducts.length} ürün',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            // Product list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ModernProductTile(
                  product: selectedProducts[index],
                  currencySymbol: widget.tenant.currencySymbol,
                ),
                childCount: selectedProducts.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => showCartBottomSheet(context),
        backgroundColor: Colors.black,
        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
      ),
    );
  }

  // ─── Shared Helpers ──────────────────────────────────────────

  Widget _buildBannerBackground(String? imageUrl) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.primary,
        gradient: !hasImage
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade800,
                  Colors.grey.shade600,
                  Colors.blueGrey.shade400,
                ],
              )
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade800,
                child: const Icon(Icons.broken_image, color: Colors.white24, size: 48),
              ),
            ),
          // Dark overlay for text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.55),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MAIN CATEGORY CARD — Used in Screen A grid
// ═══════════════════════════════════════════════════════════════

class _MainCategoryCard extends StatelessWidget {
  final MenuCategory category;
  final VoidCallback onTap;

  const _MainCategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = category.iconUrl != null && category.iconUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            if (hasImage)
              Image.network(
                category.iconUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackGradient(),
              )
            else
              _fallbackGradient(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.3, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Category name
            Positioned(
              bottom: 16,
              left: 14,
              right: 14,
              child: Text(
                category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Arrow indicator
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white.withOpacity(0.9),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackGradient() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey.shade700,
          Colors.blueGrey.shade800,
        ],
      ),
    ),
    child: Center(
      child: Icon(
        Icons.restaurant_menu,
        size: 40,
        color: Colors.white.withOpacity(0.15),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// SUBCATEGORY CHIPS — Pinned persistent header delegate
// ═══════════════════════════════════════════════════════════════

class _SubCategoryChipsDelegate extends SliverPersistentHeaderDelegate {
  final List<MenuCategory> subCategories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  _SubCategoryChipsDelegate({
    required this.subCategories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: subCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final sub = subCategories[index];
                final isSelected = sub.id == selectedId;

                return ChoiceChip(
                  label: Text(
                    sub.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => onSelected(sub.id),
                  selectedColor: Colors.black,
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(
                    color: isSelected ? Colors.transparent : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                );
              },
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SubCategoryChipsDelegate oldDelegate) =>
      selectedId != oldDelegate.selectedId ||
      subCategories != oldDelegate.subCategories;
}

// ═══════════════════════════════════════════════════════════════
// MODERN PRODUCT TILE — Clean list tile for product display
// ═══════════════════════════════════════════════════════════════

class _ModernProductTile extends StatelessWidget {
  final MenuProduct product;
  final String currencySymbol;

  const _ModernProductTile({required this.product, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image (if available)
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.imageUrl!,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fastfood, color: Colors.grey.shade300),
                ),
              ),
            ),

          if (hasImage) const SizedBox(width: 14),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                if (product.description != null && product.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      product.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Price
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${product.price.toStringAsFixed(0)} $currencySymbol',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

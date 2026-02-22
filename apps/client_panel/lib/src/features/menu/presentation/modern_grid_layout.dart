/// Modern Grid Layout — Hierarchical Category Menu
///
/// Screen A: 2-column grid of main categories with banner images.
/// Screen B: Subcategory chips (pinned) + filtered product list.
/// Apple-style white theme aesthetics.
library;

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../domain/menu_models.dart';

class ModernGridAppearance {
  final Color globalBgColor;
  final Color globalSurfaceColor;
  final Color globalAccentColor;

  final Color categoryTitleColor;
  final Color categoryActiveTextColor;
  final Color categoryInactiveTextColor;
  final bool showCategoryDivider;

  final Color productTitleColor;
  final Color productDescColor;
  final Color productPriceColor;
  final Color productCardBg;

  final Color mgCardBorderColor;

  ModernGridAppearance(Map<String, dynamic> dc)
      : globalBgColor = _parseHex(
          dc['global_bg_color'] ?? dc['background_color'],
          const Color(0xFFFFFFFF),
        ),
        globalSurfaceColor = _parseHex(
          dc['global_surface_color'] ?? dc['secondary_color'],
          const Color(0xFFF5F5F5),
        ),
        globalAccentColor = _parseHex(
          dc['global_accent_color'] ?? dc['accent_color'],
          const Color(0xFF000000),
        ),
        categoryTitleColor = _parseHex(
          dc['category_title_color'] ?? dc['title_text_color'],
          const Color(0xFF000000),
        ),
        categoryActiveTextColor = _parseHex(
          dc['category_active_text_color'],
          const Color(0xFFFFFFFF),
        ),
        categoryInactiveTextColor = _parseHex(
          dc['category_inactive_text_color'],
          const Color(0xFF424242),
        ),
        showCategoryDivider = dc['show_category_divider'] as bool? ?? true,
        productTitleColor = _parseHex(
          dc['product_title_color'] ?? dc['product_text_color'],
          const Color(0xFF212121),
        ),
        productDescColor = _parseHex(
          dc['product_desc_color'],
          const Color(0xFF9E9E9E),
        ),
        productPriceColor = _parseHex(
          dc['product_price_color'],
          const Color(0xFF424242),
        ),
        productCardBg =
            _parseHex(dc['product_card_bg'], const Color(0xFFFFFFFF)),
        mgCardBorderColor = _parseHex(
          dc['mg_card_border_color'],
          const Color(0xFFEEEEEE),
        );

  static Color _parseHex(dynamic hexStr, Color fallback) {
    if (hexStr is! String || hexStr.isEmpty) return fallback;
    try {
      final cleaned = hexStr.replaceAll('#', '').trim();
      if (cleaned.length == 6) return Color(int.parse('FF$cleaned', radix: 16));
      if (cleaned.length == 8) return Color(int.parse(cleaned, radix: 16));
    } catch (_) {}
    return fallback;
  }
}

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
  String _searchQuery = "";
  late final FocusNode _searchFocusNode;

  late ModernGridAppearance _appearance;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(() {
      setState(() {});
    });
    final dc = widget.tenant.designConfig as Map<String, dynamic>? ?? {};
    _appearance = ModernGridAppearance(dc);
  }

  @override
  void didUpdateWidget(covariant ModernGridLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tenant.designConfig != oldWidget.tenant.designConfig) {
      final dc = widget.tenant.designConfig as Map<String, dynamic>? ?? {};
      _appearance = ModernGridAppearance(dc);
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<MenuCategory> get _mainCategories {
    final rootCats = widget.categories.where((c) => c.parentId == null).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (_allProducts.isNotEmpty) {
      rootCats.insert(
        0,
        MenuCategory(
          id: 'all_products',
          tenantId: widget.tenant.id,
          name: 'Tüm Ürünler',
          iconUrl: widget.tenant.bannerUrl,
          sortOrder: -999,
          products: _allProducts,
        ),
      );
    }
    return rootCats;
  }

  List<MenuProduct> get _allProducts {
    final uniqueMap = <String, MenuProduct>{};
    for (final cat in widget.categories) {
      for (final p in cat.products) {
        uniqueMap[p.id] = p;
      }
    }
    final list = uniqueMap.values.toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  List<MenuCategory> _getSubCategories(String mainCategoryId) {
    if (mainCategoryId == 'all_products') return [];
    return widget.categories.where((c) => c.parentId == mainCategoryId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<MenuProduct> _getAllProductsForMain(String mainCategoryId) {
    if (mainCategoryId == 'all_products') return _allProducts;
    final mainCat =
        widget.categories.where((c) => c.id == mainCategoryId).firstOrNull;
    final subs = _getSubCategories(mainCategoryId);
    final allProducts = <MenuProduct>[];
    if (mainCat != null) allProducts.addAll(mainCat.products);
    for (final sub in subs) {
      allProducts.addAll(sub.products);
    }
    final uniqueMap = <String, MenuProduct>{};
    for (var p in allProducts) uniqueMap[p.id] = p;
    final list = uniqueMap.values.toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  void _openCategory(String mainCategoryId) {
    setState(() {
      _selectedMainCategoryId = mainCategoryId;
      _selectedSubCategoryId = null; // null means "Tümü"
      _searchQuery = "";
    });
  }

  void _goBack() {
    setState(() {
      _selectedMainCategoryId = null;
      _selectedSubCategoryId = null;
      _searchQuery = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isRootScreen = _selectedMainCategoryId == null;

    return Scaffold(
      backgroundColor: _appearance.globalBgColor,
      body: CustomScrollView(
        slivers: [
          // 1. Dükkan Banner'ı
          SliverAppBar(
            expandedHeight: isRootScreen ? 200 : 180,
            pinned: true,
            stretch: true,
            backgroundColor: _appearance.globalBgColor,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Text(
                isRootScreen
                    ? widget.tenant.name
                    : (widget.categories
                            .where((c) => c.id == _selectedMainCategoryId)
                            .firstOrNull
                            ?.name ??
                        (_selectedMainCategoryId == 'all_products'
                            ? 'Tüm Ürünler'
                            : '')),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isRootScreen ? 22 : 20,
                  fontFamily: widget.tenant.fontFamily,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              background: _buildBannerBackground(
                isRootScreen
                    ? widget.tenant.bannerUrl
                    : (widget.categories
                            .where((c) => c.id == _selectedMainCategoryId)
                            .firstOrNull
                            ?.iconUrl ??
                        widget.tenant.bannerUrl),
              ),
            ),
            leading: isRootScreen
                ? null
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Material(
                      color: Colors.black.withOpacity(0.3),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _goBack,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),

          // 2. Statik Arama Çubuğu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _appearance.globalBgColor == Colors.white
                      ? const Color(0xFFF5F5F5)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _searchFocusNode.hasFocus
                        ? _appearance.globalAccentColor
                        : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: _searchFocusNode.hasFocus
                      ? [
                          BoxShadow(
                            color: _appearance.globalAccentColor.withOpacity(
                              0.15,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: TextField(
                  focusNode: _searchFocusNode,
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                  controller: TextEditingController.fromValue(
                    TextEditingValue(
                      text: _searchQuery,
                      selection: TextSelection.collapsed(
                        offset: _searchQuery.length,
                      ),
                    ),
                  ),
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: "Ürün veya içerik ara...",
                    hintStyle: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: _searchFocusNode.hasFocus
                          ? _appearance.globalAccentColor
                          : Colors.black54,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.black54,
                            ),
                            onPressed: () {
                              setState(() => _searchQuery = "");
                              _searchFocusNode.unfocus();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ARAMA YAPILDIYSA VEYA KATEGORİ SEÇİLDİYSE EKRAN B (Ürünler)
          if (_searchQuery.isNotEmpty || !isRootScreen) ...[
            if (!isRootScreen && _searchQuery.isEmpty)
              Builder(
                builder: (context) {
                  final isAllProductsSelected =
                      _selectedMainCategoryId == 'all_products';
                  final filterCategories = isAllProductsSelected
                      ? _mainCategories
                          .where((c) => c.id != 'all_products')
                          .toList()
                      : _getSubCategories(_selectedMainCategoryId!);

                  if (filterCategories.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  // 4. Alt Kategoriler (Chips)
                  return SliverPersistentHeader(
                    pinned: true,
                    delegate: _SubCategoryChipsDelegate(
                      appearance: _appearance,
                      subCategories: filterCategories,
                      selectedId: _selectedSubCategoryId,
                      showAllTab: true,
                      onSelected: (id) {
                        setState(() => _selectedSubCategoryId = id);
                      },
                      onAllSelected: () {
                        setState(() => _selectedSubCategoryId = null);
                      },
                    ),
                  );
                },
              ),

            // Arama veya Seçilen Kategoriye Ait Ürünlerin Hesaplanması
            Builder(
              builder: (context) {
                List<MenuProduct> displayProducts;

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  displayProducts = _allProducts.where((p) {
                    return p.name.toLowerCase().contains(q) ||
                        (p.description?.toLowerCase().contains(q) ?? false);
                  }).toList();
                } else {
                  final isAllProductsSelected =
                      _selectedMainCategoryId == 'all_products';
                  final filterCategories = isAllProductsSelected
                      ? _mainCategories
                          .where((c) => c.id != 'all_products')
                          .toList()
                      : _getSubCategories(_selectedMainCategoryId!);
                  final mainCat = widget.categories
                      .where((c) => c.id == _selectedMainCategoryId)
                      .firstOrNull;

                  if (isAllProductsSelected) {
                    if (_selectedSubCategoryId == null) {
                      displayProducts = _allProducts;
                    } else {
                      displayProducts = _getAllProductsForMain(
                        _selectedSubCategoryId!,
                      );
                    }
                  } else {
                    if (filterCategories.isEmpty) {
                      displayProducts = mainCat?.products ?? [];
                    } else if (_selectedSubCategoryId == null) {
                      displayProducts = _getAllProductsForMain(
                        _selectedMainCategoryId!,
                      );
                    } else {
                      displayProducts = widget.categories
                          .where((c) => c.id == _selectedSubCategoryId)
                          .expand((c) => c.products)
                          .toList();
                    }
                  }
                  displayProducts.sort(
                    (a, b) => a.sortOrder.compareTo(b.sortOrder),
                  );
                }

                if (displayProducts.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 56,
                            color: _appearance.categoryInactiveTextColor
                                .withOpacity(0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Ürün bulunamadı'
                                : 'Bu kategoride ürün yok',
                            style: TextStyle(
                              color: _appearance.categoryInactiveTextColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'Arama Sonuçları (${displayProducts.length} ürün)'
                              : '${displayProducts.length} ürün',
                          style: TextStyle(
                            fontSize: 13,
                            color: _appearance.categoryInactiveTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return _ModernProductTile(
                      appearance: _appearance,
                      product: displayProducts[index - 1],
                      currencySymbol: widget.tenant.currencySymbol,
                    );
                  }, childCount: displayProducts.length + 1),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ]
          // EKRAN A (Root)
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  'Kategoriler',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _appearance.categoryTitleColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            if (_appearance.showCategoryDivider)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 0,
                  ),
                  child: Divider(
                    color: _appearance.mgCardBorderColor,
                    height: 1,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 3. Ana Kategoriler Grid'i (2'li kolon)
            if (_mainCategories.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Kategori bulunamadı',
                    style: TextStyle(
                      color: _appearance.categoryInactiveTextColor,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.95,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _MainCategoryCard(
                      appearance: _appearance,
                      category: _mainCategories[index],
                      onTap: () => _openCategory(_mainCategories[index].id),
                    ),
                    childCount: _mainCategories.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerBackground(String? imageUrl) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final fallbackColor = _appearance.globalAccentColor == Colors.black
        ? Colors.blueGrey.shade800
        : _appearance.globalAccentColor;

    return Container(
      decoration: BoxDecoration(
        color: fallbackColor,
        gradient: !hasImage
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [fallbackColor.withOpacity(0.8), fallbackColor],
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
                color: fallbackColor,
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.white24,
                  size: 48,
                ),
              ),
            ),
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
  final ModernGridAppearance appearance;
  final MenuCategory category;
  final VoidCallback onTap;

  const _MainCategoryCard({
    required this.appearance,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = category.iconUrl != null && category.iconUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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

  Widget _fallbackGradient() {
    final color = appearance.globalAccentColor == Colors.black
        ? Colors.blueGrey.shade800
        : appearance.globalAccentColor;
    return Container(
      decoration: BoxDecoration(color: color),
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 40,
          color: Colors.white.withOpacity(0.15),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SUBCATEGORY CHIPS — Pinned persistent header delegate
// ═══════════════════════════════════════════════════════════════

class _SubCategoryChipsDelegate extends SliverPersistentHeaderDelegate {
  final ModernGridAppearance appearance;
  final List<MenuCategory> subCategories;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final bool showAllTab;
  final VoidCallback? onAllSelected;

  _SubCategoryChipsDelegate({
    required this.appearance,
    required this.subCategories,
    required this.selectedId,
    required this.onSelected,
    this.showAllTab = false,
    this.onAllSelected,
  });

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final showAll = showAllTab && subCategories.isNotEmpty;
    final totalCount = (showAll ? 1 : 0) + subCategories.length;

    return Container(
      color: appearance.globalBgColor,
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: totalCount,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (showAll && index == 0) {
                  final isAllSelected = selectedId == null;
                  return ChoiceChip(
                    label: Text(
                      'Tümü',
                      style: TextStyle(
                        color: isAllSelected
                            ? appearance.categoryActiveTextColor
                            : appearance.categoryInactiveTextColor,
                        fontWeight:
                            isAllSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    selected: isAllSelected,
                    onSelected: (_) => onAllSelected?.call(),
                    selectedColor: appearance.globalAccentColor,
                    backgroundColor: appearance.globalSurfaceColor,
                    side: BorderSide(
                      color: isAllSelected
                          ? Colors.transparent
                          : appearance.mgCardBorderColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  );
                }

                final subIndex = showAll ? index - 1 : index;
                final sub = subCategories[subIndex];
                final isSelected = sub.id == selectedId;

                return ChoiceChip(
                  label: Text(
                    sub.name,
                    style: TextStyle(
                      color: isSelected
                          ? appearance.categoryActiveTextColor
                          : appearance.categoryInactiveTextColor,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => onSelected(sub.id),
                  selectedColor: appearance.globalAccentColor,
                  backgroundColor: appearance.globalSurfaceColor,
                  side: BorderSide(
                    color: isSelected
                        ? Colors.transparent
                        : appearance.mgCardBorderColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                );
              },
            ),
          ),
          if (appearance.showCategoryDivider)
            Divider(height: 1, color: appearance.mgCardBorderColor)
          else
            const SizedBox(height: 1),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SubCategoryChipsDelegate oldDelegate) =>
      selectedId != oldDelegate.selectedId ||
      subCategories != oldDelegate.subCategories ||
      showAllTab != oldDelegate.showAllTab ||
      appearance != oldDelegate.appearance;
}

// ═══════════════════════════════════════════════════════════════
// MODERN PRODUCT TILE — Clean list tile for product display
// ═══════════════════════════════════════════════════════════════

class _ModernProductTile extends StatelessWidget {
  final ModernGridAppearance appearance;
  final MenuProduct product;
  final String currencySymbol;

  const _ModernProductTile({
    required this.appearance,
    required this.product,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appearance.productCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appearance.mgCardBorderColor),
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
                    color: appearance.globalSurfaceColor,
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
                    color: appearance.productTitleColor,
                  ),
                ),
                if (product.description != null &&
                    product.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      product.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: appearance.productDescColor,
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
              color: appearance.globalSurfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${product.price.toStringAsFixed(0)} $currencySymbol',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: appearance.productPriceColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

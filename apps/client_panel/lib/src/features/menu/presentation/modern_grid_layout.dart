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
  String _searchQuery = "";
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(() {
      setState(() {});
    });
    // Menü açıldığında "Tüm Ürünler" veya ilk kategori seçili gelsin
    _selectedMainCategoryId = 'all_products';
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
    final mainCat = widget.categories
        .where((c) => c.id == mainCategoryId)
        .firstOrNull;
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

  @override
  Widget build(BuildContext context) {
    final mainCats = _mainCategories;

    final activeMainCatId =
        _selectedMainCategoryId ??
        (mainCats.isNotEmpty ? mainCats.first.id : null);
    final activeMainCat = widget.categories
        .where((c) => c.id == activeMainCatId)
        .firstOrNull;

    final isAllProductsSelected = activeMainCatId == 'all_products';
    final filterCategories = isAllProductsSelected
        ? <MenuCategory>[]
        : (activeMainCatId != null
              ? _getSubCategories(activeMainCatId)
              : <MenuCategory>[]);

    List<MenuProduct> selectedProducts;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      selectedProducts = _allProducts.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.description?.toLowerCase().contains(q) ?? false);
      }).toList();
    } else {
      if (isAllProductsSelected) {
        selectedProducts = _allProducts;
      } else if (activeMainCatId != null) {
        if (filterCategories.isEmpty) {
          selectedProducts = activeMainCat?.products ?? [];
        } else if (_selectedSubCategoryId == null) {
          selectedProducts = _getAllProductsForMain(activeMainCatId);
        } else {
          selectedProducts = widget.categories
              .where((c) => c.id == _selectedSubCategoryId)
              .expand((c) => c.products)
              .toList();
        }
      } else {
        selectedProducts = [];
      }
      selectedProducts.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    final hasSearchFocus = _searchFocusNode.hasFocus;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. Banner
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
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8),
                  ],
                ),
              ),
              background: _buildBannerBackground(widget.tenant.bannerUrl),
            ),
          ),

          // 2. YENİ: Statik Arama Çubuğu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasSearchFocus
                        ? widget.theme.primaryColor
                        : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: hasSearchFocus
                      ? [
                          BoxShadow(
                            color: widget.theme.primaryColor.withOpacity(0.15),
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
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: hasSearchFocus
                          ? widget.theme.primaryColor
                          : Colors.grey.shade500,
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

          // 3. Kategoriler (Ana Kategoriler) - Arama varsa gizle
          if (_searchQuery.isEmpty && mainCats.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: mainCats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = mainCats[index];
                    final isSelected = cat.id == activeMainCatId;
                    return ChoiceChip(
                      label: Text(
                        cat.name,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade800,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedMainCategoryId = cat.id;
                          _selectedSubCategoryId = null; // reset sub selection
                        });
                      },
                      selectedColor: Colors.black,
                      backgroundColor: Colors.grey.shade100,
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    );
                  },
                ),
              ),
            ),

          if (_searchQuery.isEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // 4. Alt Kategoriler (Chips)
          if (_searchQuery.isEmpty && filterCategories.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filterCategories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isAllSelected = _selectedSubCategoryId == null;
                      return ChoiceChip(
                        label: Text(
                          'Tümü',
                          style: TextStyle(
                            color: isAllSelected
                                ? Colors.black87
                                : Colors.grey.shade600,
                            fontWeight: isAllSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                        selected: isAllSelected,
                        onSelected: (_) {
                          setState(() => _selectedSubCategoryId = null);
                        },
                        selectedColor: Colors.grey.shade200,
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color: isAllSelected
                              ? Colors.grey.shade400
                              : Colors.grey.shade200,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      );
                    }

                    final sub = filterCategories[index - 1];
                    final isSelected = sub.id == _selectedSubCategoryId;
                    return ChoiceChip(
                      label: Text(
                        sub.name,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black87
                              : Colors.grey.shade600,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedSubCategoryId = sub.id);
                      },
                      selectedColor: Colors.grey.shade200,
                      backgroundColor: Colors.transparent,
                      side: BorderSide(
                        color: isSelected
                            ? Colors.grey.shade400
                            : Colors.grey.shade200,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
            ),

          if (_searchQuery.isEmpty && filterCategories.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Divider
          if (_searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: Divider(height: 1, color: Colors.grey.shade200),
            ),

          // 5. Ürünler Grid'i (Liste olarak)
          if (selectedProducts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 56,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Ürün bulunamadı'
                          : 'Bu kategoride ürün yok',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'Arama Sonuçları'
                            : (activeMainCat?.name ?? 'Ürünler'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Text(
                      '${selectedProducts.length} ürün',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    );
  }

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
// MODERN PRODUCT TILE — Clean list tile for product display
// ═══════════════════════════════════════════════════════════════

class _ModernProductTile extends StatelessWidget {
  final MenuProduct product;
  final String currencySymbol;

  const _ModernProductTile({
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
                if (product.description != null &&
                    product.description!.isNotEmpty)
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

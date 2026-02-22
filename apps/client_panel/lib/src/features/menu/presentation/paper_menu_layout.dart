import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_core/shared_core.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/menu_models.dart';
import 'components/noise_painter.dart';

class PaperMenuAppearance {
  final Color globalBgColor;
  final Color globalAccentColor;

  final Color categoryTitleColor;
  final Color categoryActiveTextColor;
  final Color categoryInactiveTextColor;
  final bool showCategoryDivider;

  final Color productTitleColor;
  final Color productDescColor;
  final Color productPriceColor;
  final Color
  productCardBg; // Unused in paper logically, but we map it just in case

  final double pmNoiseOpacity;
  final Color pmDottedLineColor;
  final bool pmShowDottedLine;

  PaperMenuAppearance(Map<String, dynamic> dc)
    : globalBgColor = _parseHex(
        dc['global_bg_color'] ?? dc['background_color'],
        const Color(0xFFFDFBF7),
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
        const Color(0xFF000000),
      ), // Usually black on paper menu active tab
      categoryInactiveTextColor = _parseHex(
        dc['category_inactive_text_color'],
        const Color(0x73000000),
      ), // Colors.black45
      showCategoryDivider = dc['show_category_divider'] as bool? ?? true,
      productTitleColor = _parseHex(
        dc['product_title_color'] ?? dc['product_text_color'],
        const Color(0xDD000000),
      ), // Colors.black87
      productDescColor = _parseHex(
        dc['product_desc_color'],
        const Color(0x8A000000),
      ), // Colors.black54
      productPriceColor = _parseHex(
        dc['product_price_color'],
        const Color(0xDD000000),
      ), // Colors.black87
      productCardBg = _parseHex(dc['product_card_bg'], Colors.transparent),
      pmNoiseOpacity = (dc['pm_noise_opacity'] as num?)?.toDouble() ?? 0.05,
      pmDottedLineColor = _parseHex(
        dc['pm_dotted_line_color'],
        const Color(0x42000000),
      ), // Colors.black26
      pmShowDottedLine = dc['pm_show_dotted_line'] as bool? ?? true;

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

class PaperMenuLayout extends StatefulWidget {
  final Tenant tenant;
  final List<MenuCategory> categories;

  const PaperMenuLayout({
    super.key,
    required this.tenant,
    required this.categories,
  });

  @override
  State<PaperMenuLayout> createState() => _PaperMenuLayoutState();
}

class _PaperMenuLayoutState extends State<PaperMenuLayout> {
  // Ana Liste Kontrolcüleri
  final ItemScrollController _mainScrollController = ItemScrollController();
  final ItemPositionsListener _mainPositionsListener =
      ItemPositionsListener.create();

  // Kategori Tab Kontrolcüleri
  final ItemScrollController _overlayTabController = ItemScrollController();
  final ItemScrollController _inlineTabController = ItemScrollController();

  // Arama Kontrolcüleri
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<dynamic> _flatList = [];
  final Map<String, int> _categoryStartIndex = {};
  final Map<int, String> _indexToCategoryId = {};
  List<MenuCategory> _filteredCategories = [];

  String? _selectedCategoryId;
  bool _isTabClicked = false;
  bool _showStickyHeader = false;

  // ARAMA STATE'LERİ
  bool _isSearchActive = false;
  String _searchQuery = "";

  late PaperMenuAppearance _appearance;

  @override
  void initState() {
    super.initState();
    final dc = widget.tenant.designConfig as Map<String, dynamic>? ?? {};
    _appearance = PaperMenuAppearance(dc);

    _processCategories();
    _mainPositionsListener.itemPositions.addListener(_onMainScroll);
  }

  @override
  void didUpdateWidget(covariant PaperMenuLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tenant.designConfig != oldWidget.tenant.designConfig) {
      final dc = widget.tenant.designConfig as Map<String, dynamic>? ?? {};
      _appearance = PaperMenuAppearance(dc);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Listeyi oluştururken arama filtresini de uygula
  void _processCategories() {
    _flatList = [];
    _categoryStartIndex.clear();
    _indexToCategoryId.clear();
    _filteredCategories = [];

    // 1. TENANT HEADER (Item 0)
    _flatList.add('TENANT_HEADER');

    // 2. CATEGORY BAR / SEARCH BAR (Item 1)
    _flatList.add('CATEGORY_BAR');

    int globalIndex = 2;

    // EĞER ARAMA AKTİF DEĞİLSE NORMAL AKIŞ
    if (_searchQuery.isEmpty) {
      for (var cat in widget.categories) {
        if (cat.id == '0' ||
            cat.name == 'All Products' ||
            cat.name == 'Tüm Ürünler' ||
            cat.products.isEmpty) {
          continue;
        }

        _filteredCategories.add(cat);

        // Kategori Başlığı
        _flatList.add(cat);
        _categoryStartIndex[cat.id] = globalIndex;
        _indexToCategoryId[globalIndex] = cat.id;
        globalIndex++;

        // Ürünler
        for (var product in cat.products) {
          _flatList.add(product);
          _indexToCategoryId[globalIndex] = cat.id;
          globalIndex++;
        }
      }
    }
    // EĞER ARAMA VARSA FİLTRELEME YAP
    else {
      final query = _searchQuery.toLowerCase();
      bool foundAny = false;

      for (var cat in widget.categories) {
        // Ürünleri filtrele
        final matchingProducts = cat.products.where((p) {
          final nameMatch = p.name.toLowerCase().contains(query);
          final descMatch =
              p.description?.toLowerCase().contains(query) ?? false;
          return nameMatch || descMatch;
        }).toList();

        if (matchingProducts.isNotEmpty) {
          foundAny = true;
          // Arama sonuçlarında kategori başlığını gösterelim ki neyin nerede olduğu belli olsun
          _flatList.add(cat);
          globalIndex++;

          for (var product in matchingProducts) {
            _flatList.add(product);
            globalIndex++;
          }
        }
      }

      if (!foundAny) {
        _flatList.add('NO_RESULTS');
      }
    }

    _flatList.add('FOOTER');

    if (_filteredCategories.isNotEmpty && _searchQuery.isEmpty) {
      // Sadece arama yoksa seçim yap, varsa seçimi bozma
      if (_selectedCategoryId == null) {
        _selectedCategoryId = _filteredCategories.first.id;
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _processCategories(); // Listeyi yeniden oluştur
    });
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        // Aramadan çıkınca temizle
        _searchQuery = "";
        _searchController.clear();
        _processCategories();
      } else {
        // Arama açılınca klavyeyi aç
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _onMainScroll() {
    final positions = _mainPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // --- 1. Sticky Header Görünürlüğü ---
    final categoryBarItem = positions.where((p) => p.index == 1).firstOrNull;

    bool shouldShowSticky = true;
    if (categoryBarItem != null) {
      if (categoryBarItem.itemLeadingEdge > 0) {
        shouldShowSticky = false;
      }
    } else {
      final firstVisible = positions.reduce(
        (min, p) => p.itemLeadingEdge < min.itemLeadingEdge ? p : min,
      );
      if (firstVisible.index < 1) {
        shouldShowSticky = false;
      }
    }

    if (_showStickyHeader != shouldShowSticky) {
      setState(() {
        _showStickyHeader = shouldShowSticky;
      });
    }

    // --- 2. Aktif Kategori Takibi (Sadece Arama Yoksa) ---
    if (_isTabClicked || _searchQuery.isNotEmpty) return;

    final spyItem = positions
        .where((p) => p.itemLeadingEdge < 0.3)
        .reduce((max, p) => p.itemLeadingEdge > max.itemLeadingEdge ? p : max);

    final currentId = _indexToCategoryId[spyItem.index];

    if (currentId != null && currentId != _selectedCategoryId) {
      if (mounted) {
        setState(() {
          _selectedCategoryId = currentId;
        });
        _scrollToContents(currentId, onlyTab: true);
      }
    }
  }

  void _scrollToContents(String categoryId, {bool onlyTab = false}) {
    int tabIndex = _filteredCategories.indexWhere((c) => c.id == categoryId);

    if (tabIndex != -1) {
      if (_overlayTabController.isAttached) {
        _overlayTabController.scrollTo(
          index: tabIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.45,
        );
      }
      if (_inlineTabController.isAttached) {
        _inlineTabController.scrollTo(
          index: tabIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.45,
        );
      }
    }

    if (!onlyTab && _categoryStartIndex.containsKey(categoryId)) {
      _mainScrollController.scrollTo(
        index: _categoryStartIndex[categoryId]!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.08,
      );
    }
  }

  void _onCategoryTap(String categoryId) async {
    setState(() {
      _isTabClicked = true;
      _selectedCategoryId = categoryId;
    });

    _scrollToContents(categoryId);

    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) _isTabClicked = false;
  }

  // --- Yardımcı Metodlar ---
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  String _getIconUrl(String fileName) {
    const String supabaseUrl = 'https://jswvvrxpjvsdqcayynzi.supabase.co';
    return '$supabaseUrl/storage/v1/object/public/assets/icons/$fileName';
  }

  String _formatWhatsApp(String rawPhone, {required bool forUrl}) {
    String cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '90${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('90')) {
      cleanPhone = '90$cleanPhone';
    }
    return forUrl ? cleanPhone : '+$cleanPhone';
  }

  @override
  Widget build(BuildContext context) {
    final tenant = widget.tenant;

    return Scaffold(
      backgroundColor: _appearance.globalBgColor,
      body: Stack(
        children: [
          if (_appearance.pmNoiseOpacity > 0)
            Positioned.fill(
              child: CustomPaint(
                painter: NoisePainter(opacity: _appearance.pmNoiseOpacity),
              ),
            ),

          // LAYER 1: ANA İÇERİK
          Positioned.fill(
            child: ScrollablePositionedList.builder(
              itemCount: _flatList.length,
              itemScrollController: _mainScrollController,
              itemPositionsListener: _mainPositionsListener,
              padding: const EdgeInsets.only(bottom: 100),
              itemBuilder: (context, index) {
                final item = _flatList[index];

                if (item == 'TENANT_HEADER') {
                  return _buildTenantHeader(tenant);
                } else if (item == 'CATEGORY_BAR') {
                  // Listenin içindeki placeholder da sticky ile aynı görünüme sahip olmalı
                  return _buildStickyHeaderContent(
                    controller: _inlineTabController,
                    isOverlay: false,
                  );
                } else if (item == 'FOOTER') {
                  return _buildFooter(tenant);
                } else if (item == 'NO_RESULTS') {
                  return _buildNoResults();
                } else if (item is MenuCategory) {
                  return _buildCategoryTitle(item);
                } else if (item is MenuProduct) {
                  return _buildProductRow(item, tenant);
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // LAYER 2: YAPIŞKAN HEADER (OVERLAY)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_showStickyHeader,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showStickyHeader ? 1.0 : 0.0,
                child: _buildStickyHeaderContent(
                  controller: _overlayTabController,
                  isOverlay: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildTenantHeader(Tenant tenant) {
    return Container(
      color: Colors.transparent, // Uses scaffold background
      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
      child: Column(
        children: [
          Text(
            tenant.name.toUpperCase(),
            style: GoogleFonts.lora(
              color: _appearance.categoryTitleColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
            textAlign: TextAlign.center,
          ),

          if (tenant.instagramHandle != null) ...[
            const SizedBox(height: 8),
            Text(
              '@${tenant.instagramHandle}',
              style: GoogleFonts.lora(
                color: _appearance.productDescColor,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 24),
          _buildContactInfoSection(tenant),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection(Tenant tenant) {
    List<Widget> rows = [];

    if (tenant.instagramHandle != null) {
      rows.add(
        _buildContactRow(
          'instagram.png',
          '@${tenant.instagramHandle}',
          () => _launchUrl('https://instagram.com/${tenant.instagramHandle}'),
        ),
      );
    }
    if (tenant.phoneNumber != null) {
      final displayPhone = _formatWhatsApp(tenant.phoneNumber!, forUrl: false);
      final urlPhone = _formatWhatsApp(tenant.phoneNumber!, forUrl: true);
      rows.add(
        _buildContactRow(
          'whatsapp.png',
          displayPhone,
          () => _launchUrl('https://wa.me/$urlPhone'),
        ),
      );
    }
    if (tenant.wifiName != null) {
      rows.add(
        _buildContactRow('wifi.png', tenant.wifiName!, () {
          Clipboard.setData(ClipboardData(text: tenant.wifiPassword ?? ''));
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Wifi şifresi kopyalandı!"),
                behavior: SnackBarBehavior.floating,
              ),
            );
        }),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: rows,
    );
  }

  Widget _buildContactRow(String iconName, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              _getIconUrl(iconName),
              width: 18,
              height: 18,
              color: _appearance.productDescColor,
              errorBuilder: (_, __, ___) => Icon(
                Icons.link,
                size: 18,
                color: _appearance.productDescColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.lora(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _appearance.productTitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- GÜNCELLENMİŞ STICKY HEADER ---
  // Hem Kategori Listesini hem de Arama Barını yönetir
  Widget _buildStickyHeaderContent({
    required ItemScrollController controller,
    required bool isOverlay,
  }) {
    final boxDecoration = isOverlay
        ? BoxDecoration(
            color: _appearance.globalBgColor.withOpacity(0.98),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border(
              bottom: BorderSide(color: Colors.black.withOpacity(0.05)),
            ),
          )
        : BoxDecoration(color: _appearance.globalBgColor);

    return Container(
      height: 56,
      decoration: boxDecoration,
      child: Row(
        children: [
          // SOL TARAF: KATEGORİLER veya TEXT FIELD
          Expanded(
            child: _isSearchActive
                ? _buildSearchBar()
                : _buildCategoryList(controller),
          ),

          // SAĞ TARAF: ARAMA BUTONU
          // Sadece kategoriler varken göster, arama modunda zaten "X" butonu TextField içinde olacak
          if (!_isSearchActive)
            IconButton(
              onPressed: _toggleSearchMode,
              icon: Icon(
                Icons.search,
                color: _appearance.categoryInactiveTextColor,
              ),
              tooltip: 'Ara',
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(ItemScrollController controller) {
    return ScrollablePositionedList.builder(
      itemCount: _filteredCategories.length,
      itemScrollController: controller,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        final cat = _filteredCategories[index];
        final isSelected = cat.id == _selectedCategoryId;

        return GestureDetector(
          onTap: () => _onCategoryTap(cat.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: isSelected
                ? BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _appearance.categoryTitleColor,
                        width: 2.5,
                      ),
                    ),
                  )
                : null,
            child: Text(
              cat.name.toUpperCase(),
              style: GoogleFonts.lora(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? _appearance.categoryActiveTextColor
                    : _appearance.categoryInactiveTextColor,
                letterSpacing: 1.0,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        style: GoogleFonts.lora(
          fontSize: 16,
          color: _appearance.categoryActiveTextColor,
        ),
        decoration: InputDecoration(
          hintText: 'Ürün ara...',
          hintStyle: GoogleFonts.lora(
            fontSize: 14,
            color: _appearance.categoryInactiveTextColor,
            fontStyle: FontStyle.italic,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(bottom: 8),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.close,
              color: _appearance.categoryInactiveTextColor,
            ),
            onPressed: _toggleSearchMode,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTitle(MenuCategory category) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          if (_appearance.showCategoryDivider) ...[
            Icon(
              Icons.star_rate_rounded,
              size: 14,
              color: _appearance.categoryInactiveTextColor.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            category.name.toUpperCase(),
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: _appearance.categoryTitleColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(MenuProduct product, Tenant tenant) {
    final nameStyle = GoogleFonts.lora(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: _appearance.productTitleColor,
    );
    final priceStyle = GoogleFonts.lora(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: _appearance.productPriceColor,
    );
    final descStyle = GoogleFonts.lora(
      fontSize: 14,
      fontStyle: FontStyle.italic,
      color: _appearance.productDescColor,
      height: 1.3,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(product.name, style: nameStyle)),
              const SizedBox(width: 8),
              if (_appearance.pmShowDottedLine)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: CustomPaint(
                      painter: _DottedLinePainter(
                        color: _appearance.pmDottedLineColor,
                      ),
                    ),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
              const SizedBox(width: 8),
              Text(
                '${product.price} ${tenant.currencySymbol}',
                style: priceStyle,
              ),
            ],
          ),
          if (product.description != null && product.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 30),
              child: Text(product.description!, style: descStyle),
            ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: _appearance.categoryInactiveTextColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "Sonuç bulunamadı",
            style: GoogleFonts.lora(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: _appearance.categoryInactiveTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Tenant tenant) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          if (_appearance.showCategoryDivider) ...[
            Icon(
              Icons.circle,
              size: 6,
              color: _appearance.categoryInactiveTextColor.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            "Afiyet Olsun",
            style: GoogleFonts.lora(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: _appearance.categoryInactiveTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawCircle(Offset(startX, size.height), 0.5, paint);
      startX += 5;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter old) => old.color != color;
}

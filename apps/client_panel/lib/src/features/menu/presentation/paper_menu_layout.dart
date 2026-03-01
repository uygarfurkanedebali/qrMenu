import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_core/shared_core.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/menu_models.dart';
import 'components/noise_painter.dart';
import '../../cart/application/cart_provider.dart';
import '../../cart/domain/cart_model.dart';
import 'product_detail_sheet.dart';

class PaperMenuAppearance {
  final Color globalBgColor;
  final Color globalAccentColor;

  final Color categoryTitleColor;
  final Color categoryAccentColor;
  final Color categoryActiveTextColor;
  final Color categoryInactiveTextColor;
  final bool showCategoryDivider;
  final bool showProductImages;
  final String categoryDividerType; // 'star' veya 'line'
  final Color categoryDividerColor;
  final double categoryDividerLength;

  final Color productTitleColor;
  final Color variantTextColor;
  final Color productDescColor;
  final Color productPriceColor;
  final Color
  productCardBg; // Unused in paper logically, but we map it just in case

  final double pmNoiseOpacity;
  final Color pmDottedLineColor;
  final bool pmShowDottedLine;
  final double pmLineThickness;

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
      categoryAccentColor = _parseHex(
        dc['category_accent_color'],
        _parseHex(dc['global_accent_color'] ?? dc['accent_color'], const Color(0xFF2196F3)),
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
      showProductImages = dc['show_product_images'] as bool? ?? true,
      categoryDividerType = dc['category_divider_type'] as String? ?? 'star',
      categoryDividerColor = _parseHex(
        dc['category_divider_color'],
        const Color(0x73000000),
      ),
      categoryDividerLength = (dc['category_divider_length'] as num?)?.toDouble() ?? 160.0,
      productTitleColor = _parseHex(
        dc['product_title_color'] ?? dc['product_text_color'],
        const Color(0xDD000000),
      ), // Colors.black87
      variantTextColor = _parseHex(
        dc['variant_text_color'],
        _parseHex(dc['product_desc_color'], const Color(0x8A000000)),
      ), // Fallback to desc color or grey
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
      pmShowDottedLine = dc['pm_show_dotted_line'] as bool? ?? true,
      pmLineThickness = (dc['pm_line_thickness'] as num?)?.toDouble() ?? 1.0;

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

class PaperMenuLayout extends ConsumerStatefulWidget {
  final Tenant tenant;
  final List<MenuCategory> categories;

  const PaperMenuLayout({
    super.key,
    required this.tenant,
    required this.categories,
  });

  @override
  ConsumerState<PaperMenuLayout> createState() => _PaperMenuLayoutState();
}

class _PaperMenuLayoutState extends ConsumerState<PaperMenuLayout> {
  // Ana Liste Kontrolcüleri
  final ItemScrollController _mainScrollController = ItemScrollController();
  final ItemPositionsListener _mainPositionsListener =
      ItemPositionsListener.create();

  // Kategori Tab Kontrolcüleri
  final ScrollController _overlayTabController = ScrollController();
  final ScrollController _inlineTabController = ScrollController();
  final Map<String, GlobalKey> _overlayTabKeys = {};
  final Map<String, GlobalKey> _inlineTabKeys = {};

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
    _overlayTabKeys.clear();
    _inlineTabKeys.clear();

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
        _overlayTabKeys[cat.id] = GlobalKey();
        _inlineTabKeys[cat.id] = GlobalKey();

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
      if (_overlayTabController.hasClients) {
        _scrollToTabCenter(categoryId, _overlayTabController, _overlayTabKeys);
      }
      if (_inlineTabController.hasClients) {
        _scrollToTabCenter(categoryId, _inlineTabController, _inlineTabKeys);
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

  void _scrollToTabCenter(String categoryId, ScrollController controller, Map<String, GlobalKey> keys) {
    final key = keys[categoryId];
    if (key == null || key.currentContext == null) return;

    final renderBox = key.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewport = RenderAbstractViewport.of(renderBox);
    final offsetToReveal = viewport.getOffsetToReveal(renderBox, 0.5);

    final clampedOffset = offsetToReveal.offset.clamp(
      0.0,
      controller.position.maxScrollExtent,
    );

    controller.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
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
    final dc = tenant.designConfig as Map<String, dynamic>? ?? {};
    final whatsappEnabled = dc['whatsapp_ordering_enabled'] as bool? ?? false;
    final cartItemCount = whatsappEnabled ? ref.watch(cartItemCountProvider) : 0;
    final cartTotal = whatsappEnabled ? ref.watch(cartTotalProvider) : 0.0;
    final showCartBar = whatsappEnabled && cartItemCount > 0;

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
              padding: EdgeInsets.only(bottom: showCartBar ? 160 : 100),
              itemBuilder: (context, index) {
                final item = _flatList[index];

                if (item == 'TENANT_HEADER') {
                  return _buildTenantHeader(tenant);
                } else if (item == 'CATEGORY_BAR') {
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
                  return _buildProductRow(item, tenant, whatsappEnabled: whatsappEnabled);
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

          // LAYER 3: SEPET ALT BARI
          if (whatsappEnabled)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                offset: showCartBar ? Offset.zero : const Offset(0, 1),
                child: _buildCartBar(cartItemCount, cartTotal, tenant),
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
    required ScrollController controller,
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
                : _buildCategoryList(controller: controller, isOverlay: isOverlay),
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

  Widget _buildCategoryList({
    required ScrollController controller,
    required bool isOverlay,
  }) {
    final Map<String, GlobalKey> keyMap = isOverlay ? _overlayTabKeys : _inlineTabKeys;

    return ListView.builder(
      controller: controller,
      itemCount: _filteredCategories.length,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        final cat = _filteredCategories[index];
        final isSelected = cat.id == _selectedCategoryId;

        return GestureDetector(
          onTap: () => _onCategoryTap(cat.id),
          child: Container(
            key: keyMap[cat.id],
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: isSelected
                ? BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _appearance.categoryAccentColor,
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
                    ? _appearance.categoryAccentColor
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
          // 1. YILDIZ SEÇİLİYSE ÜSTTE GÖSTER
          if (_appearance.showCategoryDivider && _appearance.categoryDividerType != 'line') ...[
            Icon(
              Icons.star_rate_rounded,
              size: 14,
              color: _appearance.categoryDividerColor,
            ),
            const SizedBox(height: 8),
          ],

          // 2. KATEGORİ BAŞLIĞI
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

          // 3. ÇİZGİ SEÇİLİYSE ALTTA GÖSTER
          if (_appearance.showCategoryDivider && _appearance.categoryDividerType == 'line') ...[
            const SizedBox(height: 12), // Başlık ile alt çizgi arası boşluk
            Container(
              width: _appearance.categoryDividerLength, // DİNAMİK UZUNLUK BURAYA BAĞLANDI
              height: 3.0,
              decoration: BoxDecoration(
                color: _appearance.categoryDividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ────────────────────────────────────────────────────────────────────────────
  /// ÜRÜN SATIRI – SAF FLEX MİMARİSİ
  /// ────────────────────────────────────────────────────────────────────────────
  ///
  /// Hiyerarşi:
  ///  Padding (dış kenar boşluğu – satır ekrana çarpmaz)
  ///   └─ Row (Ana Satır)
  ///        ├─ [Opsiyonel] Ürün Görseli (sabit 72×72)
  ///        └─ Expanded (Metin bloğu – görselden arta kalan TÜM alanı kaplar)
  ///              └─ Column (crossAxisAlignment: stretch)
  ///                    ├─ Row (İsim + Çizgi + Fiyat)
  ///                    │     ├─ [Opsiyonel] Emoji  (sabit 26px + 6px boşluk = 32px)
  ///                    │     ├─ Flexible (İsim – sadece ihtiyaç duyduğu kadar alan alır)
  ///                    │     ├─ Expanded (Çizgi – kalan TÜMÜNÜ doldurur, fiyatı duvara iter)
  ///                    │     └─ Text (Fiyat – doğal/intrinsic genişlik, asla sabit width yok)
  ///                    ├─ [Opsiyonel] Açıklama
  ///                    └─ [Opsiyonel] Varyant Listesi (her biri aynı 3'lü Row kalıbı)
  /// ────────────────────────────────────────────────────────────────────────────
  Widget _buildProductRow(MenuProduct product, Tenant tenant, {bool whatsappEnabled = false}) {
    // ── Stil Tanımları ──
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
    final variantNameStyle = GoogleFonts.lora(
      fontSize: 15,
      color: _appearance.variantTextColor,
      fontStyle: FontStyle.italic,
    );
    final variantPriceStyle = priceStyle.copyWith(fontSize: 15);

    // Emoji olup olmadığını bir kere hesapla
    final bool hasEmoji = product.emoji != null && product.emoji!.isNotEmpty;
    final bool hasVariants = product.variants != null && product.variants!.isNotEmpty;

    return InkWell(
      onTap: whatsappEnabled ? () => showProductDetailSheet(context, product: product, tenant: tenant) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── ÜRÜN GÖRSELİ (Opsiyonel, sabit boyut) ───
            if (_appearance.showProductImages &&
                product.imageUrl != null &&
                product.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey.withOpacity(0.1),
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.grey, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],

            // METİN BLOĞU
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2a. KESİNTİSİZ KÖPRÜ (Fluid Bridge)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // SOL BLOK: İsim ve Noktalar
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (hasEmoji) ...[
                              SizedBox(width: 26, child: Text(product.emoji!, style: const TextStyle(fontSize: 22))),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(product.name, style: nameStyle),
                            ),
                            if (!hasVariants) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: SizedBox(
                                    height: 10,
                                    child: CustomPaint(
                                      painter: _WebSafeDotPainter(color: _appearance.pmDottedLineColor),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                      // SAĞ BLOK: Fiyat
                      if (!hasVariants)
                        Text('${product.price} ${tenant.currencySymbol}', style: priceStyle),
                    ],
                  ),

                  // 2b. ÜRÜN AÇIKLAMASI
                  if (product.description != null &&
                      product.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 30),
                      child: Text(product.description!, style: descStyle),
                    ),

                  // 2c. VARYANT / GRAMAJ LİSTESİ
                  if (hasVariants)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        children: product.variants!.map((variant) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (hasEmoji) const SizedBox(width: 32),
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: Text(variant.name, style: variantNameStyle),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: SizedBox(
                                            height: 10,
                                            child: CustomPaint(
                                              painter: _WebSafeDotPainter(color: _appearance.pmDottedLineColor),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ),
                                Text('${variant.price} ${tenant.currencySymbol}', style: variantPriceStyle),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // SEPET CART BAR
  // ═════════════════════════════════════════════════════════════════════

  /// Sepet Alt Barı
  Widget _buildCartBar(int itemCount, double total, Tenant tenant) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.92),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () => _showWhatsAppOrderSheet(tenant),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                // Sol: Ürün sayısı ve toplam
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$itemCount Ürün  \u2022  ${total.toStringAsFixed(0)} ${tenant.currencySymbol}',
                        style: GoogleFonts.lora(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sağ: Siparişi Tamamla butonu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Siparişi Tamamla',
                    style: GoogleFonts.lora(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// WhatsApp Sipariş Özet Sayfası
  void _showWhatsAppOrderSheet(Tenant tenant) {
    final cartItems = ref.read(cartProvider);
    final cartTotal = ref.read(cartTotalProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Başlık
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sipariş Özeti',
                      style: GoogleFonts.lora(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                      tooltip: 'Sepeti Temizle',
                      onPressed: () {
                        ref.read(cartProvider.notifier).clearCart();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              // Ürün Listesi
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => Divider(height: 24, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Row(
                      children: [
                        // Adet
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.quantity}x',
                            style: GoogleFonts.lora(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Ürün Adı
                        Expanded(
                          child: Text(
                            item.displayName,
                            style: GoogleFonts.lora(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        // Fiyat
                        Text(
                          '${item.totalPrice.toStringAsFixed(0)} ${tenant.currencySymbol}',
                          style: GoogleFonts.lora(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Toplam + WhatsApp Butonu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Toplam Tutar',
                            style: GoogleFonts.lora(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${cartTotal.toStringAsFixed(0)} ${tenant.currencySymbol}',
                            style: GoogleFonts.lora(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _sendWhatsAppOrder(tenant, cartItems, cartTotal),
                          icon: const Icon(Icons.send, size: 20),
                          label: Text(
                            'WhatsApp ile Sipariş Ver',
                            style: GoogleFonts.lora(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// WhatsApp mesajını formatla ve gönder
  void _sendWhatsAppOrder(Tenant tenant, List<CartItem> cartItems, double totalAmount) {
    String message = "Merhaba, sipariş vermek istiyorum:\n\n";
    for (var item in cartItems) {
      message += "${item.quantity}x ${item.displayName} - ${item.totalPrice.toStringAsFixed(0)} ${tenant.currencySymbol}\n";
      if (item.removedIngredients.isNotEmpty) {
        message += "   * Çıkarılacaklar: ${item.removedIngredients.join(', ')}\n";
      }
    }
    message += "\nToplam Tutar: ${totalAmount.toStringAsFixed(0)} ${tenant.currencySymbol}";

    if (tenant.phoneNumber != null && tenant.phoneNumber!.isNotEmpty) {
      final phone = _formatWhatsApp(tenant.phoneNumber!, forUrl: true);
      final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşletmenin telefon numarası tanımlı değil.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Sipariş gönderildikten sonra sepeti temizle ve bottom sheet'i kapat
    ref.read(cartProvider.notifier).clearCart();
    if (mounted) Navigator.of(context).pop();
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

class _WebSafeDotPainter extends CustomPainter {
  final Color color;
  _WebSafeDotPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double currentX = size.width; // Fiyatın yanından (sağdan) başla
    while (currentX > 0) {
      canvas.drawCircle(Offset(currentX, size.height / 2), 1.5, paint);
      currentX -= 6.0; // Noktalar arası boşluk
    }
  }

  @override
  bool shouldRepaint(covariant _WebSafeDotPainter oldDelegate) => oldDelegate.color != color;
}


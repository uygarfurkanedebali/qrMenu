import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_core/shared_core.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/menu_models.dart';
import 'components/noise_painter.dart';

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
  final ItemPositionsListener _mainPositionsListener = ItemPositionsListener.create();

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

  @override
  void initState() {
    super.initState();
    _processCategories();
    _mainPositionsListener.itemPositions.addListener(_onMainScroll);
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
        if (cat.id == '0' || cat.name == 'All Products' || cat.name == 'Tüm Ürünler' || cat.products.isEmpty) {
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
          final descMatch = p.description?.toLowerCase().contains(query) ?? false;
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
      final firstVisible = positions.reduce((min, p) => p.itemLeadingEdge < min.itemLeadingEdge ? p : min);
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
         _overlayTabController.scrollTo(index: tabIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, alignment: 0.45);
      }
      if (_inlineTabController.isAttached) {
         _inlineTabController.scrollTo(index: tabIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, alignment: 0.45);
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
    final bgColor = const Color(0xFFFDFBF7);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: NoisePainter(opacity: 0.05)),
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
                  return _buildTenantHeader(tenant, bgColor);
                } else if (item == 'CATEGORY_BAR') {
                  // Listenin içindeki placeholder da sticky ile aynı görünüme sahip olmalı
                  return _buildStickyHeaderContent(bgColor, controller: _inlineTabController, isOverlay: false);
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
                child: _buildStickyHeaderContent(bgColor, controller: _overlayTabController, isOverlay: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildTenantHeader(Tenant tenant, Color bgColor) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
      child: Column(
        children: [
          Text(
            tenant.name.toUpperCase(),
            style: GoogleFonts.lora(
              color: Colors.black87,
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
                color: Colors.black54,
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
      rows.add(_buildContactRow('instagram.png', '@${tenant.instagramHandle}', () => _launchUrl('https://instagram.com/${tenant.instagramHandle}')));
    }
    if (tenant.phoneNumber != null) {
      final displayPhone = _formatWhatsApp(tenant.phoneNumber!, forUrl: false);
      final urlPhone = _formatWhatsApp(tenant.phoneNumber!, forUrl: true);
      rows.add(_buildContactRow('whatsapp.png', displayPhone, () => _launchUrl('https://wa.me/$urlPhone')));
    }
    if (tenant.wifiName != null) {
       rows.add(_buildContactRow('wifi.png', tenant.wifiName!, () {
           Clipboard.setData(ClipboardData(text: tenant.wifiPassword ?? ''));
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wifi şifresi kopyalandı!"), behavior: SnackBarBehavior.floating));
        }));
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
            Image.network(_getIconUrl(iconName), width: 18, height: 18, errorBuilder: (_,__,___) => const Icon(Icons.link, size: 18, color: Colors.black54)),
            const SizedBox(width: 8),
            Text(text, style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // --- GÜNCELLENMİŞ STICKY HEADER ---
  // Hem Kategori Listesini hem de Arama Barını yönetir
  Widget _buildStickyHeaderContent(Color bgColor, {required ItemScrollController controller, required bool isOverlay}) {
    final boxDecoration = isOverlay 
      ? BoxDecoration(
          color: bgColor.withOpacity(0.98),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
          border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
        )
      : BoxDecoration(color: bgColor);

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
              icon: const Icon(Icons.search, color: Colors.black54),
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
              ? const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black87, width: 2.5)))
              : null,
            child: Text(
              cat.name.toUpperCase(),
              style: GoogleFonts.lora(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.black87 : Colors.black45,
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
        style: GoogleFonts.lora(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Ürün ara...',
          hintStyle: GoogleFonts.lora(fontSize: 14, color: Colors.black38, fontStyle: FontStyle.italic),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(bottom: 8),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, color: Colors.black54),
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
          const Icon(Icons.star_rate_rounded, size: 14, color: Colors.black26),
          const SizedBox(height: 8),
          Text(
            category.name.toUpperCase(),
             style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(MenuProduct product, Tenant tenant) {
    final nameStyle = GoogleFonts.lora(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87);
    final priceStyle = GoogleFonts.lora(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87);
    final descStyle = GoogleFonts.lora(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black54, height: 1.3);

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
              Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 6), child: CustomPaint(painter: _DottedLinePainter()))),
              const SizedBox(width: 8),
              Text('${product.price} ${tenant.currencySymbol}', style: priceStyle),
            ],
          ),
          if (product.description != null && product.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 30),
              child: Text(product.description!, style: descStyle),
            )
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.black12),
          const SizedBox(height: 16),
          Text(
            "Sonuç bulunamadı",
            style: GoogleFonts.lora(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black45),
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
          const Icon(Icons.circle, size: 6, color: Colors.black12),
          const SizedBox(height: 20),
          Text(
            "Afiyet Olsun",
            style: GoogleFonts.lora(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black26..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawCircle(Offset(startX, size.height), 0.5, paint);
      startX += 5; 
    }
  }
  @override
  bool shouldRepaint(old) => false;
}
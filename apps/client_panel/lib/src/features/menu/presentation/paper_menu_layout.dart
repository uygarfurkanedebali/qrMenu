import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_core/shared_core.dart';
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
  // Ürün listesi için controller
  final ItemScrollController _productScrollController = ItemScrollController();
  final ItemPositionsListener _productPositionsListener = ItemPositionsListener.create();

  // Kategori barı için controller (YENİ: Bunu da akıllı listeye çevirdik)
  final ItemScrollController _categoryScrollController = ItemScrollController();

  List<dynamic> _flatList = [];
  
  // Hangi kategori ID'si kaçıncı indexte başlıyor?
  final Map<String, int> _categoryStartIndex = {};
  
  // Hangi index (ürün satırı) hangi kategoriye ait?
  final Map<int, String> _indexToCategoryId = {};
  
  List<MenuCategory> _filteredCategories = [];
  String? _selectedCategoryId;
  
  // Elle tıklandığında listener'ın tetiklenmesini engellemek için flag
  bool _isTabClicked = false;

  @override
  void initState() {
    super.initState();
    _processCategories();
    _productPositionsListener.itemPositions.addListener(_onProductScroll);
  }

  void _processCategories() {
    _flatList = [];
    _categoryStartIndex.clear();
    _indexToCategoryId.clear();
    _filteredCategories = [];

    int globalIndex = 0;

    for (var cat in widget.categories) {
      // Boş veya sistem kategorilerini atla
      if (cat.id == '0' || cat.name == 'All Products' || cat.name == 'Tüm Ürünler' || cat.products.isEmpty) {
        continue;
      }

      _filteredCategories.add(cat);
      
      // Kategori Başlığı Ekle
      _flatList.add(cat); 
      _categoryStartIndex[cat.id] = globalIndex;
      _indexToCategoryId[globalIndex] = cat.id;
      globalIndex++;

      // Ürünleri Ekle
      for (var product in cat.products) {
        _flatList.add(product);
        _indexToCategoryId[globalIndex] = cat.id;
        globalIndex++;
      }
    }

    // Footer için yer tutucu
    _flatList.add('FOOTER');
    
    // İlk kategoriyi seçili yap
    if (_filteredCategories.isNotEmpty) {
      _selectedCategoryId = _filteredCategories.first.id;
    }
  }

  // Kullanıcı aşağı kaydırdıkça çalışır
  void _onProductScroll() {
    if (_isTabClicked) return; // Elle tıkladıysa hesaplamayı durdur

    final positions = _productPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Ekranda görünen en üstteki elemanı bul
    // itemLeadingEdge: 0 ekranın tepesi demektir.
    // Negatif olmayan en küçük leadingEdge'e sahip eleman veya 0'a en yakın eleman.
    
    final firstVisible = positions
        .where((p) => p.itemLeadingEdge < 0.5) // Ekranın yarısından yukarısı
        .reduce((max, p) => p.itemLeadingEdge > max.itemLeadingEdge ? p : max);

    final currentId = _indexToCategoryId[firstVisible.index];

    if (currentId != null && currentId != _selectedCategoryId) {
      setState(() {
        _selectedCategoryId = currentId;
      });
      _syncCategoryHeader(currentId);
    }
  }

  // Kategori barını ortalayarak kaydır
  void _syncCategoryHeader(String categoryId) {
    int catIndex = _filteredCategories.indexWhere((c) => c.id == categoryId);
    if (catIndex != -1) {
      _categoryScrollController.scrollTo(
        index: catIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5, // ÖNEMLİ: Seçilen öğeyi tam ortaya getirir
      );
    }
  }

  // Kategoriye tıklandığında
  void _onCategoryTap(String categoryId) async {
    setState(() {
      _isTabClicked = true; // Otomatik algılamayı geçici durdur
      _selectedCategoryId = categoryId;
    });

    // 1. Üst barı ortala
    _syncCategoryHeader(categoryId);

    // 2. Ürün listesini o kategoriye kaydır
    if (_categoryStartIndex.containsKey(categoryId)) {
      await _productScrollController.scrollTo(
        index: _categoryStartIndex[categoryId]!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.04, // Header'ın hemen altına denk gelmesi için küçük bir offset (Sticky header payı)
      );
    }

    // Animasyon bitince flag'i aç
    await Future.delayed(const Duration(milliseconds: 700));
    _isTabClicked = false;
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  String _getIconUrl(String fileName) {
    // Supabase URL'ini buraya kendi projenizden alın
    const String supabaseUrl = 'https://jswvvrxpjvsdqcayynzi.supabase.co'; 
    return '$supabaseUrl/storage/v1/object/public/assets/icons/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    final tenant = widget.tenant;
    final bgColor = const Color(0xFFFDFBF7);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Arkaplan Dokusu
          Positioned.fill(
            child: CustomPaint(painter: NoisePainter(opacity: 0.05)),
          ),

          // Ana Yapı
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // 1. STATİK OLMAYAN (Yukarı kayıp giden) TENANT BİLGİSİ
                SliverToBoxAdapter(
                  child: _buildTenantHeader(tenant, bgColor),
                ),

                // 2. STICKY HEADER (Yapışkan Kategori Barı)
                SliverPersistentHeader(
                  pinned: true, // Bu sayede yukarı yapışır
                  delegate: _StickyCategoryListDelegate(
                    categories: _filteredCategories,
                    selectedCategoryId: _selectedCategoryId,
                    onSelect: _onCategoryTap,
                    bgColor: bgColor,
                    itemScrollController: _categoryScrollController,
                  ),
                ),
              ];
            },
            // 3. ÜRÜN LİSTESİ
            body: ScrollablePositionedList.builder(
              itemCount: _flatList.length,
              itemScrollController: _productScrollController,
              itemPositionsListener: _productPositionsListener,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
              itemBuilder: (context, index) {
                final item = _flatList[index];

                if (item is MenuCategory) {
                  return _buildCategoryTitle(item);
                } else if (item is MenuProduct) {
                  return _buildProductRow(item, tenant);
                } else if (item == 'FOOTER') {
                  return _buildFooter(tenant);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ... (Tenant Header, Footer ve Product Row widget'ları aynı kalabilir) ...
  // Sadece mantık değiştiği için _buildCategoryTitle ismini değiştirdim, içi aynı.
  
  Widget _buildTenantHeader(Tenant tenant, Color bgColor) {
     return Container(
      color: bgColor.withValues(alpha: 0.95),
      padding: const EdgeInsets.only(top: 50, bottom: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tenant.name.toUpperCase(),
            style: GoogleFonts.lora(
              color: Colors.black87,
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
            ),
            textAlign: TextAlign.center,
          ),
          // ... (Instagram, Wifi vb. kodları buraya aynen gelebilir) ...
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryTitle(MenuCategory category) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.star_rate_rounded, size: 16, color: Colors.black.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text(
            category.name.toUpperCase(),
             style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(height: 1, width: 60, color: Colors.black12),
        ],
      ),
    );
  }
  
  // Dotted Line Painter ve Product Row kodları önceki kodunuzdan aynen alınabilir.
  // Yer kaplamaması için buraya tekrar yazmıyorum, yukarıdaki kodunuzdakiyle aynı.
  Widget _buildProductRow(MenuProduct product, Tenant tenant) {
      // ... (Eski kodunuzdaki _buildProductRow içeriği)
      return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(product.name, style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87))),
              const SizedBox(width: 8),
               // Noktalı çizgi...
              const SizedBox(width: 8),
              Text('${product.price} ${tenant.currencySymbol}', style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
           if (product.description != null && product.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 20),
              child: Text(product.description!, style: GoogleFonts.lora(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54)),
            )
        ],
      ),
    );
  }

  Widget _buildFooter(Tenant tenant) {
     // ... (Eski kodunuzdaki _buildFooter içeriği)
     return const SizedBox(height: 100);
  }
}

// -----------------------------------------------------------------------------
// GÜNCELLENMİŞ STICKY HEADER DELEGATE
// -----------------------------------------------------------------------------
class _StickyCategoryListDelegate extends SliverPersistentHeaderDelegate {
  final List<MenuCategory> categories;
  final String? selectedCategoryId;
  final Function(String) onSelect;
  final Color bgColor;
  final ItemScrollController itemScrollController; // ARTIK BU DA AKILLI SCROLL

  _StickyCategoryListDelegate({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
    required this.bgColor,
    required this.itemScrollController,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bgColor, // Arkası şeffaf olmasın, içerik karışmasın
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Gölgelendirme çizgisi (opsiyonel)
          Container(height: 1, color: Colors.black.withValues(alpha: 0.05)),
          
          Expanded(
            child: ScrollablePositionedList.builder(
              itemCount: categories.length,
              itemScrollController: itemScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat.id == selectedCategoryId;
                
                return GestureDetector(
                  onTap: () => onSelect(cat.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: isSelected 
                      ? const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.black87, width: 2)),
                        )
                      : null,
                    child: Text(
                      cat.name.toUpperCase(),
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.black87 : Colors.black45,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
           // Alt çizgi
           Container(height: 1, color: Colors.black.withValues(alpha: 0.05)),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 50; // Bar yüksekliği

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(covariant _StickyCategoryListDelegate oldDelegate) {
    return oldDelegate.selectedCategoryId != selectedCategoryId ||
           oldDelegate.categories != categories;
  }
}
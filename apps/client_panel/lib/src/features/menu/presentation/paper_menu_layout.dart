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
  // Ürün listesi için
  final ItemScrollController _productScrollController = ItemScrollController();
  final ItemPositionsListener _productPositionsListener = ItemPositionsListener.create();

  // Kategori listesi için
  final ItemScrollController _categoryScrollController = ItemScrollController();

  List<dynamic> _flatList = [];
  final Map<String, int> _categoryStartIndex = {};
  final Map<int, String> _indexToCategoryId = {};
  List<MenuCategory> _filteredCategories = [];
  
  String? _selectedCategoryId;
  bool _isTabClicked = false; // Elle tıklama kontrolü

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
      if (cat.id == '0' || cat.name == 'All Products' || cat.name == 'Tüm Ürünler' || cat.products.isEmpty) {
        continue;
      }

      _filteredCategories.add(cat);
      
      // Kategori Başlığı (Listede görünen büyük başlık)
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

    _flatList.add('FOOTER');
    
    if (_filteredCategories.isNotEmpty) {
      _selectedCategoryId = _filteredCategories.first.id;
    }
  }

  // Aşağı kaydırdıkça kategoriyi güncelle
  void _onProductScroll() {
    if (_isTabClicked) return;

    final positions = _productPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Ekranın %30'luk üst kısmına giren ilk öğeyi yakala
    final firstVisible = positions
        .where((p) => p.itemLeadingEdge < 0.3) 
        .reduce((max, p) => p.itemLeadingEdge > max.itemLeadingEdge ? p : max);

    final currentId = _indexToCategoryId[firstVisible.index];

    if (currentId != null && currentId != _selectedCategoryId) {
      setState(() {
        _selectedCategoryId = currentId;
      });
      _scrollToCategoryTab(currentId);
    }
  }

  // Üst barı hizala
  void _scrollToCategoryTab(String categoryId) {
    int index = _filteredCategories.indexWhere((c) => c.id == categoryId);
    if (index != -1) {
      _categoryScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        // HİLE BURADA: 0.5 tam ortalar ama yazı uzunsa sağa kayar.
        // 0.42 - 0.45 arası bir değer genelde görsel olarak tam ortaya denk gelir.
        alignment: 0.42, 
      );
    }
  }

  void _onCategoryTap(String categoryId) async {
    setState(() {
      _isTabClicked = true;
      _selectedCategoryId = categoryId;
    });

    _scrollToCategoryTab(categoryId);

    if (_categoryStartIndex.containsKey(categoryId)) {
      await _productScrollController.scrollTo(
        index: _categoryStartIndex[categoryId]!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        // Kategori başlığı yapışkan barın hemen altına gelsin (biraz boşluk bırakarak)
        alignment: 0.08, 
      );
    }

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

          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // 1. KISIM: RESTORAN BİLGİLERİ (Aşağı indikçe kaybolur)
                // SliverToBoxAdapter kullandığımız için sayfa içeriğiyle beraber yukarı kayar.
                SliverToBoxAdapter(
                  child: _buildTenantHeader(tenant, bgColor),
                ),

                // 2. KISIM: KATEGORİ ŞERİDİ (Yukarı yapışır - Pinned)
                SliverPersistentHeader(
                  pinned: true, 
                  floating: false,
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
            // 3. KISIM: ÜRÜN LİSTESİ
            body: ScrollablePositionedList.builder(
              itemCount: _flatList.length,
              itemScrollController: _productScrollController,
              itemPositionsListener: _productPositionsListener,
              padding: const EdgeInsets.only(bottom: 100), // En alta boşluk
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

  // --- WIDGET PARÇALARI ---

  Widget _buildTenantHeader(Tenant tenant, Color bgColor) {
    // Restoran bilgilerini buraya taşıdık. SliverToBoxAdapter içinde olduğu için
    // sayfayı kaydırdığınızda yukarı doğru gidip kaybolacak.
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
          
          const SizedBox(height: 20),
          _buildContactIcons(tenant),
          const SizedBox(height: 10),
          Container(height: 1, width: 80, color: Colors.black12),
        ],
      ),
    );
  }

  Widget _buildContactIcons(Tenant tenant) {
    final List<Widget> icons = [];

    // Instagram
    if (tenant.instagramHandle != null) {
      icons.add(_iconButton('instagram.png', () => _launchUrl('https://instagram.com/${tenant.instagramHandle}')));
    }
    
    // WhatsApp
    if (tenant.phoneNumber != null) {
      if (icons.isNotEmpty) icons.add(const SizedBox(width: 20));
      final phone = _formatWhatsApp(tenant.phoneNumber!, forUrl: true);
      icons.add(_iconButton('whatsapp.png', () => _launchUrl('https://wa.me/$phone')));
    }

    // Wifi
    if (tenant.wifiName != null) {
      if (icons.isNotEmpty) icons.add(const SizedBox(width: 20));
      icons.add(_iconButton('wifi.png', () {
         Clipboard.setData(ClipboardData(text: tenant.wifiPassword ?? ''));
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wifi şifresi kopyalandı!")));
      }));
    }

    if (icons.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: icons);
  }

  Widget _iconButton(String iconName, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(50),
          color: Colors.white.withOpacity(0.5)
        ),
        child: Image.network(
          _getIconUrl(iconName),
          width: 20, height: 20,
          errorBuilder: (_,__,___) => const Icon(Icons.link, size: 20, color: Colors.black54),
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
          Icon(Icons.star_rate_rounded, size: 14, color: Colors.black26),
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
              // Noktalı çizgi
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

// -----------------------------------------------------------------------------
// STICKY HEADER (YAPIŞKAN KATEGORİ BARI)
// -----------------------------------------------------------------------------
class _StickyCategoryListDelegate extends SliverPersistentHeaderDelegate {
  final List<MenuCategory> categories;
  final String? selectedCategoryId;
  final Function(String) onSelect;
  final Color bgColor;
  final ItemScrollController itemScrollController;

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
      color: bgColor.withOpacity(0.98), // Arka planın görünmemesi için
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Üst Çizgi
          Container(height: 1, color: Colors.black.withOpacity(0.05)),
          
          Expanded(
            child: ScrollablePositionedList.builder(
              itemCount: categories.length,
              itemScrollController: itemScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16), // Baş ve sondaki boşluk
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
                          border: Border(bottom: BorderSide(color: Colors.black87, width: 2.5)),
                        )
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
            ),
          ),
           // Alt Çizgi (Gölge efekti)
           Container(height: 1, color: Colors.black.withOpacity(0.08)),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 56; // Bar yüksekliği

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant _StickyCategoryListDelegate oldDelegate) {
    return oldDelegate.selectedCategoryId != selectedCategoryId ||
           oldDelegate.categories != categories;
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
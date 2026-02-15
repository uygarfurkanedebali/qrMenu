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

class _PaperMenuLayoutState extends State<PaperMenuLayout> with SingleTickerProviderStateMixin {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  
  // Flattened list of items (Category Header or Product)
  List<dynamic> _flatList = [];
  // Map to store indices of category headers for scrolling
  final Map<String, int> _categoryIndices = {};
  // Filtered actual categories (for the tab bar)
  List<MenuCategory> _filteredCategories = [];
  
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _processCategories();
  }
  
  void _processCategories() {
    _flatList = [];
    _categoryIndices.clear();
    _filteredCategories = [];

    int indexChecker = 0;

    for (var cat in widget.categories) {
      // 1. FILTER SYSTEM CATEGORY
      if (cat.id == '0' || 
          cat.name == 'All Products' || 
          cat.name == 'Tüm Ürünler') {
        continue;
      }
      
      // Ensure category has products
      if (cat.products.isNotEmpty) {
        _filteredCategories.add(cat);
        
        // Track where this category starts
        _categoryIndices[cat.id] = indexChecker;
        if (_selectedCategoryId == null) _selectedCategoryId = cat.id;

        // Add Category Header
        _flatList.add(cat);
        indexChecker++;
        
        // Add Products
        _flatList.addAll(cat.products);
        indexChecker += cat.products.length;
      }
    }
  }

  void _scrollToCategory(String categoryId) {
    if (_categoryIndices.containsKey(categoryId)) {
      setState(() => _selectedCategoryId = categoryId);
      _itemScrollController.scrollTo(
        index: _categoryIndices[categoryId]!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = widget.tenant;
    final config = tenant.designConfig;
    final bool useTexture = config['texture'] ?? true; 
    
    // Background Color: Warm White / Paper
    final bgColor = const Color(0xFFFDFBF7);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Noise Texture
          if (useTexture)
            Positioned.fill(
              child: CustomPaint(painter: NoisePainter(opacity: 0.05)),
            ),

          // 2. Content
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // LOGO / BRANDING
                SliverAppBar(
                  backgroundColor: bgColor.withValues(alpha: 0.95),
                  surfaceTintColor: Colors.transparent, // Disable Material 3 tint
                  elevation: 0,
                  pinned: false,
                  floating: true,
                  snap: true,
                  expandedHeight: 120,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    titlePadding: const EdgeInsets.only(bottom: 20),
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tenant.name.toUpperCase(),
                          style: GoogleFonts.lora(
                            color: Colors.black87,
                            fontSize: 22, // SliverAppBar scales this, roughly
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (tenant.instagramHandle != null)
                          Text(
                            '@${tenant.instagramHandle}',
                            style: GoogleFonts.lora(
                              color: Colors.black54,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        const SizedBox(height: 12),
                        // SOCIAL ICONS ROW (Small)
                        const SizedBox(height: 12),
                        // SOCIAL & WIFI ICONS ROW
                        Builder(builder: (context) {
                          final List<Widget> headerItems = [];

                          // 1. Instagram
                          if (tenant.instagramHandle != null && tenant.instagramHandle!.isNotEmpty) {
                            headerItems.add(
                              InkWell(
                                onTap: () => _launchUrl('https://instagram.com/${tenant.instagramHandle}'),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset('assets/icons/instagram.png', width: 14, height: 14),
                                    const SizedBox(width: 4),
                                    Text(tenant.instagramHandle!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                ),
                              ),
                            );
                          }

                          // 2. WhatsApp
                          if (tenant.phoneNumber != null && tenant.phoneNumber!.isNotEmpty) {
                            if (headerItems.isNotEmpty) {
                              headerItems.add(const Text('  |  ', style: TextStyle(color: Colors.black26)));
                            }
                            final cleanPhone = tenant.phoneNumber!.replaceAll(RegExp(r'[^0-9]'), '');
                            headerItems.add(
                              InkWell(
                                onTap: () => _launchUrl('https://wa.me/$cleanPhone'),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset('assets/icons/whatsapp.png', width: 14, height: 14),
                                    const SizedBox(width: 4),
                                    Text(tenant.phoneNumber!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                ),
                              ),
                            );
                          }

                          // 3. WiFi
                          if (tenant.wifiName != null && tenant.wifiName!.isNotEmpty) {
                            if (headerItems.isNotEmpty) {
                              headerItems.add(const Text('  |  ', style: TextStyle(color: Colors.black26)));
                            }
                            headerItems.add(
                              InkWell(
                                onTap: () async {
                                  if (tenant.wifiPassword != null && tenant.wifiPassword!.isNotEmpty) {
                                    await Clipboard.setData(ClipboardData(text: tenant.wifiPassword!));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                'WiFi şifresi kopyalandı: ${tenant.wifiPassword}',
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.black87,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          margin: const EdgeInsets.only(bottom: 30, left: 40, right: 40), // Small and centered
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.wifi, size: 14, color: Colors.black54),
                                    const SizedBox(width: 4),
                                    Text(tenant.wifiName!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          if (headerItems.isEmpty) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: headerItems,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // STICKY CATEGORY HEADER
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyCategoryHeaderDelegate(
                    categories: _filteredCategories,
                    selectedCategoryId: _selectedCategoryId,
                    onSelect: _scrollToCategory,
                    bgColor: bgColor,
                  ),
                ),
              ];
            },
            body: ScrollablePositionedList.builder(
              itemCount: _flatList.length,
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 100),
              itemBuilder: (context, index) {
                final item = _flatList[index];

                if (item is MenuCategory) {
                  return _buildCategoryHeader(item);
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

  Widget _buildCategoryHeader(MenuCategory category) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
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

  Widget _buildProductRow(MenuProduct product, Tenant tenant) {
    // TYPOGRAPHY & AESTHETICS
    // Product Name: Bold (w700), Black.
    // Price: w600, Black.
    // Description: Italic, Black54, lower size.
    
    final nameStyle = GoogleFonts.lora(
      fontSize: 16, 
      fontWeight: FontWeight.w700, 
      color: Colors.black87
    );
    
    final priceStyle = GoogleFonts.lora(
      fontSize: 16, 
      fontWeight: FontWeight.w600, 
      color: Colors.black87
    );
    
    final descStyle = GoogleFonts.lora(
      fontSize: 13, 
      fontStyle: FontStyle.italic, 
      color: Colors.black54,
      height: 1.4,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX PRODUCT ROW LAYOUT
          Row(
            crossAxisAlignment: CrossAxisAlignment.end, // Align bottom
            children: [
              Text(product.name, style: nameStyle), // Left
              const SizedBox(width: 8),
              
              // Spacer with Dots
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6), // Align dots with baseline
                  child: CustomPaint(painter: _DottedLinePainter()),
                ),
              ),
              
              const SizedBox(width: 8),
              Text(
                '${product.price} ${tenant.currencySymbol}', 
                style: priceStyle
              ), // Right
            ],
          ),
          
          if (product.description != null && product.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 48), // Leave space on right for readability
              child: Text(product.description!, style: descStyle),
            ),
          ]
        ],
      ),
    );
  }
  Widget _buildFooter(Tenant tenant) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Container(height: 1, width: 60, color: Colors.black12),
          const SizedBox(height: 40),
          
          // Instagram Button
          if (tenant.instagramHandle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton(
                onPressed: () => _launchUrl('https://instagram.com/${tenant.instagramHandle}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black12),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/instagram.png', 
                      width: 24, 
                      height: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.camera_alt, size: 24, color: Colors.black87),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Bizi Instagram'da Takip Edin",
                      style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

          // WhatsApp Button
          if (tenant.phoneNumber != null && tenant.phoneNumber!.isNotEmpty)
            OutlinedButton(
              onPressed: () {
                final cleanPhone = tenant.phoneNumber!.replaceAll(RegExp(r'[^0-9]'), '');
                _launchUrl('https://wa.me/$cleanPhone');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Colors.black12),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/whatsapp.png', 
                    width: 24, 
                    height: 24,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.chat, size: 24, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  Text(
                     "WhatsApp'tan Sipariş Ver",
                     style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 40),
          Text(
            "Powered by QR-Infinity",
            style: GoogleFonts.lora(fontSize: 10, color: Colors.black26, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// STICKY HEADER DELEGATE
// -----------------------------------------------------------------------------
class _StickyCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<MenuCategory> categories;
  final String? selectedCategoryId;
  final Function(String) onSelect;
  final Color bgColor;

  _StickyCategoryHeaderDelegate({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bgColor.withValues(alpha: 0.95), // slightly transparent paper
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
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
          // Optional: Tiny shadow line
          if (overlapsContent)
            Container(height: 1, color: Colors.black.withValues(alpha: 0.03)),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 50; // Height of the bar

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(covariant _StickyCategoryHeaderDelegate oldDelegate) {
    return oldDelegate.selectedCategoryId != selectedCategoryId ||
           oldDelegate.categories != categories;
  }
}

// -----------------------------------------------------------------------------
// DOTTED LINE PAINTER
// -----------------------------------------------------------------------------
class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    
    double startX = 0;
    while (startX < size.width) {
      canvas.drawCircle(Offset(startX, size.height), 0.8, paint);
      startX += 6; // Space between dots
    }
  }
  
  @override
  bool shouldRepaint(old) => false;
}

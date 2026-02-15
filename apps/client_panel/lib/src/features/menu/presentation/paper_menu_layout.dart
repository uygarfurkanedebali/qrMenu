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
  final ScrollController _tabScrollController = ScrollController();
  
  List<dynamic> _flatList = [];
  final Map<String, int> _categoryIndices = {};
  List<MenuCategory> _filteredCategories = [];
  
  String? _selectedCategoryId;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _processCategories();
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);
  }

  @override
  void dispose() {
    _tabScrollController.dispose();
    super.dispose();
  }
  
  void _processCategories() {
    _flatList = [];
    _categoryIndices.clear();
    _filteredCategories = [];

    int indexChecker = 0;

    for (var cat in widget.categories) {
      if (cat.id == '0' || cat.name == 'All Products' || cat.name == 'Tüm Ürünler') continue;
      
      if (cat.products.isNotEmpty) {
        _filteredCategories.add(cat);
        _categoryIndices[cat.id] = indexChecker;
        if (_selectedCategoryId == null) _selectedCategoryId = cat.id;

        _flatList.add(cat);
        indexChecker++;
        
        _flatList.addAll(cat.products);
        indexChecker += cat.products.length;
      }
    }
  }

  // Auto-select category based on scroll position
  void _onItemPositionsChanged() {
    if (_isAutoScrolling) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Find the first visible item near the top
    int firstVisibleIndex = positions
        .where((p) => p.itemTrailingEdge > 0.05)
        .reduce((min, p) => p.itemLeadingEdge < min.itemLeadingEdge ? p : min)
        .index;

    String? activeCategoryId;
    for (int i = 0; i <= firstVisibleIndex; i++) {
      final item = _flatList[i];
      if (item is MenuCategory) {
        activeCategoryId = item.id;
      }
    }

    if (activeCategoryId != null && activeCategoryId != _selectedCategoryId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedCategoryId = activeCategoryId;
          });
          _scrollToTab(activeCategoryId!);
        }
      });
    }
  }

  void _scrollToTab(String categoryId) {
    if (!_tabScrollController.hasClients) return;
    int tabIndex = _filteredCategories.indexWhere((c) => c.id == categoryId);
    if (tabIndex != -1) {
      double offset = tabIndex * 110.0; // Approximate tab width
      double maxScroll = _tabScrollController.position.maxScrollExtent;
      if (offset > maxScroll) offset = maxScroll;
      
      _tabScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToCategory(String categoryId) async {
    if (_categoryIndices.containsKey(categoryId)) {
      setState(() => _selectedCategoryId = categoryId);
      _scrollToTab(categoryId);
      _isAutoScrolling = true;
      await _itemScrollController.scrollTo(
        index: _categoryIndices[categoryId]!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
      await Future.delayed(const Duration(milliseconds: 100));
      _isAutoScrolling = false;
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  String _getIconUrl(String fileName) {
    final String supabaseUrl = 'https://jswvvrxpjvsdqcayynzi.supabase.co'; 
    return '$supabaseUrl/storage/v1/object/public/assets/icons/$fileName';
  }

  // Format phone for display (+90...) and URL (90...)
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
    final config = tenant.designConfig;
    final bool useTexture = config['texture'] ?? true; 
    final bgColor = const Color(0xFFFDFBF7);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          if (useTexture)
            Positioned.fill(
              child: CustomPaint(painter: NoisePainter(opacity: 0.05)),
            ),

          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Container(
                    color: bgColor.withValues(alpha: 0.95),
                    padding: const EdgeInsets.only(top: 60, bottom: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tenant.name.toUpperCase(),
                          style: GoogleFonts.lora(
                            color: Colors.black87,
                            fontSize: 28, 
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
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Builder(builder: (context) {
                          final List<Widget> headerItems = [];

                          if (tenant.instagramHandle != null && tenant.instagramHandle!.isNotEmpty) {
                            headerItems.add(
                              InkWell(
                                onTap: () => _launchUrl('https://instagram.com/${tenant.instagramHandle}'),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.network(
                                      _getIconUrl('instagram.png'), 
                                      width: 14, height: 14,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.camera_alt, size: 14, color: Colors.black54),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(tenant.instagramHandle!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (tenant.phoneNumber != null && tenant.phoneNumber!.isNotEmpty) {
                            if (headerItems.isNotEmpty) {
                              headerItems.add(const Text('   |   ', style: TextStyle(color: Colors.black26, fontSize: 12)));
                            }
                            final cleanUrlPhone = _formatWhatsApp(tenant.phoneNumber!, forUrl: true);
                            final displayPhone = _formatWhatsApp(tenant.phoneNumber!, forUrl: false);
                            
                            headerItems.add(
                              InkWell(
                                onTap: () => _launchUrl('https://wa.me/$cleanUrlPhone'),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.network(
                                      _getIconUrl('whatsapp.png'), 
                                      width: 14, height: 14,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.chat, size: 14, color: Colors.black54),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(displayPhone, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (tenant.wifiName != null && tenant.wifiName!.isNotEmpty) {
                            if (headerItems.isNotEmpty) {
                              headerItems.add(const Text('   |   ', style: TextStyle(color: Colors.black26, fontSize: 12)));
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
                                              Text('WiFi şifresi kopyalandı: ${tenant.wifiPassword}', style: const TextStyle(fontSize: 13)),
                                            ],
                                          ),
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.black87,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          margin: const EdgeInsets.only(bottom: 30, left: 40, right: 40),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.network(
                                      _getIconUrl('wifi.png'), 
                                      width: 14, height: 14,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.wifi, size: 14, color: Colors.black54),
                                    ),
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

                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyCategoryHeaderDelegate(
                    categories: _filteredCategories,
                    selectedCategoryId: _selectedCategoryId,
                    onSelect: _scrollToCategory,
                    bgColor: bgColor,
                    tabScrollController: _tabScrollController,
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
    final nameStyle = GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87);
    final priceStyle = GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87);
    final descStyle = GoogleFonts.lora(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54, height: 1.4);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(product.name, style: nameStyle),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: CustomPaint(painter: _DottedLinePainter()),
                ),
              ),
              const SizedBox(width: 8),
              Text('${product.price} ${tenant.currencySymbol}', style: priceStyle),
            ],
          ),
          if (product.description != null && product.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 48),
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
                    Image.network(
                      _getIconUrl('instagram.png'), 
                      width: 24, height: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.camera_alt, size: 24, color: Colors.black87),
                    ),
                    const SizedBox(width: 12),
                    Text("Bizi Instagram'da Takip Edin", style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),

          if (tenant.phoneNumber != null && tenant.phoneNumber!.isNotEmpty)
            OutlinedButton(
              onPressed: () {
                final cleanUrlPhone = _formatWhatsApp(tenant.phoneNumber!, forUrl: true);
                _launchUrl('https://wa.me/$cleanUrlPhone');
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
                  Image.network(
                    _getIconUrl('whatsapp.png'), 
                    width: 24, height: 24,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.chat, size: 24, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  Text("WhatsApp'tan Sipariş Ver", style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w600)),
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
  final ScrollController tabScrollController;

  _StickyCategoryHeaderDelegate({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
    required this.bgColor,
    required this.tabScrollController,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bgColor.withValues(alpha: 0.95),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
            ),
            child: ListView.builder(
              controller: tabScrollController,
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
          if (overlapsContent)
            Container(height: 1, color: Colors.black.withValues(alpha: 0.03)),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 50;

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
      startX += 6; 
    }
  }
  
  @override
  bool shouldRepaint(old) => false;
}
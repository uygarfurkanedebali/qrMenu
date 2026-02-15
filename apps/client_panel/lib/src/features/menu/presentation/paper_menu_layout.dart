import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_core/shared_core.dart'; // Ensure this exports Tenant, Category, Product
import '../domain/menu_models.dart'; // Importing this to possibly map types if needed
import 'components/noise_painter.dart';

class PaperMenuLayout extends StatefulWidget {
  final Tenant tenant;
  final List<MenuCategory> categories; // Using MenuCategory to match Client Panel domain
  // Sepet mantığı için gerekirse callbackler eklenebilir
  
  const PaperMenuLayout({
    super.key,
    required this.tenant,
    required this.categories,
  });

  @override
  State<PaperMenuLayout> createState() => _PaperMenuLayoutState();
}

class _PaperMenuLayoutState extends State<PaperMenuLayout> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  
  // Basitlik için tüm ürünleri tek bir düz listede (flat list) tutacağız.
  // Her eleman ya bir "Başlık" (Kategori) ya da bir "Ürün" olacak.
  List<dynamic> _flatList = [];

  @override
  void initState() {
    super.initState();
    _buildFlatList();
  }

  void _buildFlatList() {
    _flatList = [];
    for (var cat in widget.categories) {
      if (cat.products.isNotEmpty) {
        _flatList.add(cat); // Kategori Başlığı
        _flatList.addAll(cat.products); // Ürünler
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.tenant.designConfig;
    final bool useTexture = config['texture'] ?? false;
    final String fontFamily = config['font'] ?? 'Inter';
    
    // Font seçimi
    TextStyle baseStyle;
    try {
      baseStyle = GoogleFonts.getFont(fontFamily);
    } catch (_) {
      baseStyle = GoogleFonts.inter();
    }

    // Sıcak/Kırık Beyaz Arkaplan
    final bgColor = const Color(0xFFFDFBF7);

  // Parse primary color safely
  final primaryColorHex = widget.tenant.primaryColor;
  Color primaryColor;
  try {
    primaryColor = Color(int.parse('FF${primaryColorHex.replaceAll('#', '')}', radix: 16));
  } catch (e) {
    primaryColor = Colors.black;
  }

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Doku Katmanı (Opsiyonel)
          if (useTexture)
            Positioned.fill(
              child: CustomPaint(painter: NoisePainter(opacity: 0.05)),
            ),

          // 2. İçerik
          CustomScrollView(
            slivers: [
              // Header (Logo)
              SliverAppBar(
                backgroundColor: bgColor.withValues(alpha: 0.9),
                elevation: 0,
                floating: false,
                pinned: true,
                expandedHeight: 120.0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    widget.tenant.name,
                    style: baseStyle.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Liste
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _flatList[index];

                      if (item is MenuCategory) {
                        // --- KATEGORİ BAŞLIĞI ---
                        return Container(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                item.name.toUpperCase(),
                                style: baseStyle.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                  color: primaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Divider(indent: 100, endIndent: 100, thickness: 1, color: Colors.black26),
                            ],
                          ),
                        );
                      } else if (item is MenuProduct) {
                        // --- ÜRÜN SATIRI ---
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: baseStyle.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Noktalı Çizgi (Spacer)
                                  Expanded(
                                    child: CustomPaint(
                                      painter: _DottedLinePainter(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${item.price} ${widget.tenant.currencySymbol}',
                                    style: baseStyle.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.description != null && item.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, right: 40),
                                  child: Text(
                                    item.description!,
                                    style: baseStyle.copyWith(
                                      fontSize: 13,
                                      color: Colors.black54,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    childCount: _flatList.length,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    
    double startX = 0;
    while (startX < size.width) {
      canvas.drawCircle(Offset(startX, size.height), 1, paint);
      startX += 6; // Nokta aralığı
    }
  }
  @override
  bool shouldRepaint(old) => false;
}

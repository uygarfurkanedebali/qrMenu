import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;

  const AdminLayout({Key? key, required this.child}) : super(key: key);

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  bool _isRailExtended = false;



  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/categories')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/products');
        break;
      case 2:
        context.go('/categories');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final int selectedIndex = _calculateSelectedIndex(context);
    
    // Mobil görünüm (Alt Navigasyon)
    if (!isDesktop) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        bottomNavigationBar: BottomNavigationBar(
           currentIndex: selectedIndex,
           onTap: _onItemTapped,
           selectedItemColor: const Color(0xFFFF5722),
           unselectedItemColor: Colors.grey,
           showUnselectedLabels: true,
           backgroundColor: theme.cardColor,
           type: BottomNavigationBarType.fixed,
           items: const [
             BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Panel'),
             BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Ürünler'),
             BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Kategori'),
             BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ayarlar'),
           ],
        ),
        body: widget.child,
      );
    }

    // Masaüstü görünüm (Overlay Hover Sidebar)
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Ana İçerik (Soldan 72px sabit boşluk)
          Positioned(
            left: 72, 
            top: 0,
            bottom: 0,
            right: 0,
            child: widget.child,
          ),
          
          // 2. Arka Plan Karartma (Sadece menü açıkken görünür)
          if (_isRailExtended)
            Positioned(
              left: 72, 
              top: 0,
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => setState(() => _isRailExtended = false),
                child: Container(
                  color: Colors.black.withOpacity(0.3), // Hafif karartma
                ),
              ),
            ),

          // 3. Hover ile Açılan Animasyonlu Yan Menü
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left: 0,
            top: 0,
            bottom: 0,
            width: _isRailExtended ? 250 : 72,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isRailExtended = true),
              onExit: (_) => setState(() => _isRailExtended = false),
              child: Material(
                elevation: 8,
                color: theme.cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24), // Fixed top spacing
                    // Logo veya Başlık Alanı (Opsiyonel)
                    if (_isRailExtended)
                       Padding(
                         padding: const EdgeInsets.only(bottom: 20, left: 24),
                         child: Text(
                           "QR MENU ADMIN",
                           style: theme.textTheme.titleMedium?.copyWith(
                             fontWeight: FontWeight.bold, 
                             letterSpacing: 1.2
                           ),
                         ),
                       ),
                    
                    // Fixed Column instead of ListView to prevent jumps
                    Column(
                      children: [
                        _buildNavItem(icon: Icons.dashboard, label: 'Panel', index: 0, selectedIndex: selectedIndex),
                        _buildNavItem(icon: Icons.list_alt, label: 'Ürünler', index: 1, selectedIndex: selectedIndex),
                        _buildNavItem(icon: Icons.category, label: 'Kategoriler', index: 2, selectedIndex: selectedIndex),
                        _buildNavItem(icon: Icons.settings, label: 'Ayarlar', index: 3, selectedIndex: selectedIndex),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index, required int selectedIndex}) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFFFF5722); // Keep accent color constant for now
    final iconColor = isSelected ? primaryColor : theme.iconTheme.color ?? Colors.grey[700];
    final textColor = isSelected ? primaryColor : theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return InkWell(
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        height: 56, // Fixed height prevents vertical jumping
        child: Row(
          children: [
            const SizedBox(width: 24), // STRICT left padding
            Icon(icon, color: iconColor), // Pinned icon
            const SizedBox(width: 20), // STRICT spacing
            // Text area always present, just faded/clipped when collapsed
            Expanded(
              child: ClipRect(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _isRailExtended ? 1.0 : 0.0,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    softWrap: false, // Prevents wrapping during animation
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

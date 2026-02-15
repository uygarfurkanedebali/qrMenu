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

  final Color _bgColor = const Color(0xFFF8F9FA);
  final Color _primaryColor = const Color(0xFFFF5722);

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
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final int selectedIndex = _calculateSelectedIndex(context);
    
    // Mobil görünüm (Alt Navigasyon)
    if (!isDesktop) {
      return Scaffold(
        backgroundColor: _bgColor,
        bottomNavigationBar: BottomNavigationBar(
           currentIndex: selectedIndex,
           onTap: _onItemTapped,
           selectedItemColor: _primaryColor,
           unselectedItemColor: Colors.grey,
           showUnselectedLabels: true,
           backgroundColor: Colors.white,
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
      backgroundColor: _bgColor,
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
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Logo veya Başlık Alanı (Opsiyonel)
                    if (_isRailExtended)
                       const Padding(
                         padding: EdgeInsets.only(bottom: 20),
                         child: Text(
                           "QR MENU ADMIN",
                           style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                         ),
                       ),
                    
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildNavItem(icon: Icons.dashboard, label: 'Panel', index: 0, selectedIndex: selectedIndex),
                          _buildNavItem(icon: Icons.list_alt, label: 'Ürünler', index: 1, selectedIndex: selectedIndex),
                          _buildNavItem(icon: Icons.category, label: 'Kategoriler', index: 2, selectedIndex: selectedIndex),
                          _buildNavItem(icon: Icons.settings, label: 'Ayarlar', index: 3, selectedIndex: selectedIndex),
                        ],
                      ),
                    ),
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
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: isSelected ? _primaryColor.withOpacity(0.05) : null,
        child: Row(
          children: [
            Icon(icon, color: isSelected ? _primaryColor : Colors.grey[700], size: 24),
            const SizedBox(width: 20),
            if (_isRailExtended)
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? _primaryColor : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

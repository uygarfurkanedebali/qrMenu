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
    bool isDesktop = MediaQuery.of(context).size.width >= 800;
    final int selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
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
      body: Row(
        children: [
          if (isDesktop)
            MouseRegion(
              onEnter: (_) => setState(() => _isRailExtended = true),
              onExit: (_) => setState(() => _isRailExtended = false),
              child: NavigationRail(
                extended: _isRailExtended,
                minExtendedWidth: 200,
                backgroundColor: Colors.white,
                selectedIndex: selectedIndex,
                onDestinationSelected: _onItemTapped,
                selectedIconTheme: IconThemeData(color: _primaryColor),
                selectedLabelTextStyle: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard),
                    label: Text('Panel'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.list_alt),
                    label: Text('Ürünler'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.category),
                    label: Text('Kategoriler'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings),
                    label: Text('Ayarlar'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

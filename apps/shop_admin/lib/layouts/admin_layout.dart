import 'package:flutter/material.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;

  const AdminLayout({Key? key, required this.child}) : super(key: key);

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  bool _isRailExtended = false;

  final Color _bgColor = const Color(0xFFF8F9FA);
  final Color _primaryColor = const Color(0xFFFF5722);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigation logic will be injected here later (e.g., GoRouter or Navigator)
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
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
                selectedIndex: _selectedIndex,
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

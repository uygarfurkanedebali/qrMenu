
import 'package:flutter/material.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;

  const AdminLayout({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // V2: Removed Sidebar and BottomNavBar.
    // The layout is now handled by individual screens (Dashboard, Products, etc.)
    // This wrapper is kept for ShellRoute compatibility and potential future global overlays.
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: child,
    );
  }
}

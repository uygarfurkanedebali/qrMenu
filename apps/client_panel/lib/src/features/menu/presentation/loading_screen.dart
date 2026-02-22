/// Loading Screen
/// 
/// Displayed while the tenant data is being fetched.
library;

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

/// Screen shown while loading tenant data
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo/loading indicator
            const QVitrinLoader(size: 80),
            const SizedBox(height: 24),
            Text(
              'Loading menu...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Landing Page Entry Point
///
/// Refactored to use the shared router from Shop Admin.
/// This ensures a unified entry point and consistent behavior.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shop_admin/src/routing/app_router.dart'; // Import from shop_admin

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase init error (landing): $e');
  }
  
  runApp(
    const ProviderScope(
      child: LandingApp(),
    ),
  );
}

class LandingApp extends ConsumerWidget {
  const LandingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Connect to the Router Provider from Shop Admin
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'QR Menu Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

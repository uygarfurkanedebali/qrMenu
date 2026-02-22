/// Landing Page Entry Point
///
/// Refactored to use the shared router from Shop Admin.
/// This ensures a unified entry point and consistent behavior.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'src/routing/app_router.dart'; // Local Landing Page Router

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
    // Connect to the generic Router Provider from Landing Router
    final router = ref.watch(routerProvider);

    return ValueListenableBuilder<bool>(
      valueListenable: isDesktopInputNotifier,
      builder: (context, isDesktop, child) {
        return MaterialApp.router(
          title: 'QR Menu Platform',
          debugShowCheckedModeBanner: false,
          scrollBehavior: const CustomSmoothScrollBehavior().copyWith(
            physics: isDesktop ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
          ),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          routerConfig: router,
        );
      },
    );
  }
}

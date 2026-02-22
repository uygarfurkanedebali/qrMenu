/// QR-Infinity Client Panel
/// 
/// Customer-facing PWA for viewing restaurant menus.
/// Resolves tenant from URL (subdomain or path) and displays themed menu.
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_core/shared_core.dart';

import 'src/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Remove the # from web URLs
  usePathUrlStrategy();
  
  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }
  
  runApp(
    const ProviderScope(
      child: ClientPanelApp(),
    ),
  );
}

/// Root widget for the Client Panel application
class ClientPanelApp extends ConsumerWidget {
  const ClientPanelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return ValueListenableBuilder<bool>(
      valueListenable: isDesktopInputNotifier,
      builder: (context, isDesktop, child) {
        return MaterialApp.router(
          title: 'QR-Infinity Menu',
          debugShowCheckedModeBanner: false,
          
          // Global Smooth Scrolling + Physics override for mouse wheels
          scrollBehavior: const CustomSmoothScrollBehavior().copyWith(
            physics: isDesktop ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
          ),
          
          // Localizations (Required for Material widgets)
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('tr'),
          ],
          
          // Default theme (overridden by tenant theme in MenuScreen)
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
            useMaterial3: true,
          ),
          
          // GoRouter configuration
          routerConfig: router,
        );
      },
    );
  }
}

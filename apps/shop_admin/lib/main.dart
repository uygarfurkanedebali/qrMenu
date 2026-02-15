/// QR-Infinity Shop Admin
/// v1.0.2
/// Dashboard for shop owners to manage their menu.
/// RBAC: Only users with role='shop_owner' are allowed.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_core/shared_core.dart';
import 'src/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }

  // 2. [KRİTİK HAMLE] VARSA ESKİ OTURUMU ÖLDÜR
  // Bu satır, sayfa her yüklendiğinde hafızadaki token'ı siler ve Login'e zorlar.
  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) {
    debugPrint(
      '🧹 [STARTUP] Eski oturum tespit edildi, güvenlik gereği siliniyor...',
    );
    await Supabase.instance.client.auth.signOut();
  }

  runApp(const ProviderScope(child: ShopAdminApp()));
}

class ShopAdminApp extends ConsumerWidget {
  const ShopAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Dark theme — Slate palette with Indigo accent
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF6366F1), // Indigo
        secondary: const Color(0xFF818CF8), // Indigo lighter
        surface: const Color(0xFF1E293B), // Slate 800
        error: Colors.red.shade400,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF94A3B8),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
      ),

      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Color(0xFF1E293B),
        selectedIconTheme: IconThemeData(color: Color(0xFF6366F1)),
        unselectedIconTheme: IconThemeData(color: Color(0xFF64748B)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF334155),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF334155),
        labelStyle: const TextStyle(color: Colors.white70),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      useMaterial3: true,
    );

    return MaterialApp.router(
      title: 'Shop Admin Panel',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('tr')],

      theme: darkTheme,
      routerConfig: router,
    );
  }
}

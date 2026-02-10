/// QR-Infinity System Admin
/// 
/// Super-admin panel for managing all tenants.
/// RBAC: Only users with role='admin' in profiles table are allowed.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_core/shared_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/features/tenants/presentation/create_tenant_screen.dart';
import 'src/features/tenants/presentation/tenants_list_screen.dart';
import 'src/features/auth/presentation/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }
  
  runApp(const SystemAdminApp());
}

class SystemAdminApp extends StatelessWidget {
  const SystemAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dark, serious theme for System Admin
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: Colors.red.shade400,
        secondary: Colors.red.shade300,
        surface: const Color(0xFF1A1A2E),
        error: Colors.red.shade300,
      ),
      scaffoldBackgroundColor: const Color(0xFF16213E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F3460),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1A1A2E),
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F3460).withAlpha(128),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'System Admin Panel',
      debugShowCheckedModeBanner: false,
      
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
      ],
      
      theme: darkTheme,
      home: const _AdminAuthGate(),
    );
  }
}

/// Auth gate that checks BOTH authentication AND admin role.
/// 
/// Flow:
/// 1. Check if user is logged in
/// 2. If yes → query profiles table for role
/// 3. If role == 'admin' → show SystemAdminHome
/// 4. If role != 'admin' → signOut() + show LoginScreen with error
/// 5. If not logged in → show LoginScreen
class _AdminAuthGate extends StatefulWidget {
  const _AdminAuthGate();

  @override
  State<_AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<_AdminAuthGate> {
  bool _isCheckingRole = true;
  bool _isAdmin = false;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _checkCurrentSession();

    // Listen for auth state changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _checkRole();
      } else if (event == AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _isCheckingRole = false;
          });
        }
      }
    });
  }

  Future<void> _checkCurrentSession() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      await _checkRole();
    } else {
      if (mounted) {
        setState(() => _isCheckingRole = false);
      }
    }
  }

  Future<void> _checkRole() async {
    if (mounted) {
      setState(() {
        _isCheckingRole = true;
        _authError = null;
      });
    }

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isCheckingRole = false);
        return;
      }

      // Query profiles table for role
      final response = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // No profile found — not an admin
        await SupabaseService.client.auth.signOut();
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _isCheckingRole = false;
            _authError = 'Profil bulunamadı. Yetkisiz erişim.';
          });
        }
        return;
      }

      final profile = UserProfile.fromJson(response);

      if (profile.isAdmin) {
        if (mounted) {
          setState(() {
            _isAdmin = true;
            _isCheckingRole = false;
          });
        }
      } else {
        // NOT admin → sign out immediately
        await SupabaseService.client.auth.signOut();
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _isCheckingRole = false;
            _authError = '⛔ Yetkisiz Erişim! Bu panel yalnızca Admin kullanıcılar içindir.\n'
                'Hesabınızın rolü: "${profile.role.displayName}"';
          });
        }
      }
    } catch (e) {
      // On error, sign out for safety
      try {
        await SupabaseService.client.auth.signOut();
      } catch (_) {}
      
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isCheckingRole = false;
          _authError = 'Rol doğrulama hatası: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingRole) {
      return Scaffold(
        backgroundColor: const Color(0xFF16213E),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Yetki kontrol ediliyor...',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    if (_isAdmin) {
      return const SystemAdminHome();
    }

    return AdminLoginScreen(
      errorMessage: _authError,
      onLoginSuccess: () => _checkRole(),
    );
  }
}

class SystemAdminHome extends StatelessWidget {
  const SystemAdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.client.auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield, size: 24),
            SizedBox(width: 8),
            Text('System Admin'),
          ],
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                avatar: const Icon(Icons.verified_user, size: 16, color: Colors.green),
                label: Text(user.email ?? '', style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.green.withAlpha(30),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Sign Out',
            onPressed: () async {
              await SupabaseService.client.auth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings, size: 80, color: Colors.red.shade400),
              const SizedBox(height: 16),
              const Text(
                'System Admin Panel',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              
              // Supabase connection status
              FutureBuilder(
                future: Future.value(Env.isConfigured),
                builder: (context, snapshot) {
                  final configured = snapshot.data ?? false;
                  return Chip(
                    avatar: Icon(
                      configured ? Icons.check_circle : Icons.error,
                      color: configured ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    label: Text(
                      configured ? 'Supabase Connected' : 'Supabase Not Configured',
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Create Tenant Button
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateTenantScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_business),
                label: const Text('Create New Tenant'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // View Tenants Button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TenantsListScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text('View All Tenants'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

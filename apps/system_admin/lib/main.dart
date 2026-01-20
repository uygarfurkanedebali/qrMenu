/// QR-Infinity System Admin
/// 
/// Super-admin panel for managing all tenants.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_core/shared_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/features/tenants/presentation/create_tenant_screen.dart';
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
      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<AuthState>(
        stream: AuthService().onAuthStateChange,
        builder: (context, snapshot) {
          // If waiting for initial connection
          if (snapshot.connectionState == ConnectionState.waiting) {
             // Check if we have a current session already
             if (AuthService().currentUser != null) {
               return const SystemAdminHome();
             }
             return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          
          final session = snapshot.data?.session;
          // Also check explicit current user if snapshot is not emitting yet but we have storage
          if (session != null || AuthService().currentUser != null) {
            return const SystemAdminHome();
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}

class SystemAdminHome extends StatelessWidget {
  const SystemAdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Admin'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 80),
              const SizedBox(height: 16),
              const Text(
                'System Admin Panel',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
              
              // View Tenants Button (Placeholder)
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tenant list coming soon')),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text('View All Tenants'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

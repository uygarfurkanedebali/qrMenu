import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }
  runApp(const LandingApp());
}

class LandingApp extends StatelessWidget {
  const LandingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Menu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LandingHome(),
    );
  }
}

class LandingHome extends StatefulWidget {
  const LandingHome({super.key});

  @override
  State<LandingHome> createState() => _LandingHomeState();
}

class _LandingHomeState extends State<LandingHome> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleAuthSuccess() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    try {
      // Check if they own a tenant
      final tenant = await TenantRepository().getTenantByOwnerEmail(user.email!);
      
      if (mounted) {
        if (tenant != null) {
          // Redirect to Shop Admin
          // Use window.location.href to perform a full page reload/redirect
          html.window.location.href = '/${tenant.slug}/shopadmin';
        } else {
          // No shop found.
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Logged in! No shop found for this account. Please contact support.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error fetching shop: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isLogin) {
        await AuthService().signIn(email: email, password: password);
      } else {
        await AuthService().signUp(email: email, password: password);
      }
      
      // Handle success and redirect
      await _handleAuthSuccess();

    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Menu Platform'),
        actions: [
          if (AuthService().currentUser != null)
             IconButton(
               icon: const Icon(Icons.logout),
               onPressed: () async {
                 await AuthService().signOut();
                 setState(() {});
               },
             )
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               if (AuthService().currentUser != null) ...[
                 const Icon(Icons.check_circle, size: 64, color: Colors.green),
                 const SizedBox(height: 16),
                 Text('Welcome to QR Menu Platform ${AuthService().currentUser?.email}'),
                 const SizedBox(height: 16),
                 FilledButton(
                   onPressed: () => _handleAuthSuccess(),
                   child: const Text('Go to Shop Admin')
                 )
               ] else ...[
                 Text(
                   _isLogin ? 'Login to QR Menu Platform' : 'Register to QR Menu Platform',
                   style: Theme.of(context).textTheme.headlineMedium,
                 ),
                 const SizedBox(height: 24),
                 if (_errorMessage != null)
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                 TextField(
                   controller: _emailController,
                   decoration: const InputDecoration(labelText: 'Email'),
                 ),
                 const SizedBox(height: 16),
                 TextField(
                   controller: _passwordController,
                   decoration: const InputDecoration(labelText: 'Password'),
                   obscureText: true,
                 ),
                 const SizedBox(height: 24),
                 FilledButton(
                   onPressed: _isLoading ? null : _submit,
                   child: _isLoading ? const CircularProgressIndicator() : Text(_isLogin ? 'Sign In' : 'Sign Up'),
                 ),
                 TextButton(
                   onPressed: () => setState(() => _isLogin = !_isLogin),
                   child: Text(_isLogin ? 'Create Account' : 'Have an account? Login'),
                 ),
               ]
            ],
          ),
        ),
      ),
    );
  }
}

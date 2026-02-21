import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;

class GlobalLoginScreen extends StatefulWidget {
  const GlobalLoginScreen({super.key});

  @override
  State<GlobalLoginScreen> createState() => _GlobalLoginScreenState();
}

class _GlobalLoginScreenState extends State<GlobalLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Lütfen e-posta ve şifrenizi girin.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        await _routeUser(response.user!);
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = 'Giriş başarısız: E-posta veya şifre hatalı.');
    } catch (e) {
      setState(() => _errorMessage = 'Beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: html.window.location.origin, // Returns back to landing page root, where auth state will be checked
      );
      // OAuth redirect handles the rest. 
    } catch (e) {
      setState(() => _errorMessage = 'Google ile giriş başlatılamadı.');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _routeUser(User user) async {
    // Check if role is admin
    final appMetadata = user.appMetadata;
    final userMetadata = user.userMetadata;
    
    // Some implementations keep role in user_metadata, some in app_metadata
    final role = appMetadata['role'] ?? userMetadata?['role'];
    
    if (role == 'admin' || role == 'system_admin') {
      html.window.location.href = '/root';
      return;
    }

    // Query tenant
    try {
      final res = await Supabase.instance.client
          .from('tenants')
          .select('slug')
          .eq('owner_id', user.id)
          .maybeSingle();

      if (res != null && res['slug'] != null) {
        final slug = res['slug'];
        html.window.location.href = '/$slug/shopadmin';
      } else {
        // No tenant found, send them to apply screen
        context.go('/apply');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Dükkan bilgileri alınırken hata oluştu.');
    }
  }

  @override
  void initState() {
    super.initState();
    // Check if already logged in (e.g. returning from Google OAuth)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session?.user != null) {
        _routeUser(session!.user!);
      }

      // Listen for auth changes
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn && data.session?.user != null) {
          _routeUser(data.session!.user!);
        }
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _isLoading ? null : () => context.go('/'),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(color: Colors.grey.shade50),
          ),
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/background/pattern.svg',
              fit: BoxFit.cover,
            ),
          ),
          
          // Form glassmorphism container
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 380,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(204), // 0.8
                      border: Border.all(color: Colors.white.withAlpha(255)), // 1.0
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13), // 0.05
                          blurRadius: 30,
                          spreadRadius: -5,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.rocket_launch, size: 48, color: Colors.blueAccent),
                        const SizedBox(height: 16),
                        const Text(
                          'Mağazaya Giriş',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withAlpha(128)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        TextField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-posta',
                            filled: true,
                            fillColor: Colors.white70,
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Şifre',
                            filled: true,
                            fillColor: Colors.white70,
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Giriş Yap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('VEYA', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                        ),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleGoogleLogin,
                            icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                            label: const Text('Google ile Giriş Yap', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: _isLoading ? null : () => context.go('/apply'),
                          child: const Text('Hesabınız yok mu? Aramıza Katılın', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

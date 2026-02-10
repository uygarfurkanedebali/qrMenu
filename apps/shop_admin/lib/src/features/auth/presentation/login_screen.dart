// Shop Admin Login Screen — SIMPLIFIED WITH FORCED NAVIGATION
// Direct navigation to /products after successful login

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../routing/app_router.dart';
import '../application/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    print('╔═══════════════════════════════════════════════════════╗');
    print('║ 👆 [LOGIN UI] Submit Button PRESSED                   ║');
    print('║ Time: ${DateTime.now().toIso8601String()}');
    print('╚═══════════════════════════════════════════════════════╝');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ [LOGIN UI] Form validation FAILED');
      return;
    }

    print('✅ [LOGIN UI] Form validation PASSED');
    setState(() {
      _isLoading = true;
      _error = null;
    });
    print('⏳ [LOGIN UI] Loading state SET to true');

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      print('═══════════════════════════════════════════════════════');
      print('🚀 [LOGIN UI] Calling ShopAuthService.signIn()...');
      print('   Email: $email');
      print('═══════════════════════════════════════════════════════');
      
      // Call simplified auth service (includes state propagation delay)
      final tenant = await ShopAuthService.signIn(
        email: email,
        password: password,
      );

      print('═══════════════════════════════════════════════════════');
      print('✅ [LOGIN UI] ShopAuthService.signIn() COMPLETED');
      print('   Tenant: ${tenant.name} (${tenant.slug})');
      print('═══════════════════════════════════════════════════════');

      // CRITICAL: Check if widget is still mounted after async
      if (!mounted) {
        print('⚠️  [LOGIN UI] Widget DISPOSED during signIn - STOPPING execution');
        print('   This is normal if router already navigated away');
        return;
      }

      print('✅ [LOGIN UI] Widget still MOUNTED - proceeding with state updates');
      
      // Store tenant in provider
      print('📝 [LOGIN UI] Setting currentTenantProvider state...');
      ref.read(currentTenantProvider.notifier).state = tenant;
      
      print('📝 [LOGIN UI] Setting roleVerifiedProvider to TRUE...');
      ref.read(roleVerifiedProvider.notifier).state = true;
      
      print('🔄 [LOGIN UI] State updated, waiting 100ms for router refresh...');
      
      // Give router a moment to process the auth state change
      await Future.delayed(const Duration(milliseconds: 100));
      
      // CRITICAL: Check mounted again after second async
      if (!mounted) {
        print('⚠️  [LOGIN UI] Widget DISPOSED after delay - STOPPING execution');
        print('   Router likely already handled navigation');
        return;
      }
      
      print('🧭 [LOGIN UI] Calling context.go(\'/products\')...');
      
      // Navigation - router should now see authenticated state
      context.go('/products');
      print('✅ [LOGIN UI] Navigation triggered to /products!');
      print('   Waiting for router redirect logic to run...');
      
    } catch (e) {
      print('═══════════════════════════════════════════════════════');
      print('❌ [LOGIN UI] Exception caught in _login()');
      print('   Error type: ${e.runtimeType}');
      print('   Error message: $e');
      print('═══════════════════════════════════════════════════════');
      
      // CRITICAL: Check mounted before using setState or showing errors
      if (!mounted) {
        print('⚠️  [LOGIN UI] Widget DISPOSED during error handling');
        return;
      }
      
      String errorMsg = e.toString();
      if (errorMsg.contains('Invalid login credentials')) {
        errorMsg = 'Geçersiz e-posta veya şifre.';
      } else if (errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.split('Exception:').last.trim();
      }
      
      print('📝 [LOGIN UI] Setting error state: $errorMsg');
      setState(() {
        _error = errorMsg;
        _isLoading = false;
      });

      // Show error in SnackBar
      if (mounted) {
        print('📢 [LOGIN UI] Showing error SnackBar');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      // CRITICAL: Check mounted before setState
      if (mounted) {
        print('🔄 [LOGIN UI] Finally block - setting loading to FALSE');
        setState(() {
          _isLoading = false;
        });
      } else {
        print('⚠️  [LOGIN UI] Finally block - widget disposed, skipping setState');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Store Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withAlpha(80),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.store, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'SHOP ADMIN',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dükkan Yönetim Paneli',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),

                // Error Banner
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withAlpha(80),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade700, width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade300, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade200, fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Login Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(100),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'E-posta',
                            labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'E-posta gerekli';
                            if (!v.contains('@')) return 'Geçersiz e-posta';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Şifre gerekli';
                            if (v.length < 6) return 'Şifre çok kısa';
                            return null;
                          },
                          onFieldSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 28),

                        FilledButton(
                          onPressed: _isLoading ? null : _login,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'GİRİŞ YAP',
                                  style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                const Text(
                  'Dükkan sahibi hesabınızla giriş yapın.',
                  style: TextStyle(color: Color(0xFF475569), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

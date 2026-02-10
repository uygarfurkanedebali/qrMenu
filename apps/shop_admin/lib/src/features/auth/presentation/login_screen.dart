// Shop Admin Login Screen — Dark Theme with Role Guard
// Authenticates shop owners and loads their tenant context
// Rejects non-shop_owner roles (admin, customer)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    // Clear any previous role errors
    ref.read(roleErrorProvider.notifier).state = null;

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Step 1: Sign in with Supabase
      await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        throw Exception('Giriş başarısız');
      }

      // Step 2: Check role from profiles
      final profileResponse = await SupabaseService.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (profileResponse == null) {
        await SupabaseService.client.auth.signOut();
        setState(() {
          _isLoading = false;
          _error = '⛔ Profil bulunamadı. Yetkisiz erişim.';
        });
        return;
      }

      final role = profileResponse['role'] as String?;

      if (role != 'shop_owner') {
        // NOT a shop owner → sign out immediately
        await SupabaseService.client.auth.signOut();
        setState(() {
          _isLoading = false;
          _error = '⛔ Yetkisiz Erişim!\n\n'
              'Bu panel yalnızca Dükkan Sahipleri içindir.\n'
              'Hesap rolünüz: "${role ?? 'tanımsız'}"';
        });
        return;
      }

      // Step 3: Role is shop_owner → fetch tenant
      final tenantState = await ShopAuthService.signInAndFetchTenant(
        email: email,
        password: password,
        skipAuth: true,  // Already signed in
      );

      if (tenantState == null) {
        throw Exception('Dükkan bilgisi yüklenemedi');
      }

      // Store tenant in provider
      ref.read(currentTenantProvider.notifier).state = tenantState;
      ref.read(roleVerifiedProvider.notifier).state = true;
      
      if (mounted) {
        context.go('/products');
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('Invalid login credentials')) {
        errorMsg = 'Geçersiz e-posta veya şifre.';
      } else if (errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.split('Exception:').last.trim();
      }
      setState(() {
        _error = errorMsg;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for role errors from router redirect
    final roleError = ref.watch(roleErrorProvider);
    final displayError = _error ?? roleError;

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
                if (displayError != null) ...[
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
                            displayError,
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

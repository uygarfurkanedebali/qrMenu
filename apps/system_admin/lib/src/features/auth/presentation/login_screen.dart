/// Admin Login Screen — Strict Mode
/// 
/// Dark, military-grade login for System Admin.
/// On login: checks profiles.role → if not admin → signOut immediately.
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class AdminLoginScreen extends StatefulWidget {
  final String? errorMessage;
  final VoidCallback onLoginSuccess;

  const AdminLoginScreen({
    super.key,
    this.errorMessage,
    required this.onLoginSuccess,
  });

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.errorMessage;
  }

  @override
  void didUpdateWidget(covariant AdminLoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorMessage != oldWidget.errorMessage && widget.errorMessage != null) {
      setState(() => _errorMessage = widget.errorMessage);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Sign in
      await SupabaseService.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        throw Exception('Giriş başarısız');
      }

      // Step 2: Check role from profiles
      final response = await SupabaseService.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        await SupabaseService.client.auth.signOut();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = '⛔ Profil bulunamadı. Yetkisiz erişim.';
          });
        }
        return;
      }

      final role = response['role'] as String?;

      if (role != 'admin') {
        // NOT admin → sign out immediately
        await SupabaseService.client.auth.signOut();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = '⛔ YETKİSİZ ERİŞİM!\n\n'
                'Bu panel yalnızca Admin kullanıcılar içindir.\n'
                'Hesap rolünüz: "${role ?? 'tanımsız'}"\n\n'
                'Eğer yönetici olmanız gerekiyorsa, sistem yöneticinizle iletişime geçin.';
          });
        }
        return;
      }

      // Step 3: Admin confirmed → notify parent
      if (mounted) {
        widget.onLoginSuccess();
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('Invalid login credentials')) {
        errorMsg = 'Geçersiz e-posta veya şifre.';
      } else if (errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.split('Exception:').last.trim();
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
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
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shield Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.red.shade900, Colors.red.shade600],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade900.withAlpha(100),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'SYSTEM ADMIN',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'KİMLİK DOĞRULAMA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade400,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 32),

                // Error Banner
                if (_errorMessage != null) ...[
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
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade200,
                              fontSize: 14,
                              height: 1.5,
                            ),
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
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A2A4E), width: 1),
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
                            labelStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
                          ),
                          keyboardType: TextInputType.emailAddress,
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
                            labelStyle: TextStyle(color: Colors.grey.shade500),
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
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Şifre gerekli';
                            return null;
                          },
                          onFieldSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: _isLoading ? null : _login,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'GİRİŞ YAP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                Text(
                  'Bu panel yetkili personel içindir.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

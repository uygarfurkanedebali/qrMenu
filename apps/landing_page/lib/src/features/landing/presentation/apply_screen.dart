import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

class ApplyScreen extends StatefulWidget {
  const ApplyScreen({super.key});

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  int _activeTabIndex = 0; // 0: Kayıt Ol, 1: Teklif Al
  
  // Registration Form
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regStoreNameController = TextEditingController();
  
  // Lead Form
  final _leadEmailController = TextEditingController();
  final _leadPhoneController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _leadSubmitted = false;

  @override
  void dispose() {
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regStoreNameController.dispose();
    _leadEmailController.dispose();
    _leadPhoneController.dispose();
    super.dispose();
  }

  String _generateSlug(String name) {
    final clean = name.toLowerCase().replaceAll('ı', 'i').replaceAll('ö', 'o').replaceAll('ü', 'u')
      .replaceAll('ş', 's').replaceAll('ğ', 'g').replaceAll('ç', 'c');
    return clean.replaceAll(RegExp(r'[^a-z0-9]'), '-').replaceAll(RegExp(r'-+'), '-').replaceAll(RegExp(r'^[-]+|[-]+$'), '');
  }

  Future<void> _handleRegister() async {
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text;
    final storeName = _regStoreNameController.text.trim();

    if (email.isEmpty || password.isEmpty || storeName.isEmpty) {
      setState(() => _errorMessage = 'Lütfen tüm alanları doldurun.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final slug = _generateSlug(storeName);
      
      // Attempt Sign Up
      final AuthResponse response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        // Create Tenant immediately (ignore conflict if RLS fails or fallback to ShopAdmin wizard later)
        try {
           await Supabase.instance.client.from('tenants').insert({
             'slug': slug,
             'name': storeName,
             'owner_id': user.id,
           });
        } catch (e) {
          debugPrint('Could not create tenant, perhaps RLS or duplicate slug: $e');
          // Proceed anyway to let shopadmin handle it if no tenant exists
        }
        
        // Try looking up the slug inserted
        final res = await Supabase.instance.client
            .from('tenants')
            .select('slug')
            .eq('owner_id', user.id)
            .maybeSingle();

        if (res != null) {
          html.window.location.assign('/${res['slug']}/shopadmin');
        } else {
          // If tenant insert failed, jump to system login to see if they can create it there
          context.go('/login');
        }
      } else {
        setState(() => _errorMessage = 'Kayıt işlemi şu an gerçekleştirilemiyor.');
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = 'Kayıt başarısız: ${e.message}');
    } catch (e) {
      debugPrint('Registration Error: $e');
      setState(() => _errorMessage = 'Beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: '${html.window.location.origin}/login', 
        // Redirecting to login handles the tenant linking and redirection logic there
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Google ile bağlantı başlatılamadı.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLeadSubmit() async {
    final email = _leadEmailController.text.trim();
    final phone = _leadPhoneController.text.trim();

    if (email.isEmpty || phone.isEmpty) {
      setState(() => _errorMessage = 'E-posta ve telefon gerekli.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch IP Address
      String ipAddress = 'unknown';
      try {
        final ipRes = await http.get(Uri.parse('https://api.ipify.org?format=json')).timeout(const Duration(seconds: 5));
        if (ipRes.statusCode == 200) {
          final data = jsonDecode(ipRes.body);
          ipAddress = data['ip'] ?? 'unknown';
        }
      } catch (e) {
        debugPrint('IP fetch failed: $e');
      }

      // 2. Fetch User Agent
      final userAgent = html.window.navigator.userAgent;

      // 3. Insert Lead
      await Supabase.instance.client.from('contact_leads').insert({
        'email': email,
        'phone': phone,
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'status': 'new',
      });

      setState(() {
        _leadSubmitted = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lead Insert Error: $e');
      setState(() {
        _errorMessage = 'Talebiniz alınırken bir hata oluştu. Lütfen tekrar deneyin.';
        _isLoading = false;
      });
    }
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
          // Background Color
          Positioned.fill(
              child: Container(color: Colors.grey.shade50),
          ),
          // Parallax Pattern
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/background/pattern.svg',
              fit: BoxFit.cover,
            ),
          ),

          // Central Glass Form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 420,
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
                        const Icon(Icons.star_rounded, size: 56, color: Colors.blueAccent),
                        const SizedBox(height: 16),
                        const Text(
                          'Aramıza Katıl',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Custom Segmented Control (Tabs)
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isLoading ? null : () => setState(() { _activeTabIndex = 0; _errorMessage = null; }),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _activeTabIndex == 0 ? Colors.blueAccent : Colors.transparent,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Kayıt Ol',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _activeTabIndex == 0 ? Colors.white : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isLoading ? null : () => setState(() { _activeTabIndex = 1; _errorMessage = null; _leadSubmitted = false; }),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _activeTabIndex == 1 ? Colors.blueAccent : Colors.transparent,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Teklif Al',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _activeTabIndex == 1 ? Colors.white : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

                        // Render Active Tab Content
                        if (_activeTabIndex == 0) 
                           _buildRegistrationTab()
                        else 
                           _buildLeadCaptureTab(),
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

  Widget _buildRegistrationTab() {
    return Column(
      children: [
        TextField(
          controller: _regStoreNameController,
          enabled: !_isLoading,
          decoration: const InputDecoration(
            labelText: 'İşletme Adı',
            filled: true,
            fillColor: Colors.white70,
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _regEmailController,
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
          controller: _regPasswordController,
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
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Kayıt Ol ve Başla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            onPressed: _isLoading ? null : _handleGoogleAuth,
            icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
            label: const Text('Google ile Kayıt Ol', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeadCaptureTab() {
    if (_leadSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Talebiniz Alındı!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ekibimiz en kısa sürede bıraktığınız iletişim bilgileri üzerinden sizinle iletişime geçecektir.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Ana Sayfaya Dön', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 24.0),
          child: Text(
            'Bize bilgilerinizi bırakın, sistemi sizin için kuralım ve menünüzü ücretsiz dijitalleştirelim.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.4, fontSize: 14),
          ),
        ),
        TextField(
          controller: _leadEmailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-posta Adresiniz',
            filled: true,
            fillColor: Colors.white70,
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _leadPhoneController,
          enabled: !_isLoading,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Telefon Numaranız',
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
            onPressed: _isLoading ? null : _handleLeadSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Beni Arayın', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

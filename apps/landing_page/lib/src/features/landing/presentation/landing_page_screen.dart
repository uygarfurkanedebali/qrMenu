import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// SaaS Landing Page
///
/// Features a parallax background, frosted glass global navbar,
/// and responsive feature sections. Displayed at the root domain.
class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    // Removed unused scroll listener
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Beneath the parallax
      extendBodyBehindAppBar: true,
      appBar: _buildGlobalNavbar(context),
      body: Stack(
        children: [
          // ─── HATA YAKALAYICI TEST KATMANI ───
          Positioned.fill(
            child: Image.asset(
              'assets/background/qvitrinpattern.jpg',
              repeat: ImageRepeat.repeat,
              errorBuilder: (context, error, stackTrace) {
                // HATA EKRANA BASILIYOR
                return Container(
                  color: Colors.white,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'RESİM YÜKLENEMEDİ!\n\nHata Detayı:\n$error',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          
          // ─── İÇERİK KATMANI ───
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildHeroSection(context),
                  _buildFeaturesSection(context),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Global Frosted Glass Navbar
  PreferredSizeWidget _buildGlobalNavbar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: Colors.white.withAlpha(51), // 0.2
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withAlpha(77))), // 0.3
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  // Logo Area
                  Image.asset(
                    'assets/logo/qvitrinfull.png',
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  // Actions
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black87,
                          backgroundColor: Colors.white.withAlpha(102), // 0.4
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        child: const Text('Giriş Yap'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: ElevatedButton(
                        onPressed: () => context.go('/apply'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent.withAlpha(204), // 0.8
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(color: Colors.white.withAlpha(128)), // 0.5
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        child: const Text('Ücretsiz Dene'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Hero Section (Transparent background, over the parallax)
  Widget _buildHeroSection(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(13), // 0.05
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withAlpha(51)), // 0.2
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Menünüzü Saniyeler İçinde\nDijitale Taşıyın',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 48,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Uygulama indirme derdi yok, matbaa maliyeti yok.\nTemassız, hızlı ve her an güncellenebilir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 18,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: ElevatedButton(
                      onPressed: () => context.go('/apply'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withAlpha(230), // 0.9
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(color: Colors.white.withAlpha(128)), // 0.5
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      child: const Text('Ücretsiz Menü Oluştur'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Features Section (Frosted glass wrapper, covers the parallax when scrolled)
  Widget _buildFeaturesSection(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(13), // 0.05
            border: Border(
              top: BorderSide(color: Colors.white.withAlpha(51)), // 0.2
              bottom: BorderSide(color: Colors.white.withAlpha(51)), // 0.2
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13), // 0.05
                blurRadius: 30,
                spreadRadius: -5,
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          child: Column(
            children: [
              const Text(
                'Nasıl Çalışır?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 60),
              const Wrap(
                spacing: 32,
                runSpacing: 32,
                alignment: WrapAlignment.center,
                children: [
                  _FeatureCard(
                    icon: Icons.app_registration,
                    title: '1. Kayıt Ol',
                    description: 'Saniyeler içinde hesabını aç ve işletmeni platforma ekle.',
                  ),
                  _FeatureCard(
                    icon: Icons.lunch_dining,
                    title: '2. Menünü Ekle',
                    description: 'Ürünleri, kategorileri, resimleri ve fiyatları dijitale taşı.',
                  ),
                  _FeatureCard(
                    icon: Icons.qr_code_2,
                    title: '3. Masaya Koy',
                    description: 'QR kodunu indir, masalara yerleştir ve anında sipariş al.',
                  ),
                ],
              ),
              const SizedBox(height: 80),
              // Neden Biz Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(13), // 0.05
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withAlpha(51)), // 0.2
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13), // 0.05
                      blurRadius: 30,
                      spreadRadius: -5,
                    )
                  ],
                ),
                child: const Column(
                  children: [
                    Text(
                      'Neden QR Infinity?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -1,
                      ),
                    ),
                    SizedBox(height: 48),
                    Row(
                      children: [
                        Expanded(
                          child: _BenefitItem(
                            icon: Icons.print_disabled,
                            title: 'Sıfır Baskı Maliyeti',
                            subtitle: 'Menü değiştirmek bedava.',
                          ),
                        ),
                        Expanded(
                          child: _BenefitItem(
                            icon: Icons.update,
                            title: 'Anında Fiyat Güncelleme',
                            subtitle: 'Zamları anında yansıt.',
                          ),
                        ),
                        Expanded(
                          child: _BenefitItem(
                            icon: Icons.clean_hands,
                            title: '%100 Hijyenik',
                            subtitle: 'Temassız güvenli deneyim.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Footer Section
  Widget _buildFooter(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          width: double.infinity,
          color: Colors.white.withAlpha(13), // 0.05
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo/qvitrinfull.png',
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                '© 2026 QVitrin. Tüm hakları saklıdır.',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13), // 0.05
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(51)), // 0.2
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8), // 0.03
            blurRadius: 15,
            spreadRadius: -2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withAlpha(26), // 0.1
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: Colors.blueAccent),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withAlpha(26), // 0.1
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blueAccent.withAlpha(77)), // 0.3
          ),
          child: Icon(icon, size: 32, color: Colors.blueAccent),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

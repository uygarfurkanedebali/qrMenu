import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _launchShopAdmin() async {
    final uri = Uri.parse('/shopadmin/login');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback if launchUrl fails
      // ignore: use_build_context_synchronously
      context.go('/shopadmin/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Beneath the parallax
      extendBodyBehindAppBar: true,
      appBar: _buildGlobalNavbar(context),
      body: Stack(
        children: [
          // ─── Layer 1: Parallax Background ───
          Positioned(
            top: -(_scrollOffset * 0.2),
            bottom: -100 + (_scrollOffset * 0.2), // Buffer to prevent clipping at bottom
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/landing_bg.jpg'),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
                child: Container(
                  // Dark gradient overlay for text readability
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(153), // 0.6
                        Colors.black.withAlpha(179), // 0.7
                      ],
                    ),
                  ),
                ),
            ),
          ),

          // ─── Layer 2: Foreground Content ───
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
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.white.withAlpha(26), // 0.1
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.center,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  // Logo Area
                  const Icon(Icons.rocket_launch, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'QR Infinity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  // Actions
                  TextButton(
                    onPressed: _launchShopAdmin,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    child: const Text('Giriş Yap'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _launchShopAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    child: const Text('Hemen Başla'),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Menünüzü Saniyeler İçinde\nDijitale Taşıyın',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Uygulama indirme derdi yok, matbaa maliyeti yok.\nTemassız, hızlı ve her an güncellenebilir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _launchShopAdmin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            child: const Text('Ücretsiz Menü Oluştur'),
          ),
        ],
      ),
    );
  }

  /// Features Section (Opaque white, covers the parallax when scrolled)
  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          const Text(
            'Nasıl Çalışır?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 60),
          Wrap(
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
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const Text(
                  'Neden QR Infinity?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 48),
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
    );
  }

  /// Footer Section
  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rocket_launch, color: Colors.white54, size: 24),
              SizedBox(width: 8),
              Text(
                'QR Infinity',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '© 2026 QR Infinity. Tüm hakları saklıdır.',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
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
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(13), // 0.05
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: Colors.black87),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey.shade600,
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
            color: Colors.blue.withAlpha(26), // 0.1
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: Colors.blue.shade700),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

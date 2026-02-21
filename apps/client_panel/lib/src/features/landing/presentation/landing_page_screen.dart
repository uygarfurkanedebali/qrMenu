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
          Positioned.fill(
            child: Transform.translate(
              // Move the background slower than the foreground (parallax effect)
              offset: Offset(0, _scrollOffset * 0.4),
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1556761175-5973dc0f32e7'),
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
                        Colors.black.withAlpha(102), // 0.4
                        Colors.black.withAlpha(179), // 0.7
                      ],
                    ),
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
                    onPressed: () {},
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
            'Mekanınızı\nDijitale Taşıyın',
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
            'Modern restoran ve kafeler için saniyeler içinde zengin içerikli,\nhızlı ve temaya uygun dijital menüler oluşturun.',
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
            onPressed: () {},
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
            'Neden Bizi Seçmelisiniz?',
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
                icon: Icons.qr_code_scanner,
                title: 'Modern Menü',
                description: 'Karanlık ve aydınlık temalı, tamamen işletmenize özel tasarlanmış modern arayüzler.',
              ),
              _FeatureCard(
                icon: Icons.bolt,
                title: 'Hızlı Sipariş',
                description: 'Müşterilerinizin beklemeden, saniyeler içinde telefonlarından detayları incelemesini sağlayın.',
              ),
              _FeatureCard(
                icon: Icons.dashboard_customize,
                title: 'Kolay Yönetim',
                description: 'Gelişmiş admin paneli ile ürünleri, kategorileri ve fiyatları saniyeler içinde güncelleyin.',
              ),
            ],
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

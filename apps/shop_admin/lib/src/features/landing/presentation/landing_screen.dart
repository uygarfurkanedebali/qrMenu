import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:url_launcher/url_launcher.dart';

// Provider to fetch landing config
final landingPageConfigProvider = FutureProvider<LandingPageConfig>((ref) async {
  return LandingRepository().getLandingConfig();
});

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(landingPageConfigProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: configAsync.when(
        data: (config) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNavBar(context),
              _buildHero(context, config),
              _buildFeatures(context, config),
              _buildFooter(context, config),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading landing page: $err')),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_2, size: 32, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'QR-Infinity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          OutlinedButton(
            onPressed: () {
              context.push('/login');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
            ),
            child: const Text('Yönetim Paneli'),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, LandingPageConfig config) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            config.heroTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1.5,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              config.heroDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 48),
          FilledButton.icon(
            onPressed: () {
               // Placeholder action
            },
            icon: const Icon(Icons.rocket_launch),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            label: const Text('Hemen Başla'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures(BuildContext context, LandingPageConfig config) {
    if (config.features.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
           const Text(
            'Öne Çıkan Özellikler',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive Grid
              final isMobile = constraints.maxWidth < 600;
              final isTablet = constraints.maxWidth < 1000;
              
              int columns = isMobile ? 1 : isTablet ? 2 : 3;
              double spacing = 24.0;
              double itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                alignment: WrapAlignment.center,
                children: config.features.map((feature) {
                  return SizedBox(
                    width: itemWidth,
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _getIconData(feature.icon), 
                                color: Colors.blue,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              feature.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              feature.text,
                              style: TextStyle(
                                color: Colors.grey.shade600, 
                                height: 1.6,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, LandingPageConfig config) {
    return Container(
      color: const Color(0xFF111827),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.qr_code_2, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            'QR-Infinity',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          if (config.contactEmail != null)
            InkWell(
              onTap: () async {
                 final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: config.contactEmail!,
                  );
                  if (await canLaunchUrl(emailLaunchUri)) {
                    await launchUrl(emailLaunchUri);
                  }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.email_outlined, color: Colors.white70, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      config.contactEmail!,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 60),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 32),
          Text(
            '© ${DateTime.now().year} QR-Infinity. All rights reserved.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'speed': return Icons.speed;
      case 'security': return Icons.security;
      case 'design': return Icons.brush;
      case 'analytics': return Icons.analytics;
      case 'mobile': return Icons.smartphone;
      case 'cloud': return Icons.cloud_queue;
      case 'support': return Icons.headset_mic;
      default: return Icons.check_circle_outline;
    }
  }
}

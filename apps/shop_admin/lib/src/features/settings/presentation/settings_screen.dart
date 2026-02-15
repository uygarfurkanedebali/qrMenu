/// Shop Settings Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_core/shared_core.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/application/auth_provider.dart';
import '../application/settings_provider.dart';
import '../../products/data/mock_storage_service.dart';
import 'components/design_settings_section.dart';

const _presetColors = [
  '#FF5722', '#E91E63', '#9C27B0', '#3F51B5', '#2196F3',
  '#009688', '#4CAF50', '#FF9800', '#795548', '#607D8B',
];

const _fontFamilies = ['Roboto', 'Lato', 'Montserrat', 'Open Sans', 'Poppins', 'Inter', 'Nunito', 'Raleway'];
const _currencies = ['₺', '\$', '€', '£', '¥'];

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _colorController;
  late TextEditingController _phoneController;
  late TextEditingController _instagramController;
  late TextEditingController _wifiNameController;
  late TextEditingController _wifiPasswordController;

  String _selectedFont = 'Roboto';
  String _selectedCurrency = '₺';
  String? _bannerUrl;
  
  // Design Settings
  String _layoutMode = 'grid';
  String _designFontFamily = 'Inter';
  bool _enableTexture = false;

  bool _isUploadingBanner = false;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _colorController = TextEditingController();
    _phoneController = TextEditingController();
    _instagramController = TextEditingController();
    _wifiNameController = TextEditingController();
    _wifiPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _colorController.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    _wifiNameController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  void _populateForm(Tenant tenant) {
    if (_initialized) return;
    _initialized = true;

    _colorController.text = tenant.primaryColor;
    _phoneController.text = tenant.phoneNumber ?? '';
    _instagramController.text = tenant.instagramHandle ?? '';
    _wifiNameController.text = tenant.wifiName ?? '';
    _wifiPasswordController.text = tenant.wifiPassword ?? '';
    _selectedFont = tenant.fontFamily;
    _selectedCurrency = tenant.currencySymbol;
    _bannerUrl = tenant.bannerUrl;

    final designConfig = tenant.designConfig;
    _layoutMode = designConfig['layout'] as String? ?? 'grid';
    _designFontFamily = designConfig['font'] as String? ?? 'Inter';
    _enableTexture = designConfig['texture'] as bool? ?? false;
  }

  Future<void> _uploadBanner() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploadingBanner = true);

    try {
      final service = ref.read(storageServiceProvider);
      final url = await service.uploadTenantBanner(image);
      
      if (mounted) {
        setState(() {
          _bannerUrl = url;
          _isUploadingBanner = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Afiş yüklendi! Kaydetmeyi unutmayın.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingBanner = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yükleme hatası: $e')),
        );
      }
    }
  }

  Color _parseHexColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}
    return const Color(0xFFFF5722);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final tenant = ref.read(currentTenantProvider);
    if (tenant == null) return;

    setState(() => _isSaving = true);

    try {
      await saveSettings(
        ref: ref,
        tenantId: tenant.id,
        updates: {
          'primary_color': _colorController.text.trim(),
          'banner_url': _bannerUrl,
          'font_family': _selectedFont,
          'currency_symbol': _selectedCurrency,
          'phone_number': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          'instagram_handle': _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
          'wifi_name': _wifiNameController.text.trim().isEmpty ? null : _wifiNameController.text.trim(),
          'wifi_password': _wifiPasswordController.text.trim().isEmpty ? null : _wifiPasswordController.text.trim(),
          'design_config': {
            'layout': _layoutMode,
            'font': _designFontFamily,
            'texture': _enableTexture,
          },
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Ayarlar başarıyla kaydedildi!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = ref.watch(currentTenantProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (tenant == null) return const Scaffold(body: Center(child: Text('Giriş yapın')));

    _populateForm(tenant);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dükkan Ayarları'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 18),
              label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Section 1: Görünüm
            _SectionHeader(icon: Icons.palette, title: 'Görünüm', subtitle: 'Marka rengi ve afiş'),
            const SizedBox(height: 12),
            
            // Banner & Color Cards...
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _uploadBanner,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    image: _bannerUrl != null
                        ? DecorationImage(image: NetworkImage(_bannerUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: Center(
                    child: _isUploadingBanner
                        ? const CircularProgressIndicator()
                        : Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Renk Seçimi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(labelText: 'Hex Renk Kodu', prefixIcon: Icon(Icons.colorize)),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Section 2: Menü Tasarımı (NEW)
            _SectionHeader(icon: Icons.design_services, title: 'Menü Tasarımı', subtitle: 'Müşteri ekranı özelleştirme'),
            const SizedBox(height: 12),
            DesignSettingsSection(
              layoutMode: _layoutMode,
              fontFamily: _designFontFamily,
              enableTexture: _enableTexture,
              onLayoutChanged: (v) => setState(() => _layoutMode = v ?? 'grid'),
              onFontChanged: (v) => setState(() => _designFontFamily = v ?? 'Inter'),
              onTextureChanged: (v) => setState(() => _enableTexture = v),
            ),
            const SizedBox(height: 32),

            // Section 3: İletişim
            _SectionHeader(icon: Icons.phone, title: 'İletişim', subtitle: 'Telefon ve Instagram'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instagramController,
                      decoration: const InputDecoration(labelText: 'Instagram', prefixIcon: Icon(Icons.camera_alt)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Section 4: Müşteri Bilgileri
            _SectionHeader(icon: Icons.wifi, title: 'Wi-Fi', subtitle: 'Müşteriler için internet bilgisi'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(controller: _wifiNameController, decoration: const InputDecoration(labelText: 'Wi-Fi Adı', prefixIcon: Icon(Icons.wifi))),
                    const SizedBox(height: 16),
                    TextFormField(controller: _wifiPasswordController, decoration: const InputDecoration(labelText: 'Şifre', prefixIcon: Icon(Icons.lock))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.primaryColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(subtitle, style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
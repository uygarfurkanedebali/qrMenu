/// Shop Settings Screen (Refactored)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_core/shared_core.dart';

import '../../auth/application/auth_provider.dart';
import '../application/settings_provider.dart';
import '../../products/data/mock_storage_service.dart';
import 'components/design_settings_section.dart';
import '../../navigation/admin_menu_drawer.dart';

class ShopSettingsScreen extends ConsumerStatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  ConsumerState<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends ConsumerState<ShopSettingsScreen> {
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

  void _populateForm(dynamic tenant) {
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
                Text('Ayarlar kaydedildi!'),
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

    if (tenant == null) return const Scaffold(body: Center(child: Text('Giriş yapın')));

    _populateForm(tenant);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Off-white
      appBar: AppBar(
        title: const Text('Mekan Ayarları', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 18),
              label: Text(_isSaving ? 'Kaydediliyor' : 'Kaydet'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: const AdminMenuDrawer(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Section 1: Genel Bilgiler (Placeholder List as requested, but keeping functionality for real use)
            const Text('Genel Bilgiler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _SettingsTile(
                    label: 'Telefon',
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.phone_outlined, size: 20)),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _SettingsTile(
                    label: 'Instagram',
                    child: TextFormField(
                      controller: _instagramController,
                      decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.camera_alt_outlined, size: 20)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Section 2: Wi-Fi
            const Text('Kablosuz İnternet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                   _SettingsTile(
                    label: 'Wi-Fi Adı',
                    child: TextFormField(
                      controller: _wifiNameController,
                      decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.wifi, size: 20)),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _SettingsTile(
                    label: 'Şifre',
                    child: TextFormField(
                      controller: _wifiPasswordController,
                      obscureText: false,
                      decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.lock_outline, size: 20)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Section 3: Görünüm & Tasarım
            const Text('Görünüm ve Marka', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            
             // Banner Upload
             InkWell(
                onTap: _uploadBanner,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    image: _bannerUrl != null
                        ? DecorationImage(image: NetworkImage(_bannerUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _bannerUrl == null 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Afiş Yükle', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      )
                    : null,
                ),
             ),
             
             const SizedBox(height: 16),
             
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
              ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text('Marka Rengi (Hex)', style: TextStyle(fontWeight: FontWeight.w500)),
                   const SizedBox(height: 8),
                   TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(
                        hintText: '#FF5722',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                 ],
               ),
             ),
             
             const SizedBox(height: 16),
             // Design Config Section Reuse
             DesignSettingsSection(
                layoutMode: _layoutMode,
                fontFamily: _designFontFamily,
                enableTexture: _enableTexture,
                onLayoutChanged: (v) => setState(() => _layoutMode = v ?? 'grid'),
                onFontChanged: (v) => setState(() => _designFontFamily = v ?? 'Inter'),
                onTextureChanged: (v) => setState(() => _enableTexture = v),
              ),

             const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingsTile({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80, 
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
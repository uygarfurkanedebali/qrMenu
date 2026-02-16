/// Shop Settings Screen (Advanced Customization)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_core/shared_core.dart';

import '../../auth/application/auth_provider.dart';
import '../application/settings_provider.dart';
import '../../products/data/mock_storage_service.dart';
import '../../navigation/admin_menu_drawer.dart';

class ShopSettingsScreen extends ConsumerStatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  ConsumerState<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends ConsumerState<ShopSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _colorController;
  late TextEditingController _phoneController;
  late TextEditingController _instagramController;
  late TextEditingController _wifiNameController;
  late TextEditingController _wifiPasswordController;

  // State Variables
  String _selectedFont = 'Roboto';
  String _selectedLayout = 'modern_grid';
  String? _bannerUrl;
  bool _enablePaperTexture = false;
  
  bool _isUploadingBanner = false;
  bool _isSaving = false;
  bool _initialized = false;

  // Constants
  static const _fontOptions = ['Roboto', 'Inter', 'Lora', 'Open Sans', 'Montserrat', 'Playfair Display'];
  static const _layoutOptions = [
    {'id': 'modern_grid', 'label': 'Modern Grid', 'icon': Icons.grid_view},
    {'id': 'minimal_list', 'label': 'Paper List (Minimal)', 'icon': Icons.list_alt},
    {'id': 'tinder_cards', 'label': 'Tinder Cards', 'icon': Icons.swipe},
  ];
  static const _presetColors = [
    Color(0xFFFF5722), // Deep Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFF9C27B0), // Purple
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF000000), // Black
  ];

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

    _colorController.text = tenant.primaryColor ?? '#000000';
    _phoneController.text = tenant.phoneNumber ?? '';
    _instagramController.text = tenant.instagramHandle ?? '';
    _wifiNameController.text = tenant.wifiName ?? '';
    _wifiPasswordController.text = tenant.wifiPassword ?? '';
    _bannerUrl = tenant.bannerUrl;

    // Design Config
    final designConfig = tenant.designConfig ?? {};
    _selectedFont = designConfig['font_family'] as String? ?? 'Roboto';
    if (!_fontOptions.contains(_selectedFont)) _selectedFont = 'Roboto';
    
    _selectedLayout = designConfig['layout_mode'] as String? ?? 'modern_grid';
    _enablePaperTexture = designConfig['enable_paper_texture'] as bool? ?? false;
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
          const SnackBar(content: Text('Afiş yüklendi!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingBanner = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yükleme hatası: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final tenant = ref.read(currentTenantProvider);
    if (tenant == null) return;

    setState(() => _isSaving = true);

    try {
      final designConfig = {
        'font_family': _selectedFont,
        'layout_mode': _selectedLayout,
        'enable_paper_texture': _enablePaperTexture,
      };

      await saveSettings(
        ref: ref,
        tenantId: tenant.id,
        updates: {
          'primary_color': _colorController.text.trim(),
          'banner_url': _bannerUrl,
          'phone_number': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          'instagram_handle': _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
          'wifi_name': _wifiNameController.text.trim().isEmpty ? null : _wifiNameController.text.trim(),
          'wifi_password': _wifiPasswordController.text.trim().isEmpty ? null : _wifiPasswordController.text.trim(),
          'design_config': designConfig,
          // 'font_family': _selectedFont, // Sync legacy fields if needed
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
    if (tenant == null) return const Scaffold(body: Center(child: Text('Giriş yapın')));

    _populateForm(tenant);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 18),
              label: Text(_isSaving ? 'Kaydediliyor' : 'Kaydet'),
              style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
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
            // --- Section 1: Görünüm & Tasarım ---
            const _SectionTitle(title: 'Görünüm & Tasarım'),
            const SizedBox(height: 16),
            
            // Banner & Renk
            Container(
              decoration: _cardDecoration,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mekan Afişi', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _uploadBanner,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        image: _bannerUrl != null
                            ? DecorationImage(image: NetworkImage(_bannerUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: _bannerUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey.shade500),
                                const SizedBox(height: 8),
                                Text('Afiş Yükle', style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('Marka Rengi', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ..._presetColors.map((color) => 
                        GestureDetector(
                          onTap: () {
                             final hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                             setState(() => _colorController.text = hex);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                if (_colorController.text.toUpperCase().endsWith(color.value.toRadixString(16).substring(2).toUpperCase()))
                                  BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, spreadRadius: 2)
                              ]
                            ),
                          ),
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _colorController,
                     decoration: const InputDecoration(
                      hintText: '#000000',
                      labelText: 'Hex Kodu',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      prefixIcon: Icon(Icons.colorize, size: 20),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

             // Tipografi & Düzen
            Container(
              decoration: _cardDecoration,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tipografi', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedFont,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    items: _fontOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                    onChanged: (val) => setState(() => _selectedFont = val!),
                  ),
                  const SizedBox(height: 24),

                  const Text('Menü Düzeni', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedLayout,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    items: _layoutOptions.map((l) => DropdownMenuItem(
                      value: l['id'] as String, 
                      child: Row(children: [
                        Icon(l['icon'] as IconData, size: 18), 
                        const SizedBox(width: 8), 
                        Text(l['label'] as String)
                      ]),
                    )).toList(),
                    onChanged: (val) => setState(() {
                       _selectedLayout = val!;
                       if (_selectedLayout != 'minimal_list') _enablePaperTexture = false;
                    }),
                  ),
                  
                  // Paper Texture Option
                  if (_selectedLayout == 'minimal_list') ...[
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Kağıt Dokusu (Texture)', style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Arka plana kağıt efekti ekler'),
                      value: _enablePaperTexture,
                      activeColor: Colors.black,
                      onChanged: (val) => setState(() => _enablePaperTexture = val),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // --- Section 2: İletişim & İnternet ---
            const _SectionTitle(title: 'İletişim & İnternet'),
            const SizedBox(height: 16),
            
            Container(
              decoration: _cardDecoration,
              child: Column(
                children: [
                  _SettingsListTile(
                    label: 'Telefon',
                    icon: Icons.phone_outlined,
                    controller: _phoneController,
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsListTile(
                    label: 'Instagram',
                    icon: Icons.camera_alt_outlined,
                    controller: _instagramController,
                    prefixText: '@',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              decoration: _cardDecoration,
              child: Column(
                children: [
                  _SettingsListTile(
                    label: 'Wi-Fi Adı',
                    icon: Icons.wifi,
                    controller: _wifiNameController,
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsListTile(
                    label: 'Şifre',
                    icon: Icons.lock_outline,
                    controller: _wifiPasswordController,
                    isObscure: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade200),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 13, 
        fontWeight: FontWeight.bold, 
        color: Colors.grey.shade600,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _SettingsListTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool isObscure;
  final String? prefixText;

  const _SettingsListTile({
    required this.label,
    required this.icon,
    required this.controller,
    this.isObscure = false,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
      subtitle: TextFormField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          border: InputBorder.none,
          hintText: 'Belirtilmedi',
          prefixText: prefixText,
        ),
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }
}
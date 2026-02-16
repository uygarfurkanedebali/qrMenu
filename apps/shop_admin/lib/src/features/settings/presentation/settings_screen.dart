/// Shop Settings Screen — Advanced Design Engine
/// 
/// Granular font & color controls, layout selection, and contact info.
/// Uses Supabase `tenants` table `design_config` JSON column for design data.
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
  late TextEditingController _primaryColorCtrl;
  late TextEditingController _bgColorCtrl;
  late TextEditingController _headingColorCtrl;
  late TextEditingController _bodyColorCtrl;
  late TextEditingController _phoneController;
  late TextEditingController _instagramController;
  late TextEditingController _wifiNameController;
  late TextEditingController _wifiPasswordController;

  // State
  String _headingFont = 'Roboto';
  String _bodyFont = 'Roboto';
  String _selectedLayout = 'modern_grid';
  String? _bannerUrl;
  bool _enablePaperTexture = false;
  bool _isUploadingBanner = false;
  bool _isSaving = false;
  bool _initialized = false;

  // Constants
  static const _fontOptions = ['Roboto', 'Lora', 'Open Sans', 'Montserrat'];
  static const _layoutOptions = [
    {'id': 'modern_grid', 'label': 'Modern Grid', 'icon': Icons.grid_view},
    {'id': 'minimal_list', 'label': 'Paper List (Minimal)', 'icon': Icons.list_alt},
    {'id': 'tinder_cards', 'label': 'Tinder Cards', 'icon': Icons.swipe},
  ];

  // Preset Colors for each section
  static const _primaryPresets = [
    Color(0xFFFF5722), Color(0xFFE91E63), Color(0xFF2196F3), Color(0xFF4CAF50), Color(0xFF9C27B0),
  ];
  static const _bgPresets = [
    Color(0xFFFFFFFF), Color(0xFFF9FAFB), Color(0xFFFFF8E1), Color(0xFF263238), Color(0xFF1A1A1A),
  ];
  static const _headingTextPresets = [
    Color(0xFF000000), Color(0xFF212121), Color(0xFF37474F), Color(0xFFFFFFFF), Color(0xFFFF5722),
  ];
  static const _bodyTextPresets = [
    Color(0xFF424242), Color(0xFF616161), Color(0xFF37474F), Color(0xFFBDBDBD), Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    _primaryColorCtrl = TextEditingController();
    _bgColorCtrl = TextEditingController();
    _headingColorCtrl = TextEditingController();
    _bodyColorCtrl = TextEditingController();
    _phoneController = TextEditingController();
    _instagramController = TextEditingController();
    _wifiNameController = TextEditingController();
    _wifiPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _primaryColorCtrl.dispose();
    _bgColorCtrl.dispose();
    _headingColorCtrl.dispose();
    _bodyColorCtrl.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    _wifiNameController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  void _populateForm(dynamic tenant) {
    if (_initialized) return;
    _initialized = true;

    _primaryColorCtrl.text = tenant.primaryColor ?? '#FF5722';
    _phoneController.text = tenant.phoneNumber ?? '';
    _instagramController.text = tenant.instagramHandle ?? '';
    _wifiNameController.text = tenant.wifiName ?? '';
    _wifiPasswordController.text = tenant.wifiPassword ?? '';
    _bannerUrl = tenant.bannerUrl;

    final dc = tenant.designConfig ?? {};
    _headingFont = dc['heading_font'] as String? ?? dc['font_family'] as String? ?? 'Roboto';
    _bodyFont = dc['body_font'] as String? ?? 'Roboto';
    if (!_fontOptions.contains(_headingFont)) _headingFont = 'Roboto';
    if (!_fontOptions.contains(_bodyFont)) _bodyFont = 'Roboto';

    _selectedLayout = dc['layout_mode'] as String? ?? 'modern_grid';
    _enablePaperTexture = dc['enable_paper_texture'] as bool? ?? false;
    _bgColorCtrl.text = dc['bg_color'] as String? ?? '#F9FAFB';
    _headingColorCtrl.text = dc['heading_color'] as String? ?? '#000000';
    _bodyColorCtrl.text = dc['body_color'] as String? ?? '#424242';
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
        'heading_font': _headingFont,
        'body_font': _bodyFont,
        'font_family': _headingFont, // Legacy compat
        'layout_mode': _selectedLayout,
        'enable_paper_texture': _enablePaperTexture,
        'bg_color': _bgColorCtrl.text.trim(),
        'heading_color': _headingColorCtrl.text.trim(),
        'body_color': _bodyColorCtrl.text.trim(),
      };

      await saveSettings(
        ref: ref,
        tenantId: tenant.id,
        updates: {
          'primary_color': _primaryColorCtrl.text.trim(),
          'banner_url': _bannerUrl,
          'phone_number': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          'instagram_handle': _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
          'wifi_name': _wifiNameController.text.trim().isEmpty ? null : _wifiNameController.text.trim(),
          'wifi_password': _wifiPasswordController.text.trim().isEmpty ? null : _wifiPasswordController.text.trim(),
          'design_config': designConfig,
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
            // ──────────────── SECTION 1: GÖRÜNÜM & TASARIM ────────────────
            const _SectionTitle(title: 'Görünüm & Tasarım'),
            const SizedBox(height: 16),

            // Banner Card
            _SettingsCard(
              children: [
                const Text('Mekan Afişi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _isUploadingBanner ? null : _uploadBanner,
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
                    child: _isUploadingBanner
                        ? const CircularProgressIndicator()
                        : (_bannerUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey.shade500),
                                  const SizedBox(height: 8),
                                  Text('Afiş Yükle', style: TextStyle(color: Colors.grey.shade600)),
                                ],
                              )
                            : null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ──────────────── COLOR PALETTE ────────────────
            _SettingsCard(
              children: [
                const Text('Renk Paleti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 6),
                Text('Menünüzün genel rengini belirleyin', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 20),
                _ColorPickerRow(label: 'Marka Rengi (Primary)', controller: _primaryColorCtrl, presets: _primaryPresets, onChanged: () => setState(() {})),
                const Divider(height: 32),
                _ColorPickerRow(label: 'Arka Plan Rengi', controller: _bgColorCtrl, presets: _bgPresets, onChanged: () => setState(() {})),
                const Divider(height: 32),
                _ColorPickerRow(label: 'Başlık Metin Rengi', controller: _headingColorCtrl, presets: _headingTextPresets, onChanged: () => setState(() {})),
                const Divider(height: 32),
                _ColorPickerRow(label: 'Gövde Metin Rengi', controller: _bodyColorCtrl, presets: _bodyTextPresets, onChanged: () => setState(() {})),
              ],
            ),
            const SizedBox(height: 20),

            // ──────────────── TYPOGRAPHY ────────────────
            _SettingsCard(
              children: [
                const Text('Tipografi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 16),
                _FontDropdown(label: 'Başlık Fontu', value: _headingFont, onChanged: (v) => setState(() => _headingFont = v!)),
                const SizedBox(height: 16),
                _FontDropdown(label: 'Gövde Fontu', value: _bodyFont, onChanged: (v) => setState(() => _bodyFont = v!)),
              ],
            ),
            const SizedBox(height: 20),

            // ──────────────── LAYOUT ────────────────
            _SettingsCard(
              children: [
                const Text('Menü Düzeni', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedLayout,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                  ),
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  dropdownColor: Colors.white,
                  items: _layoutOptions.map((l) => DropdownMenuItem(
                    value: l['id'] as String,
                    child: Row(children: [
                      Icon(l['icon'] as IconData, size: 18, color: Colors.black54),
                      const SizedBox(width: 10),
                      Text(l['label'] as String),
                    ]),
                  )).toList(),
                  onChanged: (val) => setState(() {
                    _selectedLayout = val!;
                    if (_selectedLayout != 'minimal_list') _enablePaperTexture = false;
                  }),
                ),

                // Paper Texture Toggle
                if (_selectedLayout == 'minimal_list') ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Kağıt Dokusu (Texture)', style: TextStyle(fontSize: 14, color: Colors.black87)),
                    subtitle: const Text('Arka plana kağıt efekti ekler'),
                    value: _enablePaperTexture,
                    activeColor: Colors.black,
                    onChanged: (val) => setState(() => _enablePaperTexture = val),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 32),

            // ──────────────── SECTION 2: İLETİŞİM & İNTERNET ────────────────
            const _SectionTitle(title: 'İletişim & İnternet'),
            const SizedBox(height: 16),

            _SettingsCard(
              children: [
                _SettingsListTile(label: 'Telefon', icon: Icons.phone_outlined, controller: _phoneController),
                const Divider(height: 1, indent: 56),
                _SettingsListTile(label: 'Instagram', icon: Icons.camera_alt_outlined, controller: _instagramController, prefixText: '@'),
              ],
            ),
            const SizedBox(height: 20),

            _SettingsCard(
              children: [
                _SettingsListTile(label: 'Wi-Fi Adı', icon: Icons.wifi, controller: _wifiNameController),
                const Divider(height: 1, indent: 56),
                _SettingsListTile(label: 'Şifre', icon: Icons.lock_outline, controller: _wifiPasswordController),
              ],
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ──────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
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

class _ColorPickerRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<Color> presets;
  final VoidCallback onChanged;

  const _ColorPickerRow({
    required this.label,
    required this.controller,
    required this.presets,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 10),
        Row(
          children: [
            ...presets.map((color) {
              final hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
              final isSelected = controller.text.toUpperCase() == hex;
              return GestureDetector(
                onTap: () {
                  controller.text = hex;
                  onChanged();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey.shade300,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 2),
                    ],
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 16, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                      : null,
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 180,
          child: TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.black87, fontSize: 14, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: '#000000',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              labelText: 'HEX Kodu',
              labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _parseColor(controller.text),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      if (cleaned.length == 6) return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {}
    return Colors.grey;
  }
}

class _FontDropdown extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String?> onChanged;

  const _FontDropdown({required this.label, required this.value, required this.onChanged});

  static const _fonts = ['Roboto', 'Lora', 'Open Sans', 'Montserrat'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
          ),
          style: const TextStyle(color: Colors.black87, fontSize: 15),
          dropdownColor: Colors.white,
          items: _fonts.map((f) => DropdownMenuItem(
            value: f,
            child: Text(f, style: TextStyle(fontFamily: f)),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
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
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          border: InputBorder.none,
          hintText: 'Belirtilmedi',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixText: prefixText,
        ),
      ),
    );
  }
}
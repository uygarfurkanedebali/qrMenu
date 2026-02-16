/// Shop Settings Screen — Design Engine v2
///
/// Granular font, color (via HexColorPicker), layout, texture, and contact controls.
/// Saves design_config JSON to Supabase tenants table.
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

  // Color state
  Color _primaryColor = const Color(0xFFFF5722);
  Color _bgColor = const Color(0xFFF9FAFB);
  Color _headingColor = const Color(0xFF000000);
  Color _bodyColor = const Color(0xFF424242);
  Color _accentColor = const Color(0xFFFF9800);

  // Typography
  String _headingFont = 'Roboto';
  String _bodyFont = 'Roboto';
  static const _fontOptions = ['Roboto', 'Lora', 'Open Sans', 'Montserrat'];

  // Layout
  String _layoutMode = 'modern_grid';
  bool _enablePaperTexture = false;

  static const _layoutChoices = [
    {'id': 'modern_grid', 'label': 'Modern Grid', 'icon': Icons.grid_view},
    {'id': 'paper_list', 'label': 'Paper List (Minimal)', 'icon': Icons.list_alt},
    {'id': 'tinder_cards', 'label': 'Tinder Cards', 'icon': Icons.swipe},
  ];

  // Contact
  final _phoneController = TextEditingController();
  final _instagramController = TextEditingController();
  final _wifiNameController = TextEditingController();
  final _wifiPasswordController = TextEditingController();

  // Banner
  String? _bannerUrl;
  bool _isUploadingBanner = false;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _instagramController.dispose();
    _wifiNameController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  Color _parseHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final cleaned = hex.replaceAll('#', '').trim();
      if (cleaned.length == 6) return Color(int.parse('FF$cleaned', radix: 16));
      if (cleaned.length == 8) return Color(int.parse(cleaned, radix: 16));
    } catch (_) {}
    return fallback;
  }

  String _colorToHex(Color c) {
    return '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  void _populateForm(dynamic tenant) {
    if (_initialized) return;
    _initialized = true;

    _primaryColor = _parseHex(tenant.primaryColor, const Color(0xFFFF5722));
    _phoneController.text = tenant.phoneNumber ?? '';
    _instagramController.text = tenant.instagramHandle ?? '';
    _wifiNameController.text = tenant.wifiName ?? '';
    _wifiPasswordController.text = tenant.wifiPassword ?? '';
    _bannerUrl = tenant.bannerUrl;

    final dc = tenant.designConfig as Map<String, dynamic>? ?? {};
    _headingFont = dc['heading_font'] as String? ?? dc['font_family'] as String? ?? 'Roboto';
    _bodyFont = dc['body_font'] as String? ?? 'Roboto';
    if (!_fontOptions.contains(_headingFont)) _headingFont = 'Roboto';
    if (!_fontOptions.contains(_bodyFont)) _bodyFont = 'Roboto';

    _layoutMode = dc['layout_mode'] as String? ?? 'modern_grid';
    _enablePaperTexture = dc['enable_paper_texture'] as bool? ?? false;
    _bgColor = _parseHex(dc['bg_color'] as String?, const Color(0xFFF9FAFB));
    _headingColor = _parseHex(dc['heading_color'] as String?, const Color(0xFF000000));
    _bodyColor = _parseHex(dc['body_color'] as String?, const Color(0xFF424242));
    _accentColor = _parseHex(dc['accent_color'] as String?, const Color(0xFFFF9800));
  }

  Future<void> _uploadBanner() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (image == null) return;

    setState(() => _isUploadingBanner = true);
    try {
      final service = ref.read(storageServiceProvider);
      final url = await service.uploadTenantBanner(image);
      if (mounted) setState(() { _bannerUrl = url; _isUploadingBanner = false; });
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
        'font_family': _headingFont,
        'layout_mode': _layoutMode,
        'enable_paper_texture': _enablePaperTexture,
        'bg_color': _colorToHex(_bgColor),
        'heading_color': _colorToHex(_headingColor),
        'body_color': _colorToHex(_bodyColor),
        'accent_color': _colorToHex(_accentColor),
      };

      await saveSettings(
        ref: ref,
        tenantId: tenant.id,
        updates: {
          'primary_color': _colorToHex(_primaryColor),
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
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Ayarlar başarıyla kaydedildi!'),
            ]),
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
    if (tenant == null) {
      return const Scaffold(body: Center(child: Text('Giriş yapın', style: TextStyle(color: Colors.black54))));
    }

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
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
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
            // ═══════════════════ SECTION 1: GÖRÜNÜM ═══════════════════
            _SectionHeader(title: 'Görünüm & Tasarım'),
            const SizedBox(height: 16),

            // Banner
            _Card(children: [
              const _FieldLabel('Mekan Afişi'),
              const SizedBox(height: 12),
              InkWell(
                onTap: _isUploadingBanner ? null : _uploadBanner,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
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
                          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey.shade500),
                              const SizedBox(height: 8),
                              Text('Afiş Yükle', style: TextStyle(color: Colors.grey.shade600)),
                            ])
                          : null),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // ─── COLOR PALETTE ───
            _Card(children: [
              const _FieldLabel('Renk Paleti'),
              const SizedBox(height: 4),
              Text('Menünüzün renklerini özelleştirin', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 20),

              HexColorPicker(
                label: 'Marka Rengi (Primary)',
                color: _primaryColor,
                onColorChanged: (c) => setState(() => _primaryColor = c),
              ),
              const Divider(height: 28),

              HexColorPicker(
                label: 'Arka Plan Rengi',
                color: _bgColor,
                onColorChanged: (c) => setState(() => _bgColor = c),
              ),
              const Divider(height: 28),

              HexColorPicker(
                label: 'Başlık Metin Rengi',
                color: _headingColor,
                onColorChanged: (c) => setState(() => _headingColor = c),
              ),
              const Divider(height: 28),

              HexColorPicker(
                label: 'Gövde Metin Rengi',
                color: _bodyColor,
                onColorChanged: (c) => setState(() => _bodyColor = c),
              ),
              const Divider(height: 28),

              HexColorPicker(
                label: 'Vurgu Rengi (Accent)',
                color: _accentColor,
                onColorChanged: (c) => setState(() => _accentColor = c),
              ),
            ]),
            const SizedBox(height: 20),

            // ─── TYPOGRAPHY ───
            _Card(children: [
              const _FieldLabel('Tipografi'),
              const SizedBox(height: 16),
              _buildDropdownField('Başlık Fontu', _headingFont, _fontOptions, (v) => setState(() => _headingFont = v!)),
              const SizedBox(height: 16),
              _buildDropdownField('Gövde Fontu', _bodyFont, _fontOptions, (v) => setState(() => _bodyFont = v!)),
            ]),
            const SizedBox(height: 20),

            // ─── LAYOUT ───
            _Card(children: [
              const _FieldLabel('Menü Düzeni'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _layoutMode,
                decoration: _inputDecoration(label: 'Düzen Seçin'),
                style: const TextStyle(color: Colors.black87, fontSize: 15),
                dropdownColor: Colors.white,
                items: _layoutChoices.map((l) => DropdownMenuItem(
                  value: l['id'] as String,
                  child: Row(children: [
                    Icon(l['icon'] as IconData, size: 18, color: Colors.black54),
                    const SizedBox(width: 10),
                    Text(l['label'] as String),
                  ]),
                )).toList(),
                onChanged: (val) => setState(() {
                  _layoutMode = val!;
                  if (_layoutMode != 'paper_list') _enablePaperTexture = false;
                }),
              ),

              if (_layoutMode == 'paper_list') ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kağıt Dokusu (Texture)', style: TextStyle(fontSize: 14, color: Colors.black87)),
                  subtitle: Text('Arka plana kağıt efekti ekler', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  value: _enablePaperTexture,
                  activeColor: Colors.black,
                  onChanged: (val) => setState(() => _enablePaperTexture = val),
                ),
              ],
            ]),

            const SizedBox(height: 32),

            // ═══════════════════ SECTION 2: İLETİŞİM ═══════════════════
            _SectionHeader(title: 'İletişim & İnternet'),
            const SizedBox(height: 16),

            _Card(children: [
              _buildTextField(label: 'Telefon Numarası', controller: _phoneController, icon: Icons.phone_outlined),
              const SizedBox(height: 16),
              _buildTextField(label: 'Instagram Kullanıcı Adı', controller: _instagramController, icon: Icons.camera_alt_outlined, prefix: '@'),
            ]),
            const SizedBox(height: 20),

            _Card(children: [
              _buildTextField(label: 'Wi-Fi Adı (SSID)', controller: _wifiNameController, icon: Icons.wifi),
              const SizedBox(height: 16),
              _buildTextField(label: 'Wi-Fi Şifresi', controller: _wifiPasswordController, icon: Icons.lock_outline),
            ]),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // ─── Builders ───

  InputDecoration _inputDecoration({String? label, String? hint, IconData? icon, String? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixText: prefix,
      prefixIcon: icon != null ? Icon(icon, color: Colors.black54, size: 20) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, IconData? icon, String? prefix}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: _inputDecoration(label: label, icon: icon, prefix: prefix),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: _inputDecoration(),
          style: const TextStyle(color: Colors.black87, fontSize: 15),
          dropdownColor: Colors.white,
          items: options.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ─── Helper Widgets ───

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.0));
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87));
  }
}
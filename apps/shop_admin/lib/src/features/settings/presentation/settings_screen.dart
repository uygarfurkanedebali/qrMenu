/// Shop Settings Screen — General Business Settings
///
/// Handles operational settings like Phone, Instagram, WiFi, etc.
/// Visuals/Themes are moved to Appearance Settings (AppearanceSettingsScreen).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../../auth/application/auth_provider.dart';
import '../application/settings_provider.dart';
import '../../navigation/admin_menu_drawer.dart';

class ShopSettingsScreen extends ConsumerStatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  ConsumerState<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends ConsumerState<ShopSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contact & Socials
  final _phoneController = TextEditingController();
  final _instagramController = TextEditingController();

  // Wi-Fi
  final _wifiNameController = TextEditingController();
  final _wifiPasswordController = TextEditingController();

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

  void _populateForm(dynamic tenant) {
    if (_initialized) return;
    _initialized = true;

    _phoneController.text = tenant.phoneNumber ?? '';
    _instagramController.text = tenant.instagramHandle ?? '';
    _wifiNameController.text = tenant.wifiName ?? '';
    _wifiPasswordController.text = tenant.wifiPassword ?? '';
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
          'phone_number': _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          'instagram_handle': _instagramController.text.trim().isEmpty
              ? null
              : _instagramController.text.trim(),
          'wifi_name': _wifiNameController.text.trim().isEmpty
              ? null
              : _wifiNameController.text.trim(),
          'wifi_password': _wifiPasswordController.text.trim().isEmpty
              ? null
              : _wifiPasswordController.text.trim(),
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
      return const Scaffold(
          body: Center(
              child: Text('Giriş yapın',
                  style: TextStyle(color: Colors.black54))));
    }

    _populateForm(tenant);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Mekan Ayarları',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 18),
              label: Text(_isSaving ? 'Kaydediliyor' : 'Kaydet'),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.black, foregroundColor: Colors.white),
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
            // ═══════════════════ SECTION 1: İLETİŞİM ═══════════════════
            _SectionHeader(title: 'İletişim Bilgileri'),
            const SizedBox(height: 16),
            _Card(children: [
              _buildTextField(
                  label: 'Telefon Numarası',
                  controller: _phoneController,
                  icon: Icons.phone_outlined),
              const SizedBox(height: 16),
              _buildTextField(
                  label: 'Instagram Kullanıcı Adı',
                  controller: _instagramController,
                  icon: Icons.camera_alt_outlined,
                  prefix: '@'),
            ]),

            const SizedBox(height: 32),

            // ═══════════════════ SECTION 2: İNTERNET ═══════════════════
            _SectionHeader(title: 'Müşteri Wi-Fi Ağı'),
            const SizedBox(height: 16),
            _Card(children: [
              _buildTextField(
                  label: 'Wi-Fi Adı (SSID)',
                  controller: _wifiNameController,
                  icon: Icons.wifi),
              const SizedBox(height: 16),
              _buildTextField(
                  label: 'Wi-Fi Şifresi',
                  controller: _wifiPasswordController,
                  icon: Icons.lock_outline),
            ]),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // ─── Builders ───

  InputDecoration _inputDecoration(
      {required String label, String? hint, IconData? icon, String? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixText: prefix,
      prefixIcon:
          icon != null ? Icon(icon, color: Colors.black54, size: 20) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildTextField(
      {required String label,
      required TextEditingController controller,
      IconData? icon,
      String? prefix}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: _inputDecoration(label: label, icon: icon, prefix: prefix),
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(),
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
            letterSpacing: 1.0));
  }
}

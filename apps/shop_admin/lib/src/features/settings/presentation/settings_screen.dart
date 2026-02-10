/// Shop Settings Screen
///
/// Full configuration dashboard for shop branding,
/// contact info, and customer-facing settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/application/auth_provider.dart';
import '../application/settings_provider.dart';

/// Pre-defined brand colors for quick selection
const _presetColors = [
  '#FF5722', // Deep Orange
  '#E91E63', // Pink
  '#9C27B0', // Purple
  '#3F51B5', // Indigo
  '#2196F3', // Blue
  '#009688', // Teal
  '#4CAF50', // Green
  '#FF9800', // Orange
  '#795548', // Brown
  '#607D8B', // Blue Grey
];

/// Available Google Fonts
const _fontFamilies = ['Roboto', 'Lato', 'Montserrat', 'Open Sans', 'Poppins', 'Inter', 'Nunito', 'Raleway'];

/// Currency options
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

  void _populateForm(TenantState tenant) {
    if (_initialized) return;
    _initialized = true;

    _colorController.text = tenant.primaryColor;
    _phoneController.text = tenant.phoneNumber ?? '';
    _instagramController.text = tenant.instagramHandle ?? '';
    _wifiNameController.text = tenant.wifiName ?? '';
    _wifiPasswordController.text = tenant.wifiPassword ?? '';
    _selectedFont = tenant.fontFamily;
    _selectedCurrency = tenant.currencySymbol;
  }

  Color _parseHexColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join();
      }
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
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
          'font_family': _selectedFont,
          'currency_symbol': _selectedCurrency,
          'phone_number': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          'instagram_handle': _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
          'wifi_name': _wifiNameController.text.trim().isEmpty ? null : _wifiNameController.text.trim(),
          'wifi_password': _wifiPasswordController.text.trim().isEmpty ? null : _wifiPasswordController.text.trim(),
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
          SnackBar(
            content: Text('Kaydetme hatası: $e'),
            backgroundColor: Colors.red,
          ),
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

    if (tenant == null) {
      return const Scaffold(
        body: Center(child: Text('Lütfen giriş yapın')),
      );
    }

    _populateForm(tenant);

    final primaryColor = _parseHexColor(_colorController.text);

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
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
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
            // ═══════════════════════════════════════
            // SECTION 1: GÖRÜNÜM (Appearance)
            // ═══════════════════════════════════════
            _SectionHeader(
              icon: Icons.palette,
              title: 'Görünüm',
              subtitle: 'Dükkanınızın marka rengi ve yazı tipi',
            ),
            const SizedBox(height: 12),

            // Color picker
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ana Renk', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),

                    // Quick select color circles
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presetColors.map((hex) {
                        final isSelected = _colorController.text.toUpperCase() == hex.toUpperCase();
                        return GestureDetector(
                          onTap: () {
                            setState(() => _colorController.text = hex);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _parseHexColor(hex),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _parseHexColor(hex).withAlpha(120),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Hex input
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _colorController,
                            decoration: const InputDecoration(
                              labelText: 'Hex Renk Kodu',
                              hintText: '#FF5722',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.tag),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Renk kodu gerekli';
                              final hex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
                              if (!hex.hasMatch(v)) return 'Geçersiz format (örn: #FF5722)';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Font picker
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _fontFamilies.contains(_selectedFont) ? _selectedFont : 'Roboto',
                      decoration: const InputDecoration(
                        labelText: 'Yazı Tipi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.text_fields),
                      ),
                      items: _fontFamilies.map((f) {
                        TextStyle fontStyle;
                        try {
                          fontStyle = GoogleFonts.getFont(f, fontSize: 16);
                        } catch (_) {
                          fontStyle = const TextStyle(fontSize: 16);
                        }
                        return DropdownMenuItem(
                          value: f,
                          child: Text(f, style: fontStyle),
                        );
                      }).toList(),
                      selectedItemBuilder: (context) {
                        return _fontFamilies.map((f) {
                          TextStyle fontStyle;
                          try {
                            fontStyle = GoogleFonts.getFont(f, fontSize: 16);
                          } catch (_) {
                            fontStyle = const TextStyle(fontSize: 16);
                          }
                          return Text(f, style: fontStyle);
                        }).toList();
                      },
                      onChanged: (v) => setState(() => _selectedFont = v ?? 'Roboto'),
                    ),
                    const SizedBox(height: 12),
                    // Font preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Önizleme',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Builder(builder: (context) {
                            TextStyle previewStyle;
                            try {
                              previewStyle = GoogleFonts.getFont(
                                _selectedFont,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              );
                            } catch (_) {
                              previewStyle = const TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
                            }
                            return Text(
                              'Merhaba Dünya! 🍽️',
                              style: previewStyle,
                            );
                          }),
                          const SizedBox(height: 4),
                          Builder(builder: (context) {
                            TextStyle previewStyle;
                            try {
                              previewStyle = GoogleFonts.getFont(
                                _selectedFont,
                                fontSize: 14,
                              );
                            } catch (_) {
                              previewStyle = const TextStyle(fontSize: 14);
                            }
                            return Text(
                              'Menümüzden en lezzetli seçenekleri keşfedin.',
                              style: previewStyle,
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ═══════════════════════════════════════
            // SECTION 2: İLETİŞİM (Contact)
            // ═══════════════════════════════════════
            _SectionHeader(
              icon: Icons.phone,
              title: 'İletişim',
              subtitle: 'Müşterilerinizin sizi ulaşabileceği bilgiler',
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon Numarası',
                        hintText: '+90 5XX XXX XX XX',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instagramController,
                      decoration: const InputDecoration(
                        labelText: 'Instagram',
                        hintText: 'dukkan_hesabi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.camera_alt_outlined),
                        prefixText: '@ ',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ═══════════════════════════════════════
            // SECTION 3: OPERASYON (Operations)
            // ═══════════════════════════════════════
            _SectionHeader(
              icon: Icons.settings,
              title: 'Operasyon',
              subtitle: 'Para birimi ve işletme ayarları',
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: _currencies.contains(_selectedCurrency) ? _selectedCurrency : '₺',
                  decoration: const InputDecoration(
                    labelText: 'Para Birimi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  items: _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 18))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCurrency = v ?? '₺'),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ═══════════════════════════════════════
            // SECTION 4: MÜŞTERİ (Customer Utility)
            // ═══════════════════════════════════════
            _SectionHeader(
              icon: Icons.wifi,
              title: 'Müşteri Bilgileri',
              subtitle: 'Menüde müşterilerinize gösterilecek bilgiler',
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _wifiNameController,
                      decoration: const InputDecoration(
                        labelText: 'Wi-Fi Adı',
                        hintText: 'Cafe_WiFi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.wifi),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _wifiPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Wi-Fi Şifresi',
                        hintText: '••••••••',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save button (bottom)
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _isSaving ? 'Kaydediliyor...' : 'Ayarları Kaydet',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

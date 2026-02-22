import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../application/settings_provider.dart';
import '../../auth/application/auth_provider.dart';
import '../../navigation/admin_menu_drawer.dart';
import '../../shared/presentation/widgets/advanced_color_picker.dart';

class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  ConsumerState<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState
    extends ConsumerState<AppearanceSettingsScreen> {
  bool _initialized = false;
  bool _isSaving = false;

  // Modern Grid Arka Plan Rengi
  Color _backgroundColor = const Color(0xFFFFFFFF);

  String _colorToHex(Color c) {
    return '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
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

  void _populateState(dynamic tenant) {
    if (_initialized) return;
    _initialized = true;

    // Supabase'deki Tenant modelinde "settings" objesi mevcut olmadigi icin (Sadece designConfig mevcut),
    // modern_grid layout tarafinda da beklenen background_color alanini designConfig icine mapliyoruz.
    final dc = tenant.designConfig as Map<String, dynamic>? ?? {};
    _backgroundColor = _parseHex(
        dc['background_color'] as String? ?? dc['global_bg_color'] as String?,
        const Color(0xFFFFFFFF));
  }

  Future<void> _save() async {
    final tenant = ref.read(currentTenantProvider);
    if (tenant == null) return;

    setState(() => _isSaving = true);

    try {
      final currentDesignConfig =
          Map<String, dynamic>.from(tenant.designConfig as Map? ?? {});

      // Kullanicinin istedigi gibi rengi HEX formatina cevirip json'a kaydediyoruz.
      // Not: Model formatina uyumluluk acisindan "designConfig" kullanilmistir.
      currentDesignConfig['background_color'] = _colorToHex(_backgroundColor);
      currentDesignConfig['global_bg_color'] = _colorToHex(_backgroundColor);

      await saveSettings(
        ref: ref,
        tenantId: tenant.id,
        updates: {
          'design_config': currentDesignConfig,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Görünüm ayarları başarıyla kaydedildi!'),
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

  void _openColorPicker() {
    Color tempColor = _backgroundColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Arka Plan Rengi Seç',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SingleChildScrollView(
            child: AdvancedColorPicker(
              initialColor: _backgroundColor,
              title: 'Sayfa Arka Plan Rengi',
              onColorChanged: (c) => tempColor = c,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _backgroundColor = tempColor;
                });
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Seç'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenant = ref.watch(currentTenantProvider);
    if (tenant == null) {
      return const Scaffold(
        body: Center(
            child:
                Text('Giriş yapın', style: TextStyle(color: Colors.black54))),
      );
    }

    _populateState(tenant);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Görünüm ve Tema Ayarları',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
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
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.palette, size: 18),
              label: Text(_isSaving ? 'Kaydediliyor' : 'Temayı Kaydet'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MODERN GRID AYARLARI',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                title: const Text(
                  'Sayfa Arka Plan Rengi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                trailing: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
                onTap: _openColorPicker,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

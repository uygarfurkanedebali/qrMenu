/// Shop Admin - Independent Appearance Settings Screen
///
/// Handles menu layout selection, banner uploading, and granular
/// color scheme picking using the AdvancedColorPicker.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_core/shared_core.dart';
import '../../auth/application/auth_provider.dart';
import '../application/settings_provider.dart';
import '../../products/data/mock_storage_service.dart';
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

  // Layout Options
  String _layoutMode = 'modern_grid';
  static const _layoutChoices = [
    {'id': 'modern_grid', 'label': 'Modern Grid', 'icon': Icons.grid_view},
    {
      'id': 'paper_menu',
      'label': 'Paper Menu (Kağıt Görünüm)',
      'icon': Icons.history_edu
    },
  ];

  // Banner
  String? _bannerUrl;
  bool _isUploadingBanner = false;

  // 1. Global Settings
  Color _globalBgColor = const Color(0xFFFFFFFF);
  Color _globalSurfaceColor = const Color(0xFFF5F5F5); // Grey.shade100
  Color _globalAccentColor = const Color(0xFF000000);

  // 2. Categories & Titles
  Color _categoryTitleColor = const Color(0xFF000000);
  Color _categoryActiveTextColor = const Color(0xFFFFFFFF);
  Color _categoryInactiveTextColor = const Color(0xFF424242); // Grey.shade800
  bool _showCategoryDivider = true;

  // 3. Product Cards
  Color _productTitleColor = const Color(0xFF212121); // Grey.shade900
  Color _productDescColor = const Color(0xFF9E9E9E); // Grey.shade500
  Color _productPriceColor = const Color(0xFF424242); // Grey.shade800
  Color _productCardBg = const Color(0xFFFFFFFF);

  // 4. Layout-Specific Settings
  // -> Modern Grid
  Color _mgCardBorderColor = const Color(0xFFEEEEEE); // Grey.shade200
  // -> Paper Menu
  double _pmNoiseOpacity = 0.05;
  Color _pmDottedLineColor = const Color(0x42000000); // Black26
  bool _pmShowDottedLine = true;

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

  void _populateState(dynamic tenant) {
    if (_initialized) return;
    _initialized = true;

    _bannerUrl = tenant.bannerUrl;

    final dc = tenant.designConfig as Map<String, dynamic>? ?? {};

    // Fallbacks if existing settings exist
    _layoutMode = dc['layout_mode'] as String? ?? 'modern_grid';

    // 1. Global
    _globalBgColor = _parseHex(
        dc['global_bg_color'] as String? ?? dc['background_color'] as String?,
        const Color(0xFFFFFFFF));
    _globalSurfaceColor = _parseHex(
        dc['global_surface_color'] as String? ??
            dc['secondary_color'] as String?,
        const Color(0xFFF5F5F5));
    _globalAccentColor = _parseHex(
        dc['global_accent_color'] as String? ?? dc['accent_color'] as String?,
        const Color(0xFF000000));

    // 2. Categories
    _categoryTitleColor = _parseHex(
        dc['category_title_color'] as String? ??
            dc['title_text_color'] as String?,
        const Color(0xFF000000));
    _categoryActiveTextColor = _parseHex(
        dc['category_active_text_color'] as String?, const Color(0xFFFFFFFF));
    _categoryInactiveTextColor = _parseHex(
        dc['category_inactive_text_color'] as String?, const Color(0xFF424242));
    _showCategoryDivider = dc['show_category_divider'] as bool? ?? true;

    // 3. Products
    _productTitleColor = _parseHex(
        dc['product_title_color'] as String? ??
            dc['product_text_color'] as String?,
        const Color(0xFF212121));
    _productDescColor =
        _parseHex(dc['product_desc_color'] as String?, const Color(0xFF757575));
    _productPriceColor = _parseHex(
        dc['product_price_color'] as String?, const Color(0xFF424242));
    _productCardBg =
        _parseHex(dc['product_card_bg'] as String?, const Color(0xFFFFFFFF));

    // 4. Layout Specific
    _mgCardBorderColor = _parseHex(
        dc['mg_card_border_color'] as String?, const Color(0xFFEEEEEE));

    _pmNoiseOpacity = (dc['pm_noise_opacity'] as num?)?.toDouble() ?? 0.05;
    _pmDottedLineColor = _parseHex(
        dc['pm_dotted_line_color'] as String?, const Color(0x42000000));
    _pmShowDottedLine = dc['pm_show_dotted_line'] as bool? ?? true;
  }

  Future<void> _uploadBanner() async {
    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (image == null) return;

    setState(() => _isUploadingBanner = true);
    try {
      final service = ref.read(storageServiceProvider);
      final url = await service.uploadTenantBanner(image);
      if (mounted)
        setState(() {
          _bannerUrl = url;
          _isUploadingBanner = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingBanner = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Yükleme hatası: $e')));
      }
    }
  }

  Future<void> _save() async {
    final tenant = ref.read(currentTenantProvider);
    if (tenant == null) return;

    setState(() => _isSaving = true);

    try {
      final designConfig = {
        'layout_mode': _layoutMode,
        // Global
        'global_bg_color': _colorToHex(_globalBgColor),
        'global_surface_color': _colorToHex(_globalSurfaceColor),
        'global_accent_color': _colorToHex(_globalAccentColor),
        // Categories
        'category_title_color': _colorToHex(_categoryTitleColor),
        'category_active_text_color': _colorToHex(_categoryActiveTextColor),
        'category_inactive_text_color': _colorToHex(_categoryInactiveTextColor),
        'show_category_divider': _showCategoryDivider,
        // Products
        'product_title_color': _colorToHex(_productTitleColor),
        'product_desc_color': _colorToHex(_productDescColor),
        'product_price_color': _colorToHex(_productPriceColor),
        'product_card_bg': _colorToHex(_productCardBg),
        // Layout specific
        'mg_card_border_color': _colorToHex(_mgCardBorderColor),
        'pm_noise_opacity': _pmNoiseOpacity,
        'pm_dotted_line_color': _colorToHex(_pmDottedLineColor),
        'pm_show_dotted_line': _pmShowDottedLine,
      };

      await saveSettings(
        ref: ref,
        tenantId: tenant.id,
        updates: {
          'banner_url': _bannerUrl,
          'primary_color': _colorToHex(_globalAccentColor),
          'design_config': designConfig,
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

  void _pickColor(String title, Color current, ValueChanged<Color> onSelected) {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = current;
        return AlertDialog(
          title: Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SingleChildScrollView(
            child: AdvancedColorPicker(
              initialColor: current,
              title: title,
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
                onSelected(tempColor);
                Navigator.of(context).pop();
                setState(() {});
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
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
              child: Text('Giriş yapın',
                  style: TextStyle(color: Colors.black54))));
    }

    _populateState(tenant);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Görünüm ve Tema',
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
                  : const Icon(Icons.palette, size: 18),
              label: Text(_isSaving ? 'Kaydediliyor' : 'Temayı Kaydet'),
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
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ─── BANNER UPLOAD ───
          _SectionHeader(title: 'Mekan Afişi'),
          const SizedBox(height: 12),
          InkWell(
            onTap: _isUploadingBanner ? null : _uploadBanner,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                image: _bannerUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_bannerUrl!), fit: BoxFit.cover)
                    : null,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              alignment: Alignment.center,
              child: _isUploadingBanner
                  ? const CircularProgressIndicator()
                  : (_bannerUrl == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(Icons.add_photo_alternate_rounded,
                                  size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('Afiş Yükle',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500)),
                            ])
                      : Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 24),
                        )),
            ),
          ),
          const SizedBox(height: 32),

          // ─── LAYOUT SELECTOR ───
          _SectionHeader(title: 'Menü Şablonu (Layout)'),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _layoutChoices.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final layout = _layoutChoices[index];
                final isSelected = _layoutMode == layout['id'];

                return GestureDetector(
                  onTap: () =>
                      setState(() => _layoutMode = layout['id'] as String),
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  spreadRadius: 0,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]
                          : [],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(layout['icon'] as IconData,
                            size: 36,
                            color: isSelected ? Colors.white : Colors.black87),
                        const SizedBox(height: 12),
                        Text(
                          layout['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // ─── GRANULAR SETTINGS TILES ───
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Bölüm 1
                ExpansionTile(
                  title: const Text('Genel Ayarlar (Global)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  leading: const Icon(Icons.format_paint),
                  children: [
                    _ColorTile(
                      label: 'Arka Plan Rengi',
                      color: _globalBgColor,
                      onTap: () => _pickColor('Arka Plan Rengi', _globalBgColor,
                          (c) => _globalBgColor = c),
                    ),
                    _ColorTile(
                      label: 'İkincil Zemin',
                      color: _globalSurfaceColor,
                      onTap: () => _pickColor('İkincil Zemin',
                          _globalSurfaceColor, (c) => _globalSurfaceColor = c),
                    ),
                    _ColorTile(
                      label: 'Vurgu Rengi (Accent)',
                      color: _globalAccentColor,
                      onTap: () => _pickColor('Vurgu Rengi', _globalAccentColor,
                          (c) => _globalAccentColor = c),
                      isLast: true,
                    ),
                  ],
                ),
                Divider(height: 1, color: Colors.grey.shade200),

                // Bölüm 2
                ExpansionTile(
                  title: const Text('Kategoriler ve Başlıklar',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  leading: const Icon(Icons.text_fields),
                  children: [
                    _ColorTile(
                      label: 'Ana Başlık Metin Rengi',
                      color: _categoryTitleColor,
                      onTap: () => _pickColor('Ana Başlık Rengi',
                          _categoryTitleColor, (c) => _categoryTitleColor = c),
                    ),
                    _ColorTile(
                      label: 'Seçili Kategori Metin Rengi',
                      color: _categoryActiveTextColor,
                      onTap: () => _pickColor(
                          'Seçili Kategori Rengi',
                          _categoryActiveTextColor,
                          (c) => _categoryActiveTextColor = c),
                    ),
                    _ColorTile(
                      label: 'Pasif Kategori Metin Rengi',
                      color: _categoryInactiveTextColor,
                      onTap: () => _pickColor(
                          'Pasif Kategori Rengi',
                          _categoryInactiveTextColor,
                          (c) => _categoryInactiveTextColor = c),
                    ),
                    SwitchListTile(
                      title: const Text('Ayırıcı Çizgileri Göster',
                          style: TextStyle(fontSize: 14)),
                      value: _showCategoryDivider,
                      activeColor: Colors.black,
                      onChanged: (val) =>
                          setState(() => _showCategoryDivider = val),
                    ),
                  ],
                ),
                Divider(height: 1, color: Colors.grey.shade200),

                // Bölüm 3
                ExpansionTile(
                  title: const Text('Ürün Kartları',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  leading: const Icon(Icons.inventory_2_outlined),
                  children: [
                    _ColorTile(
                      label: 'Ürün Adı Rengi',
                      color: _productTitleColor,
                      onTap: () => _pickColor('Ürün Adı Rengi',
                          _productTitleColor, (c) => _productTitleColor = c),
                    ),
                    _ColorTile(
                      label: 'Ürün Açıklama Rengi',
                      color: _productDescColor,
                      onTap: () => _pickColor('Ürün Açıklama Rengi',
                          _productDescColor, (c) => _productDescColor = c),
                    ),
                    _ColorTile(
                      label: 'Ürün Fiyat Rengi',
                      color: _productPriceColor,
                      onTap: () => _pickColor('Fiyat Rengi', _productPriceColor,
                          (c) => _productPriceColor = c),
                    ),
                    _ColorTile(
                      label: 'Kart Zemin Rengi',
                      color: _productCardBg,
                      onTap: () => _pickColor('Kart Zemin Rengi',
                          _productCardBg, (c) => _productCardBg = c),
                      isLast: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── LAYOUT SPECIFIC SETTINGS ───
          if (_layoutMode == 'modern_grid') ...[
            _SectionHeader(title: 'Modern Grid Ayarları'),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _ColorTile(
                    label: 'Kart Sınır Çizgisi Rengi',
                    color: _mgCardBorderColor,
                    onTap: () => _pickColor('Sınır Çizgisi Rengi',
                        _mgCardBorderColor, (c) => _mgCardBorderColor = c),
                    isLast: true,
                  ),
                ],
              ),
            ),
          ] else if (_layoutMode == 'paper_menu') ...[
            _SectionHeader(title: 'Paper Menu Ayarları'),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Kağıt Dokusu Yoğunluğu',
                        style: TextStyle(fontSize: 14)),
                    subtitle: Slider(
                      value: _pmNoiseOpacity,
                      min: 0.0,
                      max: 0.15,
                      divisions: 15,
                      activeColor: Colors.black,
                      label: _pmNoiseOpacity.toStringAsFixed(2),
                      onChanged: (val) => setState(() => _pmNoiseOpacity = val),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade100, indent: 16),
                  _ColorTile(
                    label: 'Noktalı Çizgi (Dotted) Rengi',
                    color: _pmDottedLineColor,
                    onTap: () => _pickColor('Noktalı Çizgi Rengi',
                        _pmDottedLineColor, (c) => _pmDottedLineColor = c),
                  ),
                  SwitchListTile(
                    title: const Text('Noktalı Çizgiyi Göster',
                        style: TextStyle(fontSize: 14)),
                    value: _pmShowDottedLine,
                    activeColor: Colors.black,
                    onChanged: (val) => setState(() => _pmShowDottedLine = val),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 60),
        ],
      ),
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

class _ColorTile extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;

  const _ColorTile(
      {required this.label,
      required this.color,
      required this.onTap,
      this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(label, style: const TextStyle(fontSize: 14)),
          onTap: onTap,
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: Colors.grey.shade100, indent: 16),
      ],
    );
  }
}

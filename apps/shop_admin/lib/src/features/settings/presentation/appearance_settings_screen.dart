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

  // Layout Options
  String _layoutMode = 'modern_grid';

  // Modern Grid Arka Plan Rengi
  Color _backgroundColor = const Color(0xFFFFFFFF);
  bool _transparentCards = true;
  Color _textColor = const Color(0xFF000000);
  Color _accentColor = const Color(0xFF000000);

  // Paper Style Özel Renkleri ve Ayırıcısı
  bool _showProductImages = true;
  Color _categoryTitleColor = const Color(0xFF000000);
  Color _productTitleColor = const Color(0xDD000000);
  Color _productPriceColor = const Color(0xDD000000);
  Color _productDescColor = const Color(0x8A000000);
  Color _pmDottedLineColor = const Color(0x42000000);
  Color _categoryDividerColor = const Color(0x73000000);
  String _categoryDividerType = 'star';
  double _categoryDividerLength = 160.0;

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
    _layoutMode = dc['layout_mode'] as String? ?? 'modern_grid';

    _backgroundColor = _parseHex(
        dc['background_color'] as String? ?? dc['global_bg_color'] as String?,
        const Color(0xFFFFFFFF));
    _transparentCards = dc['transparent_cards'] as bool? ?? true;
    _textColor =
        _parseHex(dc['text_color'] as String?, const Color(0xFF000000));
    _accentColor = _parseHex(
        dc['global_accent_color'] as String? ?? dc['accent_color'] as String?,
        const Color(0xFF000000));
        
    // Paper Style Okumaları
    _showProductImages = dc['show_product_images'] as bool? ?? true;
    _categoryTitleColor = _parseHex(dc['category_title_color'] as String?, const Color(0xFF000000));
    _productTitleColor = _parseHex(dc['product_title_color'] as String? ?? dc['product_text_color'] as String?, const Color(0xDD000000));
    _productPriceColor = _parseHex(dc['product_price_color'] as String?, const Color(0xDD000000));
    _productDescColor = _parseHex(dc['product_desc_color'] as String?, const Color(0x8A000000));
    _pmDottedLineColor = _parseHex(dc['pm_dotted_line_color'] as String?, const Color(0x42000000));
    _categoryDividerColor = _parseHex(dc['category_divider_color'] as String?, const Color(0x73000000));
    _categoryDividerType = dc['category_divider_type'] as String? ?? 'star';
    _categoryDividerLength = (dc['category_divider_length'] as num?)?.toDouble() ?? 160.0;
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
      currentDesignConfig['layout_mode'] = _layoutMode;
      currentDesignConfig['background_color'] = _colorToHex(_backgroundColor);
      currentDesignConfig['global_bg_color'] = _colorToHex(_backgroundColor);
      currentDesignConfig['transparent_cards'] = _transparentCards;
      currentDesignConfig['text_color'] = _colorToHex(_textColor);
      currentDesignConfig['global_accent_color'] = _colorToHex(_accentColor);
      currentDesignConfig['accent_color'] = _colorToHex(_accentColor);

      // Paper Style Kayıtları
      currentDesignConfig['show_product_images'] = _showProductImages;
      currentDesignConfig['category_title_color'] = _colorToHex(_categoryTitleColor);
      currentDesignConfig['product_title_color'] = _colorToHex(_productTitleColor);
      currentDesignConfig['product_price_color'] = _colorToHex(_productPriceColor);
      currentDesignConfig['product_desc_color'] = _colorToHex(_productDescColor);
      currentDesignConfig['pm_dotted_line_color'] = _colorToHex(_pmDottedLineColor);
      currentDesignConfig['category_divider_color'] = _colorToHex(_categoryDividerColor);
      currentDesignConfig['category_divider_type'] = _categoryDividerType;
      currentDesignConfig['category_divider_length'] = _categoryDividerLength;

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

  void _openColorPicker(
      String title, Color current, ValueChanged<Color> onSelected) {
    Color tempColor = current;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87),
          ),
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
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Seç', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorTile(String title, Color color, ValueChanged<Color> onChanged) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
      ),
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
              offset: const Offset(0, 2),
            )
          ],
        ),
      ),
      onTap: () => _openColorPicker(title, color, onChanged),
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Görünüm ve Tema Ayarları',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
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
              'MENÜ GÖRÜNÜMÜ (LAYOUT)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _LayoutCard(
                    title: 'Modern Grid',
                    icon: Icons.grid_view,
                    isSelected: _layoutMode == 'modern_grid',
                    onTap: () => setState(() => _layoutMode = 'modern_grid'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _LayoutCard(
                    title: 'Paper Style',
                    icon: Icons.history_edu,
                    isSelected: _layoutMode == 'paper_list',
                    onTap: () => setState(() => _layoutMode = 'paper_list'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'GENEL TEMA AYARLARI',
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
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      'Aktif Kategori / Vurgu Rengi',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
                    ),
                    trailing: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _accentColor,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.grey.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                    ),
                    onTap: () => _openColorPicker(
                        'Vurgu Rengi', _accentColor, (c) => _accentColor = c),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_layoutMode == 'modern_grid') ...[
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
                child: Column(
                  children: [
                    ListTile(
                      title: const Text(
                        'Sayfa Arka Plan Rengi',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87),
                      ),
                      trailing: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _backgroundColor,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.grey.shade300, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                      ),
                      onTap: () => _openColorPicker('Arka Plan Rengi',
                          _backgroundColor, (c) => _backgroundColor = c),
                    ),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 16),
                    SwitchListTile(
                      title: const Text('Kartları Arka Planla Bütünleştir',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87)),
                      subtitle: const Text(
                          'Kutu görünümlerini (gölgeleri, kenarlıkları) kaldırıp şeffaf yapar',
                          style:
                              TextStyle(fontSize: 13, color: Colors.black54)),
                      value: _transparentCards,
                      activeColor: Colors.black,
                      onChanged: (val) =>
                          setState(() => _transparentCards = val),
                    ),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 16),
                    ListTile(
                      title: const Text(
                        'Ana Metin Rengi',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87),
                      ),
                      trailing: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _textColor,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.grey.shade300, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                      ),
                      onTap: () => _openColorPicker(
                          'Ana Metin Rengi', _textColor, (c) => _textColor = c),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'PAPER STYLE AYARLARI',
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
                child: Column(
                  children: [
                    _buildColorTile('Arka Plan Rengi', _backgroundColor, (c) => _backgroundColor = c),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 16),
                    _buildColorTile('Kategori Başlık Rengi', _categoryTitleColor, (c) => _categoryTitleColor = c),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 16),
                    _buildColorTile('Kategori Ayırıcı Rengi', _categoryDividerColor, (c) => _categoryDividerColor = c),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 16),
                    _buildColorTile('Ürün İsmi Rengi', _productTitleColor, (c) => _productTitleColor = c),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 16),
                    _buildColorTile('Ürün Fiyat Rengi', _productPriceColor, (c) => _productPriceColor = c),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 16),
                    _buildColorTile('Ürün Açıklama Rengi', _productDescColor, (c) => _productDescColor = c),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 16),
                    _buildColorTile('Noktalı Çizgi Rengi (Ürün Arası)', _pmDottedLineColor, (c) => _pmDottedLineColor = c),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Kategori Ayırıcı Tipi',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87),
                            ),
                          ),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'star', label: Text('Yıldız'), icon: Icon(Icons.star)),
                              ButtonSegment(value: 'line', label: Text('Çizgi'), icon: Icon(Icons.horizontal_rule)),
                            ],
                            selected: {_categoryDividerType},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _categoryDividerType = newSelection.first;
                              });
                            },
                            style: SegmentedButton.styleFrom(
                              backgroundColor: Colors.white,
                              selectedBackgroundColor: Colors.blue.shade50,
                              selectedForegroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kategori Ayırıcı Çizgi Uzunluğu (px)',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _categoryDividerLength,
                                  min: 50,
                                  max: 300,
                                  divisions: 250,
                                  activeColor: Colors.black,
                                  onChanged: (val) {
                                    setState(() {
                                      _categoryDividerLength = val;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${_categoryDividerLength.toInt()}px',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 16),
                    SwitchListTile(
                      title: const Text('Ürün Görsellerini Göster',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87)),
                      subtitle: const Text(
                          'Ürün metninin solunda ürün fotoğrafı (thumbnail) gösterilir.',
                          style:
                              TextStyle(fontSize: 13, color: Colors.black54)),
                      value: _showProductImages,
                      activeColor: Colors.black,
                      onChanged: (val) =>
                          setState(() => _showProductImages = val),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LayoutCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _LayoutCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.blue : Colors.black54,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.blue : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

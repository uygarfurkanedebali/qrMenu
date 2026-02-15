import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DesignSettingsSection extends StatelessWidget {
  final String layoutMode;
  final String fontFamily;
  final bool enableTexture;
  final ValueChanged<String?> onLayoutChanged;
  final ValueChanged<String?> onFontChanged;
  final ValueChanged<bool> onTextureChanged;

  const DesignSettingsSection({
    super.key,
    required this.layoutMode,
    required this.fontFamily,
    required this.enableTexture,
    required this.onLayoutChanged,
    required this.onFontChanged,
    required this.onTextureChanged,
  });

  static const _fontFamilies = [
    'Inter', 'Lora', 'Roboto Mono', 'Dancing Script', 'Roboto',
  ];

  static const _layoutModes = [
    {'value': 'grid', 'label': 'Modern Grid (Resimli)'},
    {'value': 'paper', 'label': 'Paper List (Resimsiz/Minimal)'},
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tasarım Ayarları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Layout Mode
            DropdownButtonFormField<String>(
              value: _layoutModes.any((m) => m['value'] == layoutMode) ? layoutMode : 'grid',
              decoration: const InputDecoration(
                labelText: 'Menü Düzeni',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.view_quilt),
              ),
              items: _layoutModes.map((mode) {
                return DropdownMenuItem(
                  value: mode['value'],
                  child: Text(mode['label']!),
                );
              }).toList(),
              onChanged: onLayoutChanged,
            ),
            const SizedBox(height: 16),

            // Font Family
            DropdownButtonFormField<String>(
              value: _fontFamilies.contains(fontFamily) ? fontFamily : 'Inter',
              decoration: const InputDecoration(
                labelText: 'Yazı Tipi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.font_download),
              ),
              items: _fontFamilies.map((f) {
                return DropdownMenuItem(
                  value: f,
                  child: Text(f, style: GoogleFonts.getFont(f)),
                );
              }).toList(),
              onChanged: onFontChanged,
            ),
            const SizedBox(height: 16),

            // Texture Switch
            SwitchListTile(
              title: const Text('Kağıt Dokusu (Noise)'),
              subtitle: const Text('Arkaplana hafif kumlu kağıt efekti ekler.'),
              value: enableTexture,
              onChanged: onTextureChanged,
              secondary: const Icon(Icons.texture),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

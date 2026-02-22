import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// A sleek, advanced color picker dialog that allows users to pick colors
/// using a large saturation area, a hue slider, HEX input, and quick swatches.
class AdvancedColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final String title;

  const AdvancedColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.title = 'Renk Seç',
  });

  /// Helper to show this picker as a dialog
  static Future<Color?> show(
    BuildContext context, {
    required Color initialColor,
    String title = 'Renk Seç',
  }) {
    return showDialog<Color>(
      context: context,
      builder: (context) {
        Color selectedColor = initialColor;
        return AlertDialog(
          title: Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SingleChildScrollView(
            child: AdvancedColorPicker(
              initialColor: initialColor,
              onColorChanged: (c) => selectedColor = c,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selectedColor),
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
  State<AdvancedColorPicker> createState() => _AdvancedColorPickerState();
}

class _AdvancedColorPickerState extends State<AdvancedColorPicker> {
  late Color _currentColor;

  // Swatches commonly useful for menu designs
  final List<Color> _swatches = const [
    Color(0xFF000000), // Pure Black
    Color(0xFFFFFFFF), // Pure White
    Color(0xFFF9FAFB), // Off-white/Gray
    Color(0xFFFF5722), // Deep Orange
    Color(0xFFE53935), // Red
    Color(0xFF43A047), // Green
    Color(0xFF1E88E5), // Blue
    Color(0xFF8E24AA), // Purple
  ];

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
  }

  void _handleColorChange(Color color) {
    setState(() => _currentColor = color);
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Area: Saturation Rect + Hue Slider + Hex Input + Thumb
        ColorPicker(
          pickerColor: _currentColor,
          onColorChanged: _handleColorChange,
          pickerAreaHeightPercent: 0.7,
          enableAlpha: false,
          displayThumbColor: true,
          hexInputBar: true,
          paletteType: PaletteType.hsv,
          pickerAreaBorderRadius: BorderRadius.circular(12),
          hexInputController: null, // Let the package manage the controller
        ),

        const SizedBox(height: 16),

        // Swatches section
        Text(
          'Hazır Renkler',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _swatches.map((swatchColor) {
            final isSelected = _currentColor.value == swatchColor.value;
            return GestureDetector(
              onTap: () => _handleColorChange(swatchColor),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: swatchColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

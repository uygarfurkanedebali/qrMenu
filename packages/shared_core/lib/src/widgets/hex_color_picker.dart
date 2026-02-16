/// HexColorPicker — Shared reusable color picker widget
///
/// Row layout: circle preview + editable HEX TextField.
/// Tap circle → opens a dialog with preset swatches + custom HEX.
library;

import 'package:flutter/material.dart';

/// A minimalist color picker with inline HEX editing and a popup swatch grid.
class HexColorPicker extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final String label;

  const HexColorPicker({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.label = '',
  });

  @override
  State<HexColorPicker> createState() => _HexColorPickerState();
}

class _HexColorPickerState extends State<HexColorPicker> {
  late TextEditingController _hexController;
  late Color _currentColor;

  // 18 curated presets
  static const List<Color> _presets = [
    Color(0xFFFF5722), Color(0xFFE91E63), Color(0xFF9C27B0),
    Color(0xFF673AB7), Color(0xFF3F51B5), Color(0xFF2196F3),
    Color(0xFF03A9F4), Color(0xFF00BCD4), Color(0xFF009688),
    Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39),
    Color(0xFFFFEB3B), Color(0xFFFFC107), Color(0xFFFF9800),
    Color(0xFF795548), Color(0xFF607D8B), Color(0xFF000000),
    Color(0xFFFFFFFF), Color(0xFFF5F5F5), Color(0xFF212121),
  ];

  @override
  void initState() {
    super.initState();
    _currentColor = widget.color;
    _hexController = TextEditingController(text: _colorToHex(_currentColor));
  }

  @override
  void didUpdateWidget(covariant HexColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      _currentColor = widget.color;
      _hexController.text = _colorToHex(_currentColor);
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) {
    return '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  Color? _hexToColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '').trim();
      if (cleaned.length == 6) {
        return Color(int.parse('FF$cleaned', radix: 16));
      }
      if (cleaned.length == 8) {
        return Color(int.parse(cleaned, radix: 16));
      }
    } catch (_) {}
    return null;
  }

  void _onHexChanged(String value) {
    final parsed = _hexToColor(value);
    if (parsed != null) {
      setState(() => _currentColor = parsed);
      widget.onColorChanged(parsed);
    }
  }

  void _onSwatchSelected(Color color) {
    setState(() {
      _currentColor = color;
      _hexController.text = _colorToHex(color);
    });
    widget.onColorChanged(color);
  }

  Future<void> _openPickerDialog() async {
    Color dialogColor = _currentColor;
    final dialogHexCtrl = TextEditingController(text: _colorToHex(dialogColor));

    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              widget.label.isNotEmpty ? widget.label : 'Renk Seç',
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current color preview
                  Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: dialogColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Preset grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presets.map((preset) {
                      final isSelected = preset.value == dialogColor.value;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            dialogColor = preset;
                            dialogHexCtrl.text = _colorToHex(preset);
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: preset,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(Icons.check, size: 16,
                                  color: preset.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // HEX Input
                  TextField(
                    controller: dialogHexCtrl,
                    style: const TextStyle(color: Colors.black87, fontFamily: 'monospace', fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'HEX Kodu',
                      labelStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black, width: 1.5),
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(10),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: dialogColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                    onChanged: (val) {
                      final c = _hexToColor(val);
                      if (c != null) {
                        setDialogState(() => dialogColor = c);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal', style: TextStyle(color: Colors.black54)),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, dialogColor),
                style: FilledButton.styleFrom(backgroundColor: Colors.black),
                child: const Text('Seç'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      _onSwatchSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            // Circle preview (tap to open dialog)
            GestureDetector(
              onTap: _openPickerDialog,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _currentColor.withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Editable HEX text field
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _hexController,
                  style: const TextStyle(color: Colors.black87, fontFamily: 'monospace', fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                  ),
                  onChanged: _onHexChanged,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

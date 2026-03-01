/// Product Detail Bottom Sheet
///
/// Shows product image, description, variant selection,
/// ingredient removal options, and quantity selector.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_core/shared_core.dart';
import '../domain/menu_models.dart';
import '../../cart/application/cart_provider.dart';
import '../../cart/domain/cart_model.dart';

/// Shows a product detail bottom sheet
void showProductDetailSheet(
  BuildContext context, {
  required MenuProduct product,
  required Tenant tenant,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProductDetailSheet(product: product, tenant: tenant),
  );
}

class ProductDetailSheet extends ConsumerStatefulWidget {
  final MenuProduct product;
  final Tenant tenant;

  const ProductDetailSheet({
    super.key,
    required this.product,
    required this.tenant,
  });

  @override
  ConsumerState<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends ConsumerState<ProductDetailSheet> {
  late ProductVariant? _selectedVariant;
  int _quantity = 1;
  late List<String> _removedIngredients;

  @override
  void initState() {
    super.initState();
    // Default: first variant selected (if any)
    final variants = widget.product.variants;
    _selectedVariant = (variants != null && variants.isNotEmpty) ? variants.first : null;
    _removedIngredients = [];
  }

  double get _unitPrice => _selectedVariant?.price ?? widget.product.price;
  double get _totalPrice => _unitPrice * _quantity;

  void _addToCart() {
    final item = CartItem(
      product: widget.product,
      variant: _selectedVariant,
      quantity: _quantity,
      removedIngredients: List.unmodifiable(_removedIngredients),
    );
    ref.read(cartProvider.notifier).addCartItem(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final tenant = widget.tenant;
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;
    final hasVariants = product.variants != null && product.variants!.isNotEmpty;
    final hasIngredients = product.ingredients.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Scrollable Content ──
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. ÜRÜN GÖRSELİ
                  if (hasImage)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: Image.network(
                        product.imageUrl!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 220,
                          color: Colors.grey.shade100,
                          child: Icon(Icons.restaurant, size: 64, color: Colors.grey.shade300),
                        ),
                      ),
                    ),

                  // 2. BAŞLIK & AÇIKLAMA
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (product.emoji != null && product.emoji!.isNotEmpty) ...[
                              Text(product.emoji!, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                product.name,
                                style: GoogleFonts.lora(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!hasVariants)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${product.price.toStringAsFixed(0)} ${tenant.currencySymbol}',
                              style: GoogleFonts.lora(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        if (product.description != null && product.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              product.description!,
                              style: GoogleFonts.lora(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                                height: 1.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 3. VARYANT SEÇİMİ
                  if (hasVariants) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Text(
                        'Boyut / Gramaj',
                        style: GoogleFonts.lora(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: product.variants!.map((variant) {
                          final isSelected = _selectedVariant?.name == variant.name;
                          return ChoiceChip(
                            label: Text(
                              '${variant.name} — ${variant.price.toStringAsFixed(0)} ${tenant.currencySymbol}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedVariant = variant),
                            selectedColor: Colors.black87,
                            backgroundColor: Colors.grey.shade100,
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : Colors.grey.shade300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            showCheckmark: false,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // 4. MALZEMELER (İçindekiler)
                  if (hasIngredients) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Text(
                        'İçindekiler',
                        style: GoogleFonts.lora(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                      child: Column(
                        children: product.ingredients.map((ingredient) {
                          final isRemoved = _removedIngredients.contains(ingredient);
                          return CheckboxListTile(
                            value: !isRemoved,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _removedIngredients.remove(ingredient);
                                } else {
                                  _removedIngredients.add(ingredient);
                                }
                              });
                            },
                            title: Text(
                              ingredient,
                              style: TextStyle(
                                fontSize: 15,
                                color: isRemoved ? Colors.grey : Colors.black87,
                                decoration: isRemoved
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                            activeColor: const Color(0xFF25D366),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── STICKY ALT BAR ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // ADET SEÇİCİ
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(9),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Icon(
                              Icons.remove,
                              size: 18,
                              color: _quantity > 1 ? Colors.black87 : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 36),
                          alignment: Alignment.center,
                          child: Text(
                            '$_quantity',
                            style: GoogleFonts.lora(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _quantity++),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(9),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Icon(Icons.add, size: 18, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // SEPETE EKLE BUTONU
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _addToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Sepete Ekle — ${_totalPrice.toStringAsFixed(0)} ${tenant.currencySymbol}',
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

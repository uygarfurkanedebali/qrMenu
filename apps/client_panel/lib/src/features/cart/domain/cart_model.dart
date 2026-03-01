/// Cart Item Model
/// 
/// Represents an item in the shopping cart with quantity and optional variant.
library;

import 'package:shared_core/shared_core.dart';
import '../../menu/domain/menu_models.dart';

/// Represents a product in the cart with quantity and optional variant
class CartItem {
  final MenuProduct product;
  final ProductVariant? variant;
  final int quantity;

  const CartItem({
    required this.product,
    this.variant,
    this.quantity = 1,
  });

  /// Unique key combining product id and variant name for deduplication
  String get uniqueKey => variant != null
      ? '${product.id}_${variant!.name}'
      : product.id;

  /// Total price for this item (variant price or product price × quantity)
  double get totalPrice => ((variant?.price ?? product.price)) * quantity;

  /// Display name including variant if present
  String get displayName => variant != null
      ? '${product.name} (${variant!.name})'
      : product.name;

  /// Creates a copy with updated fields
  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      variant: variant,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          uniqueKey == other.uniqueKey;

  @override
  int get hashCode => uniqueKey.hashCode;

  @override
  String toString() => 'CartItem(${displayName} × $quantity)';
}

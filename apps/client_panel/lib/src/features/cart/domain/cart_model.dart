/// Cart Item Model
/// 
/// Represents an item in the shopping cart with quantity,
/// optional variant, and removed ingredients.
library;

import 'package:shared_core/shared_core.dart';
import '../../menu/domain/menu_models.dart';

/// Represents a product in the cart with quantity and customizations
class CartItem {
  final MenuProduct product;
  final ProductVariant? variant;
  final int quantity;
  final List<String> removedIngredients;

  const CartItem({
    required this.product,
    this.variant,
    this.quantity = 1,
    this.removedIngredients = const [],
  });

  /// Unique key combining product id, variant name, and removed ingredients
  /// Same product with different ingredient removals = separate cart lines
  String get uniqueKey {
    final base = variant != null
        ? '${product.id}_${variant!.name}'
        : product.id;
    if (removedIngredients.isEmpty) return base;
    final sorted = List<String>.from(removedIngredients)..sort();
    return '${base}_ex:${sorted.join(',')}';
  }

  /// Total price for this item (variant price or product price × quantity)
  double get totalPrice => ((variant?.price ?? product.price)) * quantity;

  /// Display name including variant if present
  String get displayName => variant != null
      ? '${product.name} (${variant!.name})'
      : product.name;

  /// Creates a copy with updated fields
  CartItem copyWith({
    int? quantity,
    List<String>? removedIngredients,
  }) {
    return CartItem(
      product: product,
      variant: variant,
      quantity: quantity ?? this.quantity,
      removedIngredients: removedIngredients ?? this.removedIngredients,
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

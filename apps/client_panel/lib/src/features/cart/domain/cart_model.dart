/// Cart Item Model
/// 
/// Represents an item in the shopping cart with quantity.
library;

import '../../menu/domain/menu_models.dart';

/// Represents a product in the cart with quantity
class CartItem {
  final MenuProduct product;
  final int quantity;

  const CartItem({
    required this.product,
    this.quantity = 1,
  });

  /// Total price for this item (price × quantity)
  double get totalPrice => product.price * quantity;

  /// Creates a copy with updated quantity
  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          product.id == other.product.id;

  @override
  int get hashCode => product.id.hashCode;

  @override
  String toString() => 'CartItem(${product.name} × $quantity)';
}

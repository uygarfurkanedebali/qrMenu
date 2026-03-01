/// Cart Provider
/// 
/// State management for the shopping cart using Riverpod.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../../menu/domain/menu_models.dart';
import '../domain/cart_model.dart';

/// Main cart state provider using Notifier
final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});

/// Cart state notifier handling all cart operations
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return []; // Start with empty cart
  }

  /// Generates a unique key for product + variant combination
  String _itemKey(MenuProduct product, ProductVariant? variant) {
    return variant != null ? '${product.id}_${variant.name}' : product.id;
  }

  /// Adds a product (optionally with variant) to cart or increments quantity
  void addItem(MenuProduct product, {ProductVariant? variant}) {
    final key = _itemKey(product, variant);
    final existingIndex = state.indexWhere((item) => item.uniqueKey == key);
    
    if (existingIndex >= 0) {
      // Product exists, increment quantity
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i],
      ];
    } else {
      // New product, add to cart
      state = [...state, CartItem(product: product, variant: variant)];
    }
  }

  /// Decrements quantity or removes if quantity becomes 0
  void removeItem(MenuProduct product, {ProductVariant? variant}) {
    final key = _itemKey(product, variant);
    final existingIndex = state.indexWhere((item) => item.uniqueKey == key);
    
    if (existingIndex < 0) return;
    
    final currentItem = state[existingIndex];
    
    if (currentItem.quantity <= 1) {
      // Remove entirely
      state = state.where((item) => item.uniqueKey != key).toList();
    } else {
      // Decrement quantity
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity - 1)
          else
            state[i],
      ];
    }
  }

  /// Removes a product entirely from cart
  void removeProductEntirely(MenuProduct product, {ProductVariant? variant}) {
    final key = _itemKey(product, variant);
    state = state.where((item) => item.uniqueKey != key).toList();
  }

  /// Updates quantity for a specific product
  void updateQuantity(MenuProduct product, int quantity, {ProductVariant? variant}) {
    if (quantity <= 0) {
      removeProductEntirely(product, variant: variant);
      return;
    }
    
    final key = _itemKey(product, variant);
    state = [
      for (final item in state)
        if (item.uniqueKey == key)
          item.copyWith(quantity: quantity)
        else
          item,
    ];
  }

  /// Returns quantity of a specific product+variant in cart
  int getQuantity(MenuProduct product, {ProductVariant? variant}) {
    final key = variant != null ? '${product.id}_${variant.name}' : product.id;
    final item = state.where((item) => item.uniqueKey == key).firstOrNull;
    return item?.quantity ?? 0;
  }

  /// Clears all items from cart
  void clearCart() {
    state = [];
  }
}

/// Computed provider for cart total price
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
});

/// Computed provider for total item count (with quantities)
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

/// Computed provider for unique product count
final cartUniqueItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.length;
});

/// Check if cart is empty
final isCartEmptyProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider).isEmpty;
});

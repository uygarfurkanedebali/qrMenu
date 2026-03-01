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

  /// Adds a fully configured CartItem to cart
  /// If an item with the same uniqueKey (product + variant + removedIngredients)
  /// already exists, increments its quantity by [quantity].
  void addCartItem(CartItem item) {
    final existingIndex = state.indexWhere((i) => i.uniqueKey == item.uniqueKey);
    
    if (existingIndex >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + item.quantity)
          else
            state[i],
      ];
    } else {
      state = [...state, item];
    }
  }

  /// Legacy helper: add product with optional variant (no ingredient removal)
  void addItem(MenuProduct product, {ProductVariant? variant}) {
    addCartItem(CartItem(product: product, variant: variant));
  }

  /// Decrements quantity or removes if quantity becomes 0
  void removeItem(MenuProduct product, {ProductVariant? variant}) {
    final key = variant != null ? '${product.id}_${variant.name}' : product.id;
    final existingIndex = state.indexWhere((item) => item.uniqueKey == key);
    
    if (existingIndex < 0) return;
    
    final currentItem = state[existingIndex];
    
    if (currentItem.quantity <= 1) {
      state = state.where((item) => item.uniqueKey != key).toList();
    } else {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity - 1)
          else
            state[i],
      ];
    }
  }

  /// Removes a cart item entirely by its uniqueKey
  void removeByKey(String uniqueKey) {
    state = state.where((item) => item.uniqueKey != uniqueKey).toList();
  }

  /// Removes a product entirely from cart
  void removeProductEntirely(MenuProduct product, {ProductVariant? variant}) {
    final key = variant != null ? '${product.id}_${variant.name}' : product.id;
    state = state.where((item) => item.uniqueKey != key).toList();
  }

  /// Updates quantity for a specific product
  void updateQuantity(MenuProduct product, int quantity, {ProductVariant? variant}) {
    if (quantity <= 0) {
      removeProductEntirely(product, variant: variant);
      return;
    }
    final key = variant != null ? '${product.id}_${variant.name}' : product.id;
    state = [
      for (final item in state)
        if (item.uniqueKey == key)
          item.copyWith(quantity: quantity)
        else
          item,
    ];
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

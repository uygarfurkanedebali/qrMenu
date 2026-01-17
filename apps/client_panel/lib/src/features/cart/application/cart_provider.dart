/// Cart Provider
/// 
/// State management for the shopping cart using Riverpod.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Adds a product to cart or increments quantity if exists
  void addItem(MenuProduct product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    
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
      state = [...state, CartItem(product: product)];
    }
  }

  /// Decrements quantity or removes if quantity becomes 0
  void removeItem(MenuProduct product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex < 0) return;
    
    final currentItem = state[existingIndex];
    
    if (currentItem.quantity <= 1) {
      // Remove entirely
      state = state.where((item) => item.product.id != product.id).toList();
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
  void removeProductEntirely(MenuProduct product) {
    state = state.where((item) => item.product.id != product.id).toList();
  }

  /// Updates quantity for a specific product
  void updateQuantity(MenuProduct product, int quantity) {
    if (quantity <= 0) {
      removeProductEntirely(product);
      return;
    }
    
    state = [
      for (final item in state)
        if (item.product.id == product.id)
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

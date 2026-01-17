/// Cart Provider Unit Tests
/// 
/// Tests for CartNotifier following Zero Trust protocol.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_panel/src/features/cart/application/cart_provider.dart';
import 'package:client_panel/src/features/menu/domain/menu_models.dart';

void main() {
  group('CartNotifier', () {
    late ProviderContainer container;

    // Sample test products
    final testProduct1 = MenuProduct(
      id: 'prod-1',
      tenantId: 'tenant-1',
      categoryId: 'cat-1',
      name: 'Test Kebab',
      price: 10.99,
    );

    final testProduct2 = MenuProduct(
      id: 'prod-2',
      tenantId: 'tenant-1',
      categoryId: 'cat-1',
      name: 'Test Coffee',
      price: 5.49,
    );

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty cart', () {
      final cart = container.read(cartProvider);
      expect(cart, isEmpty);
    });

    test('addItem adds product to cart', () {
      container.read(cartProvider.notifier).addItem(testProduct1);

      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.product.id, 'prod-1');
      expect(cart.first.quantity, 1);
    });

    test('addItem same product twice increases quantity', () {
      container.read(cartProvider.notifier).addItem(testProduct1);
      container.read(cartProvider.notifier).addItem(testProduct1);

      final cart = container.read(cartProvider);
      expect(cart.length, 1); // Still only one item
      expect(cart.first.quantity, 2); // Quantity increased
    });

    test('addItem different products creates separate items', () {
      container.read(cartProvider.notifier).addItem(testProduct1);
      container.read(cartProvider.notifier).addItem(testProduct2);

      final cart = container.read(cartProvider);
      expect(cart.length, 2);
    });

    test('removeItem decreases quantity', () {
      container.read(cartProvider.notifier).addItem(testProduct1);
      container.read(cartProvider.notifier).addItem(testProduct1);
      container.read(cartProvider.notifier).removeItem(testProduct1);

      final cart = container.read(cartProvider);
      expect(cart.first.quantity, 1);
    });

    test('removeItem removes product when quantity reaches 0', () {
      container.read(cartProvider.notifier).addItem(testProduct1);
      container.read(cartProvider.notifier).removeItem(testProduct1);

      final cart = container.read(cartProvider);
      expect(cart, isEmpty);
    });

    test('clearCart empties all items', () {
      container.read(cartProvider.notifier).addItem(testProduct1);
      container.read(cartProvider.notifier).addItem(testProduct2);
      container.read(cartProvider.notifier).clearCart();

      final cart = container.read(cartProvider);
      expect(cart, isEmpty);
    });

    test('cartTotalProvider calculates correct total', () {
      container.read(cartProvider.notifier).addItem(testProduct1); // 10.99
      container.read(cartProvider.notifier).addItem(testProduct1); // 10.99 (qty: 2)
      container.read(cartProvider.notifier).addItem(testProduct2); // 5.49

      final total = container.read(cartTotalProvider);
      expect(total, closeTo(27.47, 0.01)); // 10.99 * 2 + 5.49
    });

    test('cartItemCountProvider counts all items with quantities', () {
      container.read(cartProvider.notifier).addItem(testProduct1);
      container.read(cartProvider.notifier).addItem(testProduct1);
      container.read(cartProvider.notifier).addItem(testProduct2);

      final count = container.read(cartItemCountProvider);
      expect(count, 3); // 2 kebabs + 1 coffee
    });

    test('isCartEmptyProvider returns true for empty cart', () {
      expect(container.read(isCartEmptyProvider), true);
      
      container.read(cartProvider.notifier).addItem(testProduct1);
      expect(container.read(isCartEmptyProvider), false);
      
      container.read(cartProvider.notifier).clearCart();
      expect(container.read(isCartEmptyProvider), true);
    });

    test('updateQuantity sets specific quantity', () {
      container.read(cartProvider.notifier).addItem(testProduct1);
      container.read(cartProvider.notifier).updateQuantity(testProduct1, 5);

      final cart = container.read(cartProvider);
      expect(cart.first.quantity, 5);
    });

    test('updateQuantity with 0 removes item', () {
      container.read(cartProvider.notifier).addItem(testProduct1);
      container.read(cartProvider.notifier).updateQuantity(testProduct1, 0);

      final cart = container.read(cartProvider);
      expect(cart, isEmpty);
    });
  });
}

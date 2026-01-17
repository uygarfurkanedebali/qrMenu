/// Cart Widget Tests
/// 
/// Widget tests for Cart UI components.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_panel/src/features/cart/domain/cart_model.dart';
import 'package:client_panel/src/features/menu/domain/menu_models.dart';

void main() {
  group('CartItem Model', () {
    final testProduct = MenuProduct(
      id: 'prod-1',
      tenantId: 'tenant-1',
      categoryId: 'cat-1',
      name: 'Test Product',
      price: 10.00,
    );

    test('totalPrice calculates correctly', () {
      final item = CartItem(product: testProduct, quantity: 3);
      expect(item.totalPrice, 30.00);
    });

    test('copyWith updates quantity', () {
      final item = CartItem(product: testProduct, quantity: 1);
      final updated = item.copyWith(quantity: 5);
      
      expect(updated.quantity, 5);
      expect(updated.product.id, item.product.id);
    });

    test('equality based on product id', () {
      final item1 = CartItem(product: testProduct, quantity: 1);
      final item2 = CartItem(product: testProduct, quantity: 5);
      
      expect(item1, equals(item2)); // Same product ID
    });

    test('default quantity is 1', () {
      final item = CartItem(product: testProduct);
      expect(item.quantity, 1);
    });
  });

  group('MenuProduct Model', () {
    test('formattedPrice returns correct format', () {
      final product = MenuProduct(
        id: 'p1',
        tenantId: 't1',
        categoryId: 'c1',
        name: 'Test',
        price: 12.50,
      );
      
      expect(product.formattedPrice, '\$12.50');
    });

    test('default values are correct', () {
      final product = MenuProduct(
        id: 'p1',
        tenantId: 't1',
        categoryId: 'c1',
        name: 'Test',
        price: 10.00,
      );
      
      expect(product.isAvailable, true);
      expect(product.isPopular, false);
      expect(product.tags, isEmpty);
    });
  });
}

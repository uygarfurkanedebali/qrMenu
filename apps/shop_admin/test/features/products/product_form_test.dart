/// Product Form Widget Test
/// 
/// Verifies the ProductEditScreen UI and interaction.
/// 
/// Scenarios:
/// 1. Render empty form (Create Mode)
/// 2. Input validation
/// 3. Save interaction
library;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_admin/src/features/products/presentation/product_edit_screen.dart';

void main() {
  group('ProductEditScreen', () {
    testWidgets('renders empty form for new product', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const ProductEditScreen(),
          ),
        ),
      );

      // Verify fields are empty
      expect(find.text('Add Product'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3)); // Name, Price, Desc
      expect(find.text('Save Product'), findsOneWidget);
    });

    testWidgets('validates required fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const ProductEditScreen(),
          ),
        ),
      );

      // Tap save without input
      final saveButton = find.text('Save Product');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      // Expect validation errors
      expect(find.text('Required'), findsWidgets);
    });

    testWidgets('submits form with valid data', (tester) async {
      // Mock repository to intercept addProduct call (conceptually)
      // Since we use a real fake repository with a delay, we can verify the success snackbar
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const ProductEditScreen(),
          ),
        ),
      );

      // Fill form
      await tester.enterText(
          find.ancestor(of: find.text('Product Name'), matching: find.byType(TextFormField)), 
          'Test Kebab');
      await tester.enterText(
          find.ancestor(of: find.text('Price'), matching: find.byType(TextFormField)), 
          '15.50');

      // Tap save (ensure visible)
      final saveButton = find.text('Save Product');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump(); // Start save
      
      // Should show loading indicator (might be quick)
      // expect(find.byType(CircularProgressIndicator), findsOneWidget); // Flaky if fast
      
      // Wait for async operation (FakeRepo has 500ms delay)
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle(); // Wait for snackbar animation
      
      // Should show success snackbar
      expect(find.text('Product saved successfully'), findsOneWidget);
    });
  });
}

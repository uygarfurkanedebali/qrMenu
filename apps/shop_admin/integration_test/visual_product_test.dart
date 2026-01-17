/// Visual Product Test
/// 
/// Integration test designed to be watched by a human.
/// Includes intentional delays to demonstrate functionality.
library;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shop_admin/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Visual Product Form Test', () {
    testWidgets('Demo: Add Product Flow', (tester) async {
      // 1. App Starts
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 2. Navigate to Products
      // Find "Products" in sidebar and tap
      final productsLink = find.text('Products');
      expect(productsLink, findsOneWidget); // Ensure we are on a screen where sidebar is visible
      await tester.tap(productsLink);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 3. Navigate to /products/new
      // Find "Add" icon button
      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle(const Duration(seconds: 2)); // Wait so user can see empty form

      // 4. Type Name
      final nameField = find.ancestor(
        of: find.text('Product Name'), 
        matching: find.byType(TextFormField)
      );
      await tester.enterText(nameField, 'Visual Test Kebab');
      await tester.pumpAndSettle(const Duration(seconds: 1)); // Wait so user can read it

      // 5. Type Price
      final priceField = find.ancestor(
        of: find.text('Price'), 
        matching: find.byType(TextFormField)
      );
      await tester.enterText(priceField, '999');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 6. Tap Save
      await tester.tap(find.text('Save Product'));
      await tester.pump(); // Start save animation
      
      // 7. Watch processing
      await tester.pump(const Duration(seconds: 3)); // Wait for mock delay + visual confirmation
      await tester.pumpAndSettle(); // Settle any snackbars

      // 8. Verify Success (Optional for visual test, but good practice)
      expect(find.text('Product saved successfully'), findsOneWidget);
      
      await tester.pumpAndSettle(const Duration(seconds: 2)); // Lingering look
    });
  });
}

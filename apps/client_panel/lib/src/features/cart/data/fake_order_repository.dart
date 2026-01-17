/// Fake Order Repository
/// 
/// Mock order submission for development.
library;

/// Order submission result
class OrderResult {
  final String orderId;
  final bool success;
  final String message;

  const OrderResult({
    required this.orderId,
    required this.success,
    required this.message,
  });
}

/// Mock order repository
class FakeOrderRepository {
  /// Simulates submitting an order
  static Future<OrderResult> submitOrder({
    required String tenantId,
    required double totalAmount,
    required int itemCount,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Generate a fake order ID
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
    
    // For demo, always succeed
    return OrderResult(
      orderId: orderId,
      success: true,
      message: 'Order placed successfully! Your order number is $orderId',
    );
  }
}

/// Extended Category model with nested products
/// 
/// This model extends the shared_core Category to include
/// a list of products for menu rendering.
library;

/// Category with nested products for menu display
class MenuCategory {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final String? iconUrl;
  final String? parentId;
  final int sortOrder;
  final List<MenuProduct> products;

  const MenuCategory({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    this.iconUrl,
    this.parentId,
    this.sortOrder = 0,
    required this.products,
  });
}

/// Product for menu display with extended fields
class MenuProduct {
  final String id;
  final String tenantId;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final bool isPopular;
  final int sortOrder;
  final List<String> tags;

  const MenuProduct({
    required this.id,
    required this.tenantId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.isPopular = false,
    this.sortOrder = 0,
    this.tags = const [],
  });

  /// Formatted price string
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
}

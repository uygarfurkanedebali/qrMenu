/// Product model for menu items
/// 
/// Products are the core menu items displayed to customers.
/// Each product belongs to exactly one tenant (multi-tenant isolation)
/// and optionally belongs to a category.
library;

/// Represents a product/menu item
class Product {
  final String id;
  final String tenantId;
  final String? categoryId; // Deprecated (Transitioning to M-to-M)
  final List<String> categoryIds; // New Field (Phase 1)
  final String name;
  final String? description;
  final String? emoji;
  final List<ProductVariant>? variants;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.tenantId,
    this.categoryId,
    this.categoryIds = const [], // Default empty
    required this.name,
    this.description,
    this.emoji,
    this.variants,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(price >= 0, 'Price must be non-negative');

  /// Creates a Product from JSON (database response)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      categoryId: json['category_id'] as String?,
      // Extract IDs from joined product_categories table if present
      categoryIds: (json['product_categories'] as List<dynamic>?)
              ?.map((e) => e['category_id'] as String)
              .toList() ??
          [],
      name: json['name'] as String,
      description: json['description'] as String?,
      emoji: json['emoji'] as String?,
      variants: (json['variants'] as List<dynamic>?)
          ?.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts the Product to JSON for database insertion
  /// Does NOT include 'id' - let database auto-generate UUID
  Map<String, dynamic> toJsonForInsert() => {
        'tenant_id': tenantId,
        // Only include category_id if it's a valid non-empty string
        if (categoryId != null && categoryId!.isNotEmpty) 'category_id': categoryId,
        'name': name,
        'description': description,
        if (emoji != null && emoji!.isNotEmpty) 'emoji': emoji,
        if (variants != null && variants!.isNotEmpty) 
          'variants': variants!.map((v) => v.toJson()).toList(),
        'price': price,
        'image_url': imageUrl,
        'is_available': isAvailable,
        'sort_order': sortOrder,
      };

  /// Converts the Product to JSON for updates (includes id)
  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        // Only include category_id if it's a valid non-empty string
        if (categoryId != null && categoryId!.isNotEmpty) 'category_id': categoryId,
        'name': name,
        'description': description,
        if (emoji != null && emoji!.isNotEmpty) 'emoji': emoji,
        if (variants != null && variants!.isNotEmpty) 
          'variants': variants!.map((v) => v.toJson()).toList(),
        'price': price,
        'image_url': imageUrl,
        'is_available': isAvailable,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Returns formatted price string
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  /// Creates a copy with modified properties
  Product copyWith({
    String? id,
    String? tenantId,
    String? categoryId,
    List<String>? categoryIds,
    String? name,
    String? description,
    String? emoji,
    List<ProductVariant>? variants,
    double? price,
    String? imageUrl,
    bool? isAvailable,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      categoryId: categoryId ?? this.categoryId,
      categoryIds: categoryIds ?? this.categoryIds,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      variants: variants ?? this.variants,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, price: $formattedPrice)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a product variant (e.g. grammage, size)
class ProductVariant {
  final String name;
  final double price;

  const ProductVariant({
    required this.name,
    required this.price,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
  };
}

/// Category model for product grouping
/// 
/// Categories organize products within a tenant's menu.
/// Each category belongs to exactly one tenant (multi-tenant isolation).
library;

/// Represents a product category in the menu
class Category {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? parentId;
  final int sortOrder;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    this.imageUrl,
    this.parentId,
    this.sortOrder = 0,
    this.isVisible = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a Category from JSON (database response)
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      parentId: json['parent_id'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isVisible: json['is_visible'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts the Category to JSON for database insertion
  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'parent_id': parentId,
        'sort_order': sortOrder,
        'is_visible': isVisible,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Creates a copy with modified properties
  Category copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? description,
    String? imageUrl,
    String? parentId,
    bool clearParentId = false,
    int? sortOrder,
    bool? isVisible,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      sortOrder: sortOrder ?? this.sortOrder,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name, parentId: $parentId, sortOrder: $sortOrder)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

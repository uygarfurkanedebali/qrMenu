/// Tenant model for shop/restaurant representation
/// 
/// Tenants are the core multi-tenant entities.
library;

import 'theme_config.dart';

class Tenant {
  final String id;
  final String name;
  final String slug;
  final String? ownerEmail;
  final ThemeConfig? themeConfig;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tenant({
    required this.id,
    required this.name,
    required this.slug,
    this.ownerEmail,
    this.themeConfig,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      ownerEmail: json['owner_email'] as String?,
      themeConfig: json['theme_config'] != null
          ? ThemeConfig.fromJson(json['theme_config'])
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'owner_email': ownerEmail,
        'theme_config': themeConfig?.toJson(),
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Tenant copyWith({
    String? id,
    String? name,
    String? slug,
    String? ownerEmail,
    ThemeConfig? themeConfig,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      themeConfig: themeConfig ?? this.themeConfig,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Tenant(id: $id, name: $name, slug: $slug)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tenant && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

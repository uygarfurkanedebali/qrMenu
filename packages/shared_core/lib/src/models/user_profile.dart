/// User Profile Model
/// 
/// Represents a row from public.profiles table.
/// Used for RBAC role checking across the app.
library;

/// User roles in the system
enum UserRole {
  admin,
  shopOwner,
  customer;

  /// Parse from database string value
  static UserRole fromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'shop_owner':
        return UserRole.shopOwner;
      case 'customer':
        return UserRole.customer;
      default:
        return UserRole.customer;
    }
  }

  /// Convert to database string value
  String toDbString() {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.shopOwner:
        return 'shop_owner';
      case UserRole.customer:
        return 'customer';
    }
  }

  /// Display name for UI
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'System Admin';
      case UserRole.shopOwner:
        return 'Shop Owner';
      case UserRole.customer:
        return 'Customer';
    }
  }
}

/// Represents a user profile from public.profiles
class UserProfile {
  final String id;
  final String? email;
  final UserRole role;
  final String? fullName;
  final String? tenantId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    this.email,
    required this.role,
    this.fullName,
    this.tenantId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a UserProfile from JSON (database response)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'customer'),
      fullName: json['full_name'] as String?,
      tenantId: json['tenant_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role.toDbString(),
        'full_name': fullName,
        'tenant_id': tenantId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  bool get isAdmin => role == UserRole.admin;
  bool get isShopOwner => role == UserRole.shopOwner;
  bool get isCustomer => role == UserRole.customer;

  @override
  String toString() => 'UserProfile(id: $id, email: $email, role: ${role.displayName})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

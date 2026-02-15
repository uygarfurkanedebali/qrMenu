library;

class Tenant {
  final String id;
  final String name;
  final String slug;
  final String? ownerEmail;
  final String? bannerUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Settings
  final String primaryColor;
  final String fontFamily;
  final String currencySymbol;
  final String? phoneNumber;
  final String? instagramHandle;
  final String? wifiName;
  final String? wifiPassword;
  
  // NEW: Design Configuration
  final Map<String, dynamic> designConfig;

  const Tenant({
    required this.id,
    required this.name,
    required this.slug,
    this.ownerEmail,
    this.bannerUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.primaryColor = '#FF5722',
    this.fontFamily = 'Roboto',
    this.currencySymbol = '₺',
    this.phoneNumber,
    this.instagramHandle,
    this.wifiName,
    this.wifiPassword,
    this.designConfig = const {},
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      ownerEmail: json['owner_email'] as String?,
      bannerUrl: json['banner_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      primaryColor: json['primary_color'] as String? ?? '#FF5722',
      fontFamily: json['font_family'] as String? ?? 'Roboto',
      currencySymbol: json['currency_symbol'] as String? ?? '₺',
      phoneNumber: json['phone_number'] as String?,
      instagramHandle: json['instagram_handle'] as String?,
      wifiName: json['wifi_name'] as String?,
      wifiPassword: json['wifi_password'] as String?,
      designConfig: json['design_config'] != null
          ? Map<String, dynamic>.from(json['design_config'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'owner_email': ownerEmail,
    'banner_url': bannerUrl,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'primary_color': primaryColor,
    'font_family': fontFamily,
    'currency_symbol': currencySymbol,
    'phone_number': phoneNumber,
    'instagram_handle': instagramHandle,
    'wifi_name': wifiName,
    'wifi_password': wifiPassword,
    'design_config': designConfig,
  };

  Tenant copyWith({
    String? id,
    String? name,
    String? slug,
    String? ownerEmail,
    String? bannerUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? primaryColor,
    String? fontFamily,
    String? currencySymbol,
    String? phoneNumber,
    String? instagramHandle,
    String? wifiName,
    String? wifiPassword,
    Map<String, dynamic>? designConfig,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      primaryColor: primaryColor ?? this.primaryColor,
      fontFamily: fontFamily ?? this.fontFamily,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      wifiName: wifiName ?? this.wifiName,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      designConfig: designConfig ?? this.designConfig,
    );
  }
}

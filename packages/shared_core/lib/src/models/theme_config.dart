/// Theme configuration model for multi-tenant theming
/// 
/// This model represents the customizable theme options that shop owners
/// can configure. Only colors and fonts are customizable per business rules.
library;

/// Allowed font families that can be used in themes
enum ThemeFontFamily {
  roboto('Roboto'),
  openSans('Open Sans'),
  lato('Lato'),
  montserrat('Montserrat'),
  poppins('Poppins'),
  inter('Inter'),
  nunito('Nunito'),
  raleway('Raleway');

  const ThemeFontFamily(this.displayName);
  final String displayName;

  /// Parse from string, defaults to Roboto if invalid
  static ThemeFontFamily fromString(String? value) {
    if (value == null) return ThemeFontFamily.roboto;
    return ThemeFontFamily.values.firstWhere(
      (font) => font.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => ThemeFontFamily.roboto,
    );
  }
}

/// Border radius configuration for UI elements
class BorderRadiusConfig {
  final double small;
  final double medium;
  final double large;

  const BorderRadiusConfig({
    this.small = 4.0,
    this.medium = 8.0,
    this.large = 16.0,
  });

  factory BorderRadiusConfig.fromJson(Map<String, dynamic> json) {
    return BorderRadiusConfig(
      small: (json['small'] as num?)?.toDouble() ?? 4.0,
      medium: (json['medium'] as num?)?.toDouble() ?? 8.0,
      large: (json['large'] as num?)?.toDouble() ?? 16.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'small': small,
        'medium': medium,
        'large': large,
      };
}

/// Theme configuration for a tenant's menu
/// 
/// Contains all customizable visual properties that can be
/// modified by shop owners (colors and fonts only, per business rules).
class ThemeConfig {
  final String id;
  final String tenantId;
  final String name;
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final String textColor;
  final ThemeFontFamily fontFamily;
  final BorderRadiusConfig borderRadius;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ThemeConfig({
    this.id = 'default',
    this.tenantId = 'default',
    this.name = 'Default',
    this.primaryColor = '#FF5722',
    this.secondaryColor = '#FFC107',
    this.backgroundColor = '#FFFFFF',
    this.textColor = '#212121',
    this.fontFamily = ThemeFontFamily.roboto,
    this.borderRadius = const BorderRadiusConfig(),
    this.isActive = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Validates a HEX color string
  /// Returns true if valid (format: #RRGGBB or #RGB)
  static bool isValidHexColor(String color) {
    final hexPattern = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return hexPattern.hasMatch(color);
  }

  /// Creates a ThemeConfig from JSON (database response)
  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    // Validate and sanitize colors
    String validateColor(String? color, String defaultColor) {
      if (color == null || !isValidHexColor(color)) {
        return defaultColor;
      }
      return color.toUpperCase();
    }

    return ThemeConfig(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String? ?? 'Default',
      primaryColor: validateColor(json['primary_color'] as String?, '#FF5722'),
      secondaryColor: validateColor(json['secondary_color'] as String?, '#FFC107'),
      backgroundColor: validateColor(json['background_color'] as String?, '#FFFFFF'),
      textColor: validateColor(json['text_color'] as String?, '#212121'),
      fontFamily: ThemeFontFamily.fromString(json['font_family'] as String?),
      borderRadius: json['border_radius_config'] != null
          ? BorderRadiusConfig.fromJson(json['border_radius_config'] as Map<String, dynamic>)
          : const BorderRadiusConfig(),
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts the ThemeConfig to JSON for database insertion
  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'name': name,
        'primary_color': primaryColor,
        'secondary_color': secondaryColor,
        'background_color': backgroundColor,
        'text_color': textColor,
        'font_family': fontFamily.displayName,
        'border_radius_config': borderRadius.toJson(),
        'is_active': isActive,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  /// Creates a copy with modified properties
  ThemeConfig copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? primaryColor,
    String? secondaryColor,
    String? backgroundColor,
    String? textColor,
    ThemeFontFamily? fontFamily,
    BorderRadiusConfig? borderRadius,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ThemeConfig(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontFamily: fontFamily ?? this.fontFamily,
      borderRadius: borderRadius ?? this.borderRadius,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'ThemeConfig(id: $id, name: $name, isActive: $isActive)';
}

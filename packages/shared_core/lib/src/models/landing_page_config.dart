/// Landing Page Configuration Model (CMS)
/// 
/// Represents the dynamic content for the landing page.
/// This is a Singleton model (ID always 1).
library;

class LandingPageConfig {
  final int id;
  final String heroTitle;
  final String heroDescription;
  final List<LandingFeature> features;
  final String? contactEmail;
  final bool isMaintenanceMode;
  final DateTime updatedAt;

  const LandingPageConfig({
    required this.id,
    required this.heroTitle,
    required this.heroDescription,
    this.features = const [],
    this.contactEmail,
    this.isMaintenanceMode = false,
    required this.updatedAt,
  });

  factory LandingPageConfig.fromJson(Map<String, dynamic> json) {
    return LandingPageConfig(
      id: json['id'] as int,
      heroTitle: json['hero_title'] as String,
      heroDescription: json['hero_description'] as String,
      features: (json['features_list'] as List?)
              ?.map((e) => LandingFeature.fromJson(e))
              .toList() ??
          [],
      contactEmail: json['contact_email'] as String?,
      isMaintenanceMode: json['is_maintenance_mode'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hero_title': heroTitle,
        'hero_description': heroDescription,
        'features_list': features.map((e) => e.toJson()).toList(),
        'contact_email': contactEmail,
        'is_maintenance_mode': isMaintenanceMode,
        'updated_at': updatedAt.toIso8601String(),
      };
}

class LandingFeature {
  final String icon;
  final String title;
  final String text;

  const LandingFeature({
    required this.icon,
    required this.title,
    required this.text,
  });

  factory LandingFeature.fromJson(Map<String, dynamic> json) {
    return LandingFeature(
      icon: json['icon'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'icon': icon,
        'title': title,
        'text': text,
      };
}

/// Repository for managing Landing Page CMS content
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/landing_page_config.dart';
import '../services/supabase_service.dart';

class LandingRepository {
  static const String _tableName = 'landing_page_config';
  static const int _singletonId = 1;

  /// Fetches the landing page configuration.
  /// If no config exists, returns a default fallback.
  Future<LandingPageConfig> getLandingConfig() async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('id', _singletonId)
          .maybeSingle();

      if (response == null) {
        // Fallback if DB is empty (should be seeded, but just in case)
        return LandingPageConfig(
          id: _singletonId,
          heroTitle: 'Restoranınızın Dijital Geleceği',
          heroDescription: 'QR-Infinity ile tanışın.',
          updatedAt: DateTime.now(),
        );
      }

      return LandingPageConfig.fromJson(response);
    } catch (e) {
      // Return fallback on error to prevent app crash
      print('❌ [LandingRepository] Fetch Error: $e');
      return LandingPageConfig(
        id: _singletonId,
        heroTitle: 'Restoranınızın Dijital Geleceği',
        heroDescription: 'QR-Infinity ile tanışın. (Offline)',
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Updates the landing page configuration.
  /// Requires authentication (RLS enforced).
  Future<void> updateLandingConfig(LandingPageConfig config, {String? authToken}) async {
    // Note: RLS policies should handle authorization.
    // However, if using REST API directly, authToken injection might be needed.
    // For now, assuming Supabase Client session is active.

    await SupabaseService.client.from(_tableName).upsert(config.toJson());
  }
}

/// Supabase Service
/// 
/// Singleton service for Supabase client initialization and access.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  /// Initialize Supabase (call once at app startup)
  static Future<void> initialize() async {
    if (!Env.isConfigured) {
      throw Exception(
        'Supabase credentials not configured. '
        'Please update shared_core/lib/src/config/env.dart with your keys.',
      );
    }

    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    
    _instance = SupabaseService._();
    _client = Supabase.instance.client;
  }

  /// Get the singleton instance
  static SupabaseService get instance {
    if (_instance == null) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// Get the Supabase client
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _client?.auth.currentUser != null;

  /// Get current user
  User? get currentUser => _client?.auth.currentUser;

  /// Get current session
  Session? get currentSession => _client?.auth.currentSession;
}

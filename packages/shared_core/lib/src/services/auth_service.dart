import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Authentication Service
///
/// Handles user authentication using Supabase.
class AuthService {
  final GoTrueClient _auth;

  AuthService() : _auth = SupabaseService.client.auth;

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await _auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current session
  Session? get currentSession => _auth.currentSession;

  /// Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;
}

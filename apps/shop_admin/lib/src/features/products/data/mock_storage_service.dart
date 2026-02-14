/// Storage Service (REST API Bypass)
/// 
/// Handles file uploading to Supabase Storage using direct HTTP requests.
/// Bypasses Supabase SDK client state to avoid "Ghost Logout" issues.
library;

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_core/shared_core.dart';
import '../../auth/application/auth_provider.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return SupabaseStorageService();
});

/// Interface for storage operations
abstract class StorageService {
  Future<String> uploadImage(XFile file);
}

/// Real Supabase Storage implementation (REST API Version)
class SupabaseStorageService implements StorageService {

  @override
  Future<String> uploadImage(XFile file) async {
    // 1. Get Session manually from ShopAuthService (The Shielded Source of Truth)
    // We bypass Supabase.instance.client.auth because it might be stuck in 'signedOut'
    final session = ShopAuthService.currentSession;
    final accessToken = session?.accessToken;
    final user = session?.user;

    print('\n🚀 STORAGE PHASE 2: HEADER INJECTION (REST API)');
    print('   - Manual Session: ${session != null}');
    print('   - Access Token: ${accessToken != null ? "PRESENT" : "MISSING"}');
    print('   - User ID: ${user?.id}');

    if (accessToken == null || user == null) {
      print('🛑 FATAL: No access token available via ShopAuthService. Cannot upload.');
      throw Exception('User is not logged in (Phase 2 Fail).');
    }

    try {
      // 2. Prepare HTTP Request
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final path = '${user.id}/$fileName';
      
      // Supabase Storage API Endpoint
      // POST /storage/v1/object/{bucket}/{path}
      final url = Uri.parse('${Env.supabaseUrl}/storage/v1/object/products/$path');
      
      print('🌐 API URL: $url');
      
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'apikey': Env.supabaseAnonKey,
        'Content-Type': 'application/octet-stream', // Generic binary stream
        'x-upsert': 'false',
      });
      
      // Read bytes and set body
      final Uint8List bytes = await file.readAsBytes();
      request.bodyBytes = bytes;

      // 3. Send Request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 RESPONSE STATUS: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Success! Construct the public URL manually
        // Format: {supabaseUrl}/storage/v1/object/public/{bucket}/{path}
         final publicUrl = '${Env.supabaseUrl}/storage/v1/object/public/products/$path';
         print('✅ UPLOAD COMPLETE (REST API): $publicUrl');
         return publicUrl;
      } else {
        print('💥 UPLOAD FAILED (REST API): ${response.body}');
        throw Exception('Upload failed with status ${response.statusCode}: ${response.body}');
      }

    } catch (e) {
      print('💥 UPLOAD ERROR (REST API): $e');
      rethrow;
    }
  }
}

/// Mock implementation for testing
class MockStorageService implements StorageService {
  @override
  Future<String> uploadImage(XFile file) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'https://placehold.co/400x400/6B7FFF/FFFFFF?text=Uploaded';
  }
}

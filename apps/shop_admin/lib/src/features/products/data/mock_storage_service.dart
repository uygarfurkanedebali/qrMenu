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
  return SupabaseStorageService(ref);
});

/// Interface for storage operations
abstract class StorageService {
  Future<String> uploadImage(XFile file);
}

/// Real Supabase Storage implementation (REST API Version)
class SupabaseStorageService implements StorageService {
  final Ref ref;

  SupabaseStorageService(this.ref);

  @override
  Future<String> uploadImage(XFile file) async {
    // 1. Get Session manually from ShopAuthService (The Shielded Source of Truth)
    final session = ShopAuthService.currentSession;
    final accessToken = session?.accessToken;
    final user = session?.user;

    // 2. Get Tenant ID from Provider (Multi-Tenant logic)
    final tenantId = ref.read(currentTenantIdProvider);

    print('\n🚀 STORAGE PHASE 4: MULTI-TENANT PATHS');
    print('   - Manual Session: ${session != null}');
    print('   - User ID: ${user?.id}');
    print('   - Tenant ID: $tenantId');

    // 3. Validation: Both Auth and Tenant must be present
    if (accessToken == null || user == null) {
      print('🛑 FATAL: No access token available. Cannot upload.');
      throw Exception('User is not logged in.');
    }

    if (tenantId == null) {
       print('🛑 FATAL: No Tenant ID found. Cannot upload to root.');
       throw Exception('Dükkan bilgisi bulunamadı. Resim yüklenemez.');
    }

    try {
      // 4. Prepare HTTP Request
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      
      // NEW PATH: products/[TENANT_ID]/[FILENAME] (Confirmed)
      final path = '$tenantId/$fileName';
      
      // MIME Type Detection
      final extension = file.name.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'application/octet-stream';
      }

      print('📂 Uploading to path: $path');
      print('🎨 MIME Type detected: $mimeType');
      
      // Supabase Storage API Endpoint
      final url = Uri.parse('${Env.supabaseUrl}/storage/v1/object/products/$path');
      
      print('🌐 API URL: $url');
      
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'apikey': Env.supabaseAnonKey,
        'Content-Type': mimeType, 
        'x-upsert': 'false',
      });
      
      final Uint8List bytes = await file.readAsBytes();
      request.bodyBytes = bytes;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 RESPONSE STATUS: ${response.statusCode}');
      
      if (response.statusCode == 200) {
         final publicUrl = '${Env.supabaseUrl}/storage/v1/object/public/products/$path';
         print('✅ UPLOAD COMPLETE (MULTI-TENANT): $publicUrl');
         return publicUrl;
      } else {
        print('💥 UPLOAD FAILED: ${response.body}');
        throw Exception('Upload failed with status ${response.statusCode}: ${response.body}');
      }

    } catch (e) {
      print('💥 UPLOAD ERROR: $e');
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

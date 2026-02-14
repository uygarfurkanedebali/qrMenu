/// Storage Service
/// 
/// Handles file uploading to Supabase Storage.
library;

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_core/shared_core.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return SupabaseStorageService();
});

/// Interface for storage operations
abstract class StorageService {
  Future<String> uploadImage(XFile file);
}

/// Real Supabase Storage implementation
class SupabaseStorageService implements StorageService {
  static const _bucketName = 'product-images';

  @override
  Future<String> uploadImage(XFile file) async {
    // 🕵️ REAL CODE DEBUGGER
    // Ensure we are accessing the client directly as requested
    final _client = SupabaseService.client; 
    final _user = _client.auth.currentUser;
    final _session = _client.auth.currentSession;
    
    print('\n🧨 REAL UPLOAD TRAP 🧨');
    print('File being executed: mock_storage_service.dart (THIS IS THE REAL IMPLEMENTATION)');
    print('User ID: ${_user?.id}');
    if (_session?.accessToken != null) {
      print('Session Token: ${_session!.accessToken.substring(0, 10)}...');
    } else {
      print('Session Token: NULL');
    }
    print('Bucket Variable: $_bucketName');
    print('Bucket Constant: products (Hardcoded check)');
    print('----------------------------------\n');

    if (_user == null || _session == null) {
      print('❌ ERROR: User is not authenticated. Aborting upload.');
      throw Exception('User not authenticated');
    }

    try {
      // Generate path with user ID
      final path = '${_user.id}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      
      // Read file bytes
      final Uint8List bytes = await file.readAsBytes();
      
      await _client.storage
          .from(_bucketName) // authenticating against 'product-images'
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(cacheControl: '3600', upsert: false),
          );

      final url = _client.storage
          .from(_bucketName)
          .getPublicUrl(path);
          
      print('✅ Upload Success: $url');
      return url;
    } catch (e) {
      print('💥 UPLOAD FAILED: $e');
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

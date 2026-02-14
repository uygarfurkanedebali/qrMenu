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
    // 1. Get the GLOBAL client (Source of Truth)
    // Direct access to bypass potentially stale instances
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    // 2. Auth Check
    if (user == null) {
      print('🛑 FATAL: Global Supabase client reports NO USER. Cannot upload.');
      throw Exception('User is not logged in.');
    }

    try {
      // 3. Define Path & Bucket
      // Using 'products' to match the primary SQL policy as requested
      // Note: We use uploadBinary because input is XFile (bytes)
      final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      
      print('🚀 UPLOADING to: products/$path');
      print('   User ID: ${user.id}');

      // 4. Perform Upload (Using the global client)
      await client.storage.from('products').uploadBinary(
        path,
        await file.readAsBytes(),
        fileOptions: FileOptions(cacheControl: '3600', upsert: false),
      );

      // 5. Get URL
      final url = client.storage.from('products').getPublicUrl(path);
      print('✅ UPLOAD COMPLETE: $url');
      return url;

    } catch (e) {
      print('💥 UPLOAD ERROR: $e');
      rethrow;
    }
  }
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

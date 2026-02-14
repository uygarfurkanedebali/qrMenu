/// Storage Service
/// 
/// Handles file uploading to Supabase Storage.
library;

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return SupabaseStorageService();
});

/// Interface for storage operations
abstract class StorageService {
  Future<String> uploadImage(XFile file);
}

/// Real Supabase Storage implementation
class SupabaseStorageService implements StorageService {
  // REMOVED: final SupabaseClient _client = ... (Source of stale state)

  @override
  Future<String> uploadImage(XFile file) async {
    // 1. Fetch the FRESH singleton instance every time
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    final user = client.auth.currentUser;

    print('\n🔄 STORAGE DIAGNOSTICS:');
    print('   - Session Active: ${session != null}');
    print('   - User ID: ${user?.id}');
    
    // 2. Fallback check (If singleton is empty, maybe AuthState is stuck?)
    if (user == null) {
      print('⚠️ User is null on global client. Attempting session refresh is risky without context.');
      print('🛑 FATAL: Still no user. Aborting.');
      throw Exception('User is not logged in (Split Brain Error).');
    }

    try {
      // Hardcoded 'products' to match SQL policy
      final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      
      print('🚀 UPLOADING to: products/$path');

      // 3. Upload using the fresh client
      // Using uploadBinary because XFile provides bytes reliably across platforms
      final Uint8List bytes = await file.readAsBytes();
      await client.storage.from('products').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final url = client.storage.from('products').getPublicUrl(path);
      print('✅ UPLOAD COMPLETE: $url');
      return url;

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

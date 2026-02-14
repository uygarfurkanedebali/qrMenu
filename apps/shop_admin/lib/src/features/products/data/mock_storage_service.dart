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
  
  // Use the global client directly to ensure we use the active session
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<String> uploadImage(XFile file) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      print('🛑 FATAL: Global Supabase client reports NO USER. Cannot upload.');
      throw Exception('User is not logged in.');
    }

    try {
      // Hardcoded 'products' to match SQL policy
      final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      
      print('🚀 UPLOADING to: products/$path');

      // Read file bytes
      final Uint8List bytes = await file.readAsBytes();

      // Upload without optional fileOptions to avoid compatibility issues
      await _client.storage.from('products').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final url = _client.storage.from('products').getPublicUrl(path);
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

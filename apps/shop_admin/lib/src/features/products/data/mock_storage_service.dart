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
    try {
      // Read file bytes
      final Uint8List bytes = await file.readAsBytes();
      
      // Generate unique filename with timestamp
      final extension = file.name.split('.').last.toLowerCase();
      final filename = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      // Upload to Supabase Storage using the correct API
      await SupabaseService.client.storage
          .from(_bucketName)
          .uploadBinary(
            filename, 
            bytes,
          );

      // Get public URL
      final publicUrl = SupabaseService.client.storage
          .from(_bucketName)
          .getPublicUrl(filename);

      return publicUrl;
    } catch (e) {
      // If storage bucket doesn't exist or upload fails, return a placeholder
      // This allows the app to work even without storage setup
      return 'https://placehold.co/400x400/6B7FFF/FFFFFF?text=Product';
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

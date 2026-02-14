/// Settings Provider
/// 
/// Handles saving shop settings to the database.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../../auth/application/auth_provider.dart';

/// Provider for saving settings
final settingsSaveProvider = StateProvider<AsyncValue<void>>((ref) {
  return const AsyncData(null);
});

/// Save settings to database and update local state
Future<void> saveSettings({
  required WidgetRef ref,
  required String tenantId,
  required Map<String, dynamic> updates,
}) async {
  ref.read(settingsSaveProvider.notifier).state = const AsyncLoading();

  try {
    // Phase 1 Fix: Get token for isolated client
    final session = ShopAuthService.currentSession;
    final token = session?.accessToken;

    if (token == null) {
      throw Exception('Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.');
    }

    final repository = TenantRepository();
    final updatedTenant = await repository.updateTenant(
      tenantId, 
      {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      },
      authToken: token, // Inject token
    );

    // Update local tenant state with new values
    final currentTenant = ref.read(currentTenantProvider);
    if (currentTenant != null) {
      ref.read(currentTenantProvider.notifier).state = TenantState(
        id: currentTenant.id,
        name: updatedTenant.name,
        slug: currentTenant.slug,
        ownerEmail: currentTenant.ownerEmail,
        primaryColor: updatedTenant.primaryColor,
        fontFamily: updatedTenant.fontFamily,
        currencySymbol: updatedTenant.currencySymbol,
        phoneNumber: updatedTenant.phoneNumber,
        instagramHandle: updatedTenant.instagramHandle,
        wifiName: updatedTenant.wifiName,
        wifiPassword: updatedTenant.wifiPassword,
      );
    }

    ref.read(settingsSaveProvider.notifier).state = const AsyncData(null);
    print('✅ [SETTINGS] Ayarlar başarıyla kaydedildi');
  } catch (e) {
    print('❌ [SETTINGS] Kaydetme hatası: $e');
    ref.read(settingsSaveProvider.notifier).state = AsyncError(e, StackTrace.current);
    rethrow;
  }
}

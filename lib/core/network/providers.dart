import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inno/core/network/api_client.dart';
import 'package:flutter_inno/core/storage/secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage);
});

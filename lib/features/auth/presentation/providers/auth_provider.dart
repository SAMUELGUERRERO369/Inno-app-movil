import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inno/core/network/providers.dart';
import 'package:flutter_inno/features/auth/data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

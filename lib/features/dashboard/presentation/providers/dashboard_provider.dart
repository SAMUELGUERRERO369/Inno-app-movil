import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inno/core/network/providers.dart';
import 'package:flutter_inno/features/dashboard/dashboard.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRepository(apiClient);
});

final clienteDashboardProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, documento) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getClienteDashboard(documento);
});

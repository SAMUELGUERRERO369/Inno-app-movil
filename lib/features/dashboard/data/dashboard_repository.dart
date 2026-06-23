import 'package:flutter_inno/core/network/api_client.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<Map<String, dynamic>> getClienteDashboard(String documento) async {
    final response = await _apiClient.get(
      '/dashboard/cliente/$documento',
    );
    return response.data as Map<String, dynamic>;
  }
}

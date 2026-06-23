import 'package:flutter_inno/core/network/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<Map<String, dynamic>> login(String documento, String password) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: {
        'numeroDocumento': documento,
        'password': password,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      '/auth/registro',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }
}

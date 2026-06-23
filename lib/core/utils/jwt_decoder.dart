import 'dart:convert';

class JwtDecoder {
  static Map<String, dynamic> decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};

    try {
      final payload = parts[1];
      final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      final padded = normalized.padRight(normalized.length + (4 - normalized.length % 4) % 4, '=');
      final decoded = utf8.decode(base64.decode(padded));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}

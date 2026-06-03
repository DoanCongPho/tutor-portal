import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

/// Thin wrapper over the `http` package that:
///  - prefixes [AppConfig.apiBaseUrl]
///  - encodes/decodes JSON
///  - injects a Bearer token when [accessToken] is non-null
///  - converts non-2xx responses into [ApiException]
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body,
    String? accessToken,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
    try {
      final response = await _client
          .post(uri, headers: headers, body: jsonEncode(body ?? const {}))
          .timeout(AppConfig.apiTimeout);
      return _decode(response);
    } on http.ClientException catch (e) {
      throw ApiException(statusCode: 0, message: 'network: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    String? accessToken,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(AppConfig.apiTimeout);
      return _decode(response);
    } on http.ClientException catch (e) {
      throw ApiException(statusCode: 0, message: 'network: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    String? accessToken,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
    try {
      final response = await _client
          .delete(uri, headers: headers)
          .timeout(AppConfig.apiTimeout);
      return _decode(response);
    } on http.ClientException catch (e) {
      throw ApiException(statusCode: 0, message: 'network: ${e.message}');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final raw = response.body;
    Map<String, dynamic>? decoded;
    if (raw.isNotEmpty) {
      try {
        decoded = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        decoded = null;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded ?? <String, dynamic>{};
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: decoded?['error'] as String? ?? raw,
      body: decoded,
    );
  }

  void close() => _client.close();
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.close);
  return client;
});

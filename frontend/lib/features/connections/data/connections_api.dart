import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/parent_connection.dart';

/// Raw HTTP binding to the student-facing children endpoints in
/// `internal/children/routes.go`: `POST /children/link` (accept a parent's invite
/// code) and `GET /children/connection` (the student's current link).
class ConnectionsApi {
  ConnectionsApi(this._client);

  final ApiClient _client;

  /// Accepts a parent's invite [code], linking the two accounts. Returns the
  /// now-connected child record.
  Future<ParentConnection> link({
    required String token,
    required String code,
  }) async {
    final json = await _client.postJson(
      '/children/link',
      accessToken: token,
      body: {'code': code},
    );
    return ParentConnection.fromJson(json);
  }

  /// Returns the student's current connection, or null if they haven't linked a
  /// parent yet (the endpoint answers 404 in that case).
  Future<ParentConnection?> myConnection(String token) async {
    try {
      final json =
          await _client.getJson('/children/connection', accessToken: token);
      return ParentConnection.fromJson(json);
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }
}

final connectionsApiProvider = Provider<ConnectionsApi>((ref) {
  return ConnectionsApi(ref.watch(apiClientProvider));
});

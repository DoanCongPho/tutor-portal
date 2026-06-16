import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/parent_connection.dart';
import 'connections_api.dart';

/// Single point of truth for the student's parent-connection state. Resolves the
/// access token, calls [ConnectionsApi], and transparently refreshes once on a
/// 401 (the auth strategy in frontend/CLAUDE.md, mirroring ChildrenRepository).
class ConnectionsRepository {
  ConnectionsRepository({
    required ConnectionsApi api,
    required AuthRepository auth,
  })  : _api = api,
        _auth = auth;

  final ConnectionsApi _api;
  final AuthRepository _auth;

  Future<ParentConnection?> myConnection() => _authed(_api.myConnection);

  Future<ParentConnection> link(String code) =>
      _authed((t) => _api.link(token: t, code: code));

  /// Runs [call] with the current access token, refreshing and retrying once if
  /// the first attempt comes back 401.
  Future<T> _authed<T>(Future<T> Function(String token) call) async {
    var token = await _auth.currentAccessToken();
    if (token == null) {
      throw ApiException(statusCode: 401, message: 'Not signed in');
    }
    try {
      return await call(token);
    } on ApiException catch (e) {
      if (!e.isUnauthorized) rethrow;
      final user = await _auth.refresh();
      if (user == null) rethrow;
      token = await _auth.currentAccessToken();
      if (token == null) rethrow;
      return await call(token);
    }
  }
}

final connectionsRepositoryProvider = Provider<ConnectionsRepository>((ref) {
  return ConnectionsRepository(
    api: ref.watch(connectionsApiProvider),
    auth: ref.watch(authRepositoryProvider),
  );
});

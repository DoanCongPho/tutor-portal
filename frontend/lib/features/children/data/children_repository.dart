import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/child.dart';
import 'children_api.dart';

/// Single point of truth for child data. Resolves the access token, calls
/// [ChildrenApi], and transparently refreshes once on a 401 (per the auth
/// strategy in frontend/CLAUDE.md — promote into ApiClient when a third
/// feature needs it).
class ChildrenRepository {
  ChildrenRepository({required ChildrenApi api, required AuthRepository auth})
      : _api = api,
        _auth = auth;

  final ChildrenApi _api;
  final AuthRepository _auth;

  Future<List<Child>> list() => _authed(_api.list);

  Future<Child> createInvite({
    required String name,
    String? grade,
    String? school,
  }) =>
      _authed(
        (t) => _api.create(
          token: t,
          name: name,
          grade: grade,
          school: school,
        ),
      );

  Future<Child> connect(String code) =>
      _authed((t) => _api.connect(token: t, code: code));

  Future<Child> regenerate(int id) =>
      _authed((t) => _api.regenerate(token: t, id: id));

  Future<void> remove(int id) => _authed((t) => _api.remove(token: t, id: id));

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

final childrenRepositoryProvider = Provider<ChildrenRepository>((ref) {
  return ChildrenRepository(
    api: ref.watch(childrenApiProvider),
    auth: ref.watch(authRepositoryProvider),
  );
});

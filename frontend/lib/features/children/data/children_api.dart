import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/child.dart';

/// Raw HTTP binding to the backend's `internal/children/routes.go` endpoints.
/// Every call is authenticated — the caller passes a valid access token.
class ChildrenApi {
  ChildrenApi(this._client);

  final ApiClient _client;

  Future<List<Child>> list(String token) async {
    final json = await _client.getJson('/children', accessToken: token);
    final raw = (json['children'] as List?) ?? const [];
    return raw
        .map((e) => Child.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Registers a child profile and mints a shareable invite code (the child
  /// starts `pending`).
  Future<Child> create({
    required String token,
    required String name,
    String? grade,
    String? school,
  }) async {
    final json = await _client.postJson(
      '/children',
      accessToken: token,
      body: {
        'name': name,
        if (grade != null && grade.isNotEmpty) 'grade': grade,
        if (school != null && school.isNotEmpty) 'school': school,
      },
    );
    return Child.fromJson(json);
  }

  /// Accepts an invite code, moving the matching pending child to `connected`.
  Future<Child> connect({required String token, required String code}) async {
    final json = await _client.postJson(
      '/children/connect',
      accessToken: token,
      body: {'code': code},
    );
    return Child.fromJson(json);
  }

  /// Mints a fresh invite code for a pending child (e.g. the old one lapsed).
  Future<Child> regenerate({required String token, required int id}) async {
    final json =
        await _client.postJson('/children/$id/invite', accessToken: token);
    return Child.fromJson(json);
  }

  Future<void> remove({required String token, required int id}) async {
    await _client.deleteJson('/children/$id', accessToken: token);
  }
}

final childrenApiProvider = Provider<ChildrenApi>((ref) {
  return ChildrenApi(ref.watch(apiClientProvider));
});

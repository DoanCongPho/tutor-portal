import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/tutor_profile.dart';

/// HTTP binding to the backend's `internal/tutor/routes.go` endpoints. Both
/// require a tutor access token (the routes are guarded by RequireAuth +
/// RequireRole("tutor")).
class TutorApi {
  TutorApi(this._client);

  final ApiClient _client;

  /// POST /tutors/onboarding — persists the full onboarding payload and returns
  /// the resulting profile (verification_status = pending_review).
  Future<TutorProfile> submitOnboarding({
    required String accessToken,
    required Map<String, dynamic> payload,
  }) async {
    final json = await _client.postJson(
      '/tutors/onboarding',
      body: payload,
      accessToken: accessToken,
    );
    return TutorProfile.fromJson(json);
  }

  /// GET /tutors/me — the authenticated tutor's profile. Throws ApiException
  /// with statusCode 404 when the tutor has not onboarded yet.
  Future<TutorProfile> getMyProfile(String accessToken) async {
    final json = await _client.getJson('/tutors/me', accessToken: accessToken);
    return TutorProfile.fromJson(json);
  }
}

final tutorApiProvider = Provider<TutorApi>((ref) {
  return TutorApi(ref.watch(apiClientProvider));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/token_storage.dart';
import '../domain/tutor_profile.dart';
import 'tutor_api.dart';

/// Coordinates [TutorApi] with the stored access token so the controller layer
/// doesn't have to thread credentials through every call.
class TutorRepository {
  TutorRepository({required TutorApi api, required TokenStorage storage})
      : _api = api,
        _storage = storage;

  final TutorApi _api;
  final TokenStorage _storage;

  Future<TutorProfile> submitOnboarding(Map<String, dynamic> payload) async {
    final token = await _requireToken();
    return _api.submitOnboarding(accessToken: token, payload: payload);
  }

  Future<TutorProfile> getMyProfile() async {
    final token = await _requireToken();
    return _api.getMyProfile(token);
  }

  Future<String> _requireToken() async {
    final token = await _storage.readAccessToken();
    if (token == null) {
      throw StateError('Not authenticated');
    }
    return token;
  }
}

final tutorRepositoryProvider = Provider<TutorRepository>((ref) {
  return TutorRepository(
    api: ref.watch(tutorApiProvider),
    storage: ref.watch(tokenStorageProvider),
  );
});

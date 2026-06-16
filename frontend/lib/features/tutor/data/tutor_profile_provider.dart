import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tutor_profile.dart';
import 'tutor_repository.dart';

/// The signed-in tutor's saved profile (GET /tutors/me). Shared by the tutor
/// Profile tab and the Edit Profile form. Invalidate it after a successful edit
/// (`ref.invalidate(tutorProfileProvider)`) to re-fetch the fresh aggregate.
final tutorProfileProvider = FutureProvider<TutorProfile>((ref) {
  return ref.watch(tutorRepositoryProvider).getMyProfile();
});

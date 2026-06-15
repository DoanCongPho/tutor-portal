import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/tutor_repository.dart';
import '../domain/tutor_profile.dart';
import '../domain/tutor_vocab.dart';

/// Number of onboarding steps (matches the mockup "Step X of 6").
const int kOnboardingStepCount = 6;

/// Hourly-rate slider bounds, in whole VND (the mockup runs 100k–1,000k).
const int kMinRate = 100000;
const int kMaxRate = 1000000;
const int kDefaultRate = 350000;

/// Immutable draft of the whole onboarding wizard. The controller mutates it
/// step by step; [submit] flattens it into the API payload.
class TutorOnboardingState {
  const TutorOnboardingState({
    this.step = 0,
    this.name = '',
    this.phone = '',
    this.avatarUrl = '',
    this.subjects = const [],
    this.hourlyRate = kDefaultRate,
    this.bio = '',
    this.documents = const {},
    this.schedule = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.submittedStatus,
  });

  final int step;
  final String name;
  final String phone;
  final String avatarUrl;
  final List<TutorSubjectEntry> subjects;
  final int hourlyRate;
  final String bio;

  /// Credential references keyed by type. File uploads are skipped in v1, so the
  /// value is a plain URL/reference string.
  final Map<DocType, String> documents;
  final List<ScheduleSlot> schedule;

  final bool isSubmitting;
  final String? errorMessage;

  /// Set once the backend accepts the submission (e.g. "pending_review").
  final String? submittedStatus;

  bool get isFirstStep => step == 0;
  bool get isLastStep => step == kOnboardingStepCount - 1;
  bool get isSubmitted => submittedStatus != null;

  /// Per-step gate for enabling the Next/Submit button.
  bool get canAdvance {
    switch (step) {
      case 0:
        return name.trim().isNotEmpty;
      case 1:
        return subjects.isNotEmpty;
      case 2:
        return hourlyRate >= kMinRate && hourlyRate <= kMaxRate;
      case 3:
        return documents.values.any((v) => v.trim().isNotEmpty);
      case 4:
        return schedule.isNotEmpty;
      default:
        return true;
    }
  }

  TutorOnboardingState copyWith({
    int? step,
    String? name,
    String? phone,
    String? avatarUrl,
    List<TutorSubjectEntry>? subjects,
    int? hourlyRate,
    String? bio,
    Map<DocType, String>? documents,
    List<ScheduleSlot>? schedule,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? submittedStatus,
  }) {
    return TutorOnboardingState(
      step: step ?? this.step,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      subjects: subjects ?? this.subjects,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      bio: bio ?? this.bio,
      documents: documents ?? this.documents,
      schedule: schedule ?? this.schedule,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      submittedStatus: submittedStatus ?? this.submittedStatus,
    );
  }
}

class TutorOnboardingController extends Notifier<TutorOnboardingState> {
  late final TutorRepository _repo;

  @override
  TutorOnboardingState build() {
    _repo = ref.read(tutorRepositoryProvider);
    // Prefill name/phone from the signed-in account so step 1 isn't empty.
    final user = ref.read(authControllerProvider).user;
    return TutorOnboardingState(
      name: user?.name ?? '',
      phone: user?.phone ?? '',
    );
  }

  void next() {
    if (!state.canAdvance || state.isLastStep) return;
    state = state.copyWith(step: state.step + 1, clearError: true);
  }

  void back() {
    if (state.isFirstStep) return;
    state = state.copyWith(step: state.step - 1, clearError: true);
  }

  void goTo(int step) {
    if (step < 0 || step >= kOnboardingStepCount) return;
    state = state.copyWith(step: step, clearError: true);
  }

  void setPersonal({String? name, String? phone, String? avatarUrl}) {
    state = state.copyWith(name: name, phone: phone, avatarUrl: avatarUrl);
  }

  void addSubject(TutorSubjectEntry entry) {
    if (state.subjects.contains(entry)) return;
    state = state.copyWith(subjects: [...state.subjects, entry]);
  }

  void removeSubject(TutorSubjectEntry entry) {
    state = state.copyWith(
      subjects: state.subjects.where((e) => e != entry).toList(),
    );
  }

  void setRate(int rate) => state = state.copyWith(hourlyRate: rate);

  void setBio(String bio) => state = state.copyWith(bio: bio);

  void setDocument(DocType type, String fileUrl) {
    final docs = Map<DocType, String>.from(state.documents);
    if (fileUrl.trim().isEmpty) {
      docs.remove(type);
    } else {
      docs[type] = fileUrl.trim();
    }
    state = state.copyWith(documents: docs);
  }

  void addSlot(ScheduleSlot slot) {
    state = state.copyWith(schedule: [...state.schedule, slot]);
  }

  void removeSlotAt(int index) {
    final next = [...state.schedule]..removeAt(index);
    state = state.copyWith(schedule: next);
  }

  void clearError() => state = state.copyWith(clearError: true);

  /// Flattens the draft into the backend payload and POSTs it. On success
  /// [submittedStatus] is set to the returned verification status.
  Future<void> submit() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final payload = <String, dynamic>{
        'name': state.name.trim(),
        if (state.phone.trim().isNotEmpty) 'phone': state.phone.trim(),
        if (state.avatarUrl.trim().isNotEmpty) 'avatar_url': state.avatarUrl.trim(),
        'hourly_rate': state.hourlyRate,
        if (state.bio.trim().isNotEmpty) 'bio': state.bio.trim(),
        'subjects': state.subjects.map((s) => s.toJson()).toList(),
        'documents': state.documents.entries
            .where((e) => e.value.trim().isNotEmpty)
            .map((e) => {'doc_type': e.key.api, 'file_url': e.value.trim()})
            .toList(),
        'schedule': state.schedule.map((s) => s.toJson()).toList(),
      };
      final profile = await _repo.submitOnboarding(payload);
      state = state.copyWith(submittedStatus: profile.verificationStatus);
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}

final tutorOnboardingControllerProvider =
    NotifierProvider<TutorOnboardingController, TutorOnboardingState>(
  TutorOnboardingController.new,
);

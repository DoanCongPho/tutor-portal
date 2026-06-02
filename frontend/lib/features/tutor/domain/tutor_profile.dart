import 'tutor_vocab.dart';

/// A (subject, level) pair the tutor teaches. One row in `tutor_subjects`.
class TutorSubjectEntry {
  const TutorSubjectEntry({required this.subject, required this.level});

  final String subject;
  final Level level;

  Map<String, dynamic> toJson() => {'subject': subject, 'level': level.api};

  factory TutorSubjectEntry.fromJson(Map<String, dynamic> json) => TutorSubjectEntry(
        subject: json['subject'] as String,
        level: Level.fromApi(json['level'] as String),
      );

  @override
  bool operator ==(Object other) =>
      other is TutorSubjectEntry && other.subject == subject && other.level == level;

  @override
  int get hashCode => Object.hash(subject, level);
}

/// A credential document reference. File uploads are skipped in v1, so [fileUrl]
/// is a plain URL/reference string.
class TutorDocumentEntry {
  const TutorDocumentEntry({required this.docType, required this.fileUrl});

  final DocType docType;
  final String fileUrl;

  Map<String, dynamic> toJson() => {'doc_type': docType.api, 'file_url': fileUrl};

  factory TutorDocumentEntry.fromJson(Map<String, dynamic> json) => TutorDocumentEntry(
        docType: DocType.fromApi(json['doc_type'] as String),
        fileUrl: json['file_url'] as String? ?? '',
      );
}

/// A weekly availability slot. One row in `schedules`.
class ScheduleSlot {
  const ScheduleSlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  final int dayOfWeek; // 0=Sun .. 6=Sat
  final String startTime; // "HH:MM"
  final String endTime;

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
      };

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) => ScheduleSlot(
        dayOfWeek: (json['day_of_week'] as num).toInt(),
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
      );
}

/// Mirrors the backend `TutorProfileResponse` (`internal/tutor/dto.go`).
class TutorProfile {
  const TutorProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.hourlyRate,
    required this.verificationStatus,
    required this.subjects,
    required this.schedule,
    this.phone,
    this.avatarUrl,
    this.bio,
  });

  final int id;
  final int userId;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final int hourlyRate;
  final String? bio;
  final String verificationStatus;
  final List<TutorSubjectEntry> subjects;
  final List<ScheduleSlot> schedule;

  factory TutorProfile.fromJson(Map<String, dynamic> json) => TutorProfile(
        id: (json['id'] as num).toInt(),
        userId: (json['user_id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        hourlyRate: (json['hourly_rate'] as num).toInt(),
        bio: json['bio'] as String?,
        verificationStatus: json['verification_status'] as String,
        subjects: ((json['subjects'] as List?) ?? const [])
            .map((e) => TutorSubjectEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        schedule: ((json['schedule'] as List?) ?? const [])
            .map((e) => ScheduleSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

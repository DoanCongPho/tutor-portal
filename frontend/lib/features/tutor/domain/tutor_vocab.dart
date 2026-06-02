// Controlled vocabulary for tutor onboarding. Mirrors the backend's
// `internal/tutor/helpers.go` (subject list) and the `tutor_subjects.level` /
// `tutor_documents.doc_type` enums. Keep in sync with the Go side.

/// Teaching subjects (Vietnamese curriculum). Free text is not allowed — the
/// backend rejects anything outside this list.
const List<String> kSubjects = <String>[
  'Toán',
  'Ngữ văn',
  'Tiếng Anh',
  'Vật lý',
  'Hóa học',
  'Sinh học',
  'Lịch sử',
  'Địa lý',
  'Giáo dục công dân',
  'Tin học',
  'Tiếng Pháp',
  'Tiếng Nhật',
  'Tiếng Trung',
  'Tiếng Hàn',
];

/// Teaching level (maps to the `level` enum). [api] is the wire value.
enum Level {
  primary('primary', 'Tiểu học'),
  middleSchool('middle_school', 'THCS'),
  highSchool('high_school', 'THPT'),
  university('university', 'Đại học');

  const Level(this.api, this.label);
  final String api;
  final String label;

  static Level fromApi(String value) =>
      Level.values.firstWhere((l) => l.api == value, orElse: () => Level.highSchool);
}

/// Credential document type (maps to the `doc_type` enum).
enum DocType {
  degree('degree', 'Degree', 'Bằng cấp'),
  certificate('certificate', 'Teaching certificate', 'Chứng chỉ giảng dạy'),
  nationalId('national_id', 'National ID', 'CMND/CCCD');

  const DocType(this.api, this.label, this.labelVi);
  final String api;
  final String label;
  final String labelVi;

  static DocType fromApi(String value) =>
      DocType.values.firstWhere((d) => d.api == value, orElse: () => DocType.degree);
}

/// Day-of-week labels indexed 0=Sunday .. 6=Saturday (matches `schedules.day_of_week`).
const List<String> kDayLabels = <String>[
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];

/// Formats a whole-VND amount with thousands separators, e.g. 350000 → "350,000".
String formatVnd(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

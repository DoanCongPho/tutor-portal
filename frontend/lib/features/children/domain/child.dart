/// Mirrors the backend `ChildDTO` from `internal/children/dto.go`.
///
/// A child is either `pending` (an invite code has been shared but not yet
/// accepted) or `connected` (linked to the child's own account). [inviteCode]
/// and [inviteExpiresAt] are only present while pending.
class Child {
  const Child({
    required this.id,
    required this.name,
    required this.status,
    this.grade,
    this.school,
    this.inviteCode,
    this.inviteExpiresAt,
  });

  final int id;
  final String name;
  final String status;
  final String? grade;
  final String? school;
  final String? inviteCode;
  final DateTime? inviteExpiresAt;

  bool get isConnected => status == 'connected';
  bool get isPending => status == 'pending';

  factory Child.fromJson(Map<String, dynamic> json) => Child(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        status: json['status'] as String? ?? 'pending',
        grade: json['grade'] as String?,
        school: json['school'] as String?,
        inviteCode: json['invite_code'] as String?,
        inviteExpiresAt: switch (json['invite_expires_at']) {
          final String s => DateTime.tryParse(s),
          _ => null,
        },
      );
}

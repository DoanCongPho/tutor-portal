/// Mirrors the `UserDTO` returned by the backend at
/// `internal/auth/dto.go::UserDTO`. Email is the verified login identity; phone
/// is optional contact info collected at signup but never verified.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.phone,
  });

  final int id;
  final String email;
  final String role;
  final String name;
  final String? phone;

  bool get isTutor => role == 'tutor';
  bool get isParent => role == 'parent';
  bool get isStudent => role == 'student';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num).toInt(),
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        role: json['role'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'email': email,
        if (phone != null) 'phone': phone,
        'role': role,
        'name': name,
      };
}

/// Mirrors the `UserDTO` returned by the backend at
/// `internal/auth/dto.go::UserDTO`.
class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    required this.role,
    required this.name,
    this.email,
  });

  final int id;
  final String phone;
  final String role;
  final String name;
  final String? email;

  bool get isTutor => role == 'tutor';
  bool get isParent => role == 'parent';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num).toInt(),
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
        role: json['role'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'phone': phone,
        if (email != null) 'email': email,
        'role': role,
        'name': name,
      };
}

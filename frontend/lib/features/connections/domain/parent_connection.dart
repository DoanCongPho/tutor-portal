/// The student's view of their parent link, mirroring the backend `ChildDTO`
/// returned by `/children/link` and `/children/connection`. [name] is the name
/// the parent gave the child profile when they created the invite.
class ParentConnection {
  const ParentConnection({
    required this.id,
    required this.name,
    required this.status,
  });

  final int id;
  final String name;
  final String status;

  bool get isConnected => status == 'connected';

  factory ParentConnection.fromJson(Map<String, dynamic> json) =>
      ParentConnection(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
      );
}

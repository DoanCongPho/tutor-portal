import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/connections_repository.dart';
import '../domain/parent_connection.dart';

/// Owns the student's parent-connection state. `null` data means "not connected
/// to a parent yet"; a non-null [ParentConnection] is the active link.
class ConnectionsController extends AsyncNotifier<ParentConnection?> {
  late final ConnectionsRepository _repo;

  @override
  Future<ParentConnection?> build() {
    _repo = ref.read(connectionsRepositoryProvider);
    return _repo.myConnection();
  }

  /// Links to a parent via their invite [code] and returns the new connection.
  /// Throws on failure so the caller can surface the error.
  Future<ParentConnection> connect(String code) async {
    final conn = await _repo.link(code);
    state = AsyncValue.data(conn);
    return conn;
  }
}

final connectionsControllerProvider =
    AsyncNotifierProvider<ConnectionsController, ParentConnection?>(
  ConnectionsController.new,
);

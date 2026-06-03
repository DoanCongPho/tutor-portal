import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/children_repository.dart';
import '../domain/child.dart';

/// Owns the parent's children list. Mutations call the repository then refresh
/// the list so connected/pending state and pending-invite codes stay in sync.
class ChildrenController extends AsyncNotifier<List<Child>> {
  late final ChildrenRepository _repo;

  @override
  Future<List<Child>> build() {
    _repo = ref.read(childrenRepositoryProvider);
    return _repo.list();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.list);
  }

  /// Adds a child and returns it (with its fresh invite code) so the caller can
  /// surface the code immediately. Throws on failure — the caller shows the error.
  Future<Child> addChild({
    required String name,
    String? grade,
    String? school,
  }) async {
    final child =
        await _repo.createInvite(name: name, grade: grade, school: school);
    await refresh();
    return child;
  }

  Future<Child> connect(String code) async {
    final child = await _repo.connect(code);
    await refresh();
    return child;
  }

  Future<Child> regenerate(int id) async {
    final child = await _repo.regenerate(id);
    await refresh();
    return child;
  }

  Future<void> remove(int id) async {
    await _repo.remove(id);
    await refresh();
  }
}

final childrenControllerProvider =
    AsyncNotifierProvider<ChildrenController, List<Child>>(
  ChildrenController.new,
);

import 'domain_snapshot_store.dart';
import 'sqlite_domain_snapshot_store.dart';

/// Internal command buffer. It deliberately performs no I/O and is never used
/// as an application repository or a durability acknowledgment.
class DomainMutationBuffer<T> implements DomainSnapshotStore<T> {
  DomainMutationBuffer(this.value);
  @override
  T value;
  @override
  bool get recoveredFromDamagedSnapshot => false;
  @override
  Future<void> persist(T next) async {
    value = next;
  }
}

/// A repository containing staged business mutations, held under the live
/// repository's write queue. Publish reads committed storage, never the buffer.
class StagedDomainMutation<R> {
  const StagedDomainMutation({
    required this.repository,
    required this.prepare,
    required this.publishCommitted,
  });
  final R repository;
  final PreparedDomainSnapshotChange Function() prepare;
  final void Function() publishCommitted;
}

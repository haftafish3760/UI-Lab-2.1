import 'draft_repository.dart';
import 'draft_recovery_catalog.dart';

/// A recovery chooser receives this read model, not a stored payload or SQL row.
class DraftRecoveryChoice {
  const DraftRecoveryChoice({
    required this.draftId,
    required this.label,
    required this.unreadable,
  });
  final String draftId;
  final String label;
  final bool unreadable;
}

/// A domain-issued query for already-authorized recovery. Its wire keys belong
/// to the workflow, and are never supplied by a widget's field/controller tree.
class DraftRecoveryQuery {
  const DraftRecoveryQuery({
    required this.repository,
    required this.canList,
    required this.organizationId,
    required this.ownerId,
    required this.domain,
    required this.parentField,
    required this.labelField,
    required this.emptyLabel,
  });
  final DraftRepository repository;
  final bool Function() canList;
  final String organizationId;
  final String ownerId;
  final String domain;
  final String parentField;
  final String labelField;
  final String emptyLabel;

  Future<List<DraftRecoveryChoice>> list() async {
    // Authorization belongs to the workflow and is rechecked across I/O. Reuse
    // catalog isolation without granting the chooser any discard capability.
    if (!canList()) return const [];
    final catalog = DraftRecoveryCatalog(
      repository: repository,
      organizationId: organizationId,
      ownerId: ownerId,
      handlers: [
        DraftRecoveryHandler(
          domain: domain,
          workflowLabel: domain,
          canList: canList,
          canDiscard: (_) async => false,
          inspect: (input) async {
            if (input[parentField] != null) return null;
            final value = input[labelField];
            if (value is! String) {
              return const DraftRecoveryPreview(
                title: 'Saved input unavailable — kept on this device',
                availability: DraftRecoveryAvailability.unreadable,
              );
            }
            return DraftRecoveryPreview(
              title: value.trim().isEmpty ? emptyLabel : value,
            );
          },
        ),
      ],
    );
    final entries = await catalog.list();
    if (!canList()) return const [];
    return List.unmodifiable(
      entries.map(
        (entry) => DraftRecoveryChoice(
          draftId: entry.draftId,
          label: entry.preview.title,
          unreadable:
              entry.preview.availability !=
              DraftRecoveryAvailability.recoverable,
        ),
      ),
    );
  }
}

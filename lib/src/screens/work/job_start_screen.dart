import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import 'estimate_models.dart';
import 'work_job_editor.dart';
import 'work_models.dart';
import 'work_saved_document_route.dart';

/// Both Jobs and Work use the same entry into standalone or estimated work.
class JobStartScreen extends StatefulWidget {
  const JobStartScreen({required this.initialDay, super.key});
  final DateTime initialDay;

  @override
  State<JobStartScreen> createState() => _JobStartScreenState();
}

class _JobStartScreenState extends State<JobStartScreen> {
  String _query = '';

  Future<void> _withoutEstimate() async {
    final job = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => WorkJobEditor(initialDay: widget.initialDay),
      ),
    );
    if (mounted && job != null) Navigator.of(context).pop(job);
  }

  Future<void> _openEstimate(WorkRecord record) async {
    // Review, approval and atomic conversion stay in the existing document flow.
    await openSavedWorkDocument(context, record);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final permissions = store.workSession?.permissions;
    final canCreate =
        permissions == null ||
        (permissions.editableKinds.contains(WorkRecordKind.job) &&
            permissions.visibleCreatorIds.contains(
              permissions.actorEmployeeId,
            ));
    final estimates = store.workRecords.where((record) {
      if (record.kind != WorkRecordKind.estimate ||
          (permissions != null && !permissions.canEdit(record))) {
        return false;
      }
      if (record.resolvedEstimateStage == EstimateStage.converted) return false;
      return '${record.number} ${record.title} ${record.client}'
          .toLowerCase()
          .contains(_query.toLowerCase().trim());
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('New job')),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: SizedBox(
            width: AppLayoutEngine.formWorkspaceWidthFor(
              constraints.maxWidth -
                  AppLayoutEngine.pageInsetsFor(
                    constraints.maxWidth,
                  ).horizontal,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
              children: [
                if (!canCreate)
                  const Text('Your access does not allow creating jobs.')
                else ...[
                  FilledButton.icon(
                    key: const ValueKey('job-without-estimate'),
                    onPressed: _withoutEstimate,
                    icon: const Icon(Icons.add),
                    label: const Text('Create job without an estimate'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Start from an estimate',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose an estimate to review its approval and create the job. '
                    'Its customer, items and prices carry over.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('job-estimate-search'),
                    decoration: const InputDecoration(
                      labelText: 'Find an estimate',
                      hintText: 'Customer, title or estimate number',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  if (estimates.isEmpty)
                    Text(
                      _query.trim().isEmpty
                          ? 'No estimates are available to turn into jobs yet.'
                          : 'No estimates match your search.',
                    ),
                  for (final record in estimates)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _EstimateChoiceRow(
                        record: record,
                        onOpen: () => _openEstimate(record),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EstimateChoiceRow extends StatelessWidget {
  const _EstimateChoiceRow({required this.record, required this.onOpen});

  final WorkRecord record;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final approval = record.hasCurrentCustomerApproval
        ? 'Customer approval recorded'
        : 'Review customer approval';
    return Semantics(
      button: true,
      label:
          'Open estimate ${record.number}, ${record.title}, '
          '${record.client}, $approval',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: BorderSide(color: colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('job-start-estimate-${record.id}'),
          onTap: onOpen,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${record.number} · ${record.title}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(record.client),
                        Text(
                          approval,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
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
        builder: (context, constraints) => ListView(
          padding: AppLayoutEngine.pageInsetsFor(
            constraints.maxWidth,
          ).copyWith(top: 16, bottom: 24),
          children: [
            if (!canCreate)
              const Text('Your access does not allow creating jobs.')
            else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const ValueKey('job-without-estimate'),
                  onPressed: _withoutEstimate,
                  icon: const Icon(Icons.add),
                  label: const Text('Create without an estimate'),
                ),
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
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${record.number} · ${record.title}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(record.client),
                        Text(
                          record.hasCurrentCustomerApproval
                              ? 'Customer approval recorded'
                              : 'Review customer approval before creating a job',
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _openEstimate(record),
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('Open estimate'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

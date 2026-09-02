part of 'estimate_detail_screen.dart';

class _EstimateActionCard extends StatelessWidget {
  const _EstimateActionCard({
    required this.record,
    required this.onEditDetails,
    required this.onPreview,
    required this.onDelivery,
    required this.onSignature,
    required this.onReady,
    required this.onCreateJob,
    required this.permissions,
  });

  final WorkRecord record;
  final VoidCallback onEditDetails;
  final VoidCallback onPreview;
  final VoidCallback onDelivery;
  final VoidCallback onSignature;
  final VoidCallback onReady;
  final VoidCallback onCreateJob;
  final EstimatePermissions permissions;

  @override
  Widget build(BuildContext context) {
    final stage = record.resolvedEstimateStage;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Estimate actions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text('Every action applies to the exact revision shown above.'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (permissions.canEditItems)
                OutlinedButton.icon(
                  key: const ValueKey('edit-estimate-details'),
                  onPressed: onEditDetails,
                  icon: const Icon(Icons.edit_note_outlined),
                  label: const Text('Edit estimate'),
                ),
              OutlinedButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.preview_outlined),
                label: const Text('Preview customer copy'),
              ),
              if (permissions.canSend &&
                  stage != EstimateStage.draft &&
                  record.companyReviewAllowsCustomerApproval)
                OutlinedButton.icon(
                  onPressed: onDelivery,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF delivery options'),
                ),
              if (stage == EstimateStage.draft && permissions.canEditItems)
                FilledButton.tonalIcon(
                  onPressed: onReady,
                  icon: const Icon(Icons.task_alt_outlined),
                  label: Text(
                    record.requiresCompanyReview
                        ? 'Submit for company approval'
                        : 'Mark ready to send',
                  ),
                ),
              if (stage != EstimateStage.converted &&
                  stage != EstimateStage.draft &&
                  record.companyReviewAllowsCustomerApproval &&
                  permissions.canCollectSignature)
                OutlinedButton.icon(
                  onPressed: onSignature,
                  icon: const Icon(Icons.draw_outlined),
                  label: const Text('Sign in person'),
                ),
              if (stage == EstimateStage.approved &&
                  record.hasCurrentCustomerSignature &&
                  permissions.canConvertToJob)
                FilledButton.icon(
                  key: const ValueKey('preview-create-job'),
                  onPressed: onCreateJob,
                  icon: const Icon(Icons.event_available_outlined),
                  label: const Text('Create and plan job'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

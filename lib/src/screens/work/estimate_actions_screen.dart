import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../theme/app_semantic_colors.dart';
import 'estimate_models.dart';
import 'work_detail_header.dart';
import 'work_models.dart';

enum EstimateAction { edit, preview, delivery, signature, markReady, createJob }

class EstimateActionsScreen extends StatelessWidget {
  const EstimateActionsScreen({
    required this.record,
    required this.permissions,
    super.key,
  });

  final WorkRecord record;
  final EstimatePermissions permissions;

  @override
  Widget build(BuildContext context) {
    final stage = record.resolvedEstimateStage;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final statusActions = <Widget>[
      if (stage == EstimateStage.draft && permissions.canEditItems)
        _ActionTile(
          key: const ValueKey('estimate-mark-ready-action'),
          icon: Icons.task_alt_outlined,
          title: record.requiresCompanyReview
              ? 'Submit for company approval'
              : 'Mark ready to send',
          detail: record.requiresCompanyReview
              ? 'Send this exact revision to an authorized company reviewer.'
              : 'Confirm the draft has customer-ready scope and pricing.',
          accent: semantic.success,
          surface: semantic.successSurface,
          onTap: () => _finish(context, EstimateAction.markReady),
        ),
      if (stage == EstimateStage.approved &&
          record.hasCurrentCustomerSignature &&
          permissions.canConvertToJob)
        _ActionTile(
          key: const ValueKey('preview-create-job'),
          icon: Icons.event_available_outlined,
          title: 'Create and plan job',
          detail:
              'Create a linked job, then review its schedule and assignment.',
          accent: semantic.success,
          surface: semantic.successSurface,
          onTap: () => _finish(context, EstimateAction.createJob),
        ),
    ];
    final recordActions = <Widget>[
      if (permissions.canEditItems)
        _ActionTile(
          key: const ValueKey('edit-estimate-details'),
          icon: Icons.edit_note_outlined,
          title: 'Edit estimate',
          detail: 'Update customer details, proposed work, dates, or pricing.',
          accent: semantic.planned,
          surface: semantic.plannedSurface,
          onTap: () => _finish(context, EstimateAction.edit),
        ),
      _ActionTile(
        key: const ValueKey('preview-estimate-copy'),
        icon: Icons.preview_outlined,
        title: 'Preview customer copy',
        detail: 'Review the exact estimate the customer will receive.',
        accent: semantic.current,
        surface: semantic.currentSurface,
        onTap: () => _finish(context, EstimateAction.preview),
      ),
      if (permissions.canSend &&
          stage != EstimateStage.draft &&
          record.companyReviewAllowsCustomerApproval)
        _ActionTile(
          key: const ValueKey('estimate-delivery-action'),
          icon: Icons.picture_as_pdf_outlined,
          title: 'Send or share estimate',
          detail:
              'Choose email, secure text link, device share, save, or print.',
          accent: semantic.current,
          surface: semantic.currentSurface,
          onTap: () => _finish(context, EstimateAction.delivery),
        ),
      if (stage != EstimateStage.converted &&
          stage != EstimateStage.draft &&
          record.companyReviewAllowsCustomerApproval &&
          permissions.canCollectSignature)
        _ActionTile(
          key: const ValueKey('estimate-signature-action'),
          icon: Icons.draw_outlined,
          title: 'Sign in person',
          detail: 'Record customer approval for this exact revision.',
          accent: semantic.planned,
          surface: semantic.plannedSurface,
          onTap: () => _finish(context, EstimateAction.signature),
        ),
    ];
    return Scaffold(
      key: const ValueKey('estimate-actions-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.detailWorkspaceFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
              children: [
                Center(
                  child: SizedBox(
                    width: layout.columnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: 'Estimate actions',
                          selectedDay:
                              record.estimateDates?.createdOn ??
                              record.createdOn ??
                              DateTime.now(),
                          onBack: () => Navigator.of(context).pop(),
                          showDateContext: true,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          record.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          '${record.number} · Revision ${record.revision} · ${stage.label}',
                        ),
                        if (statusActions.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          const _GroupHeading('Next step'),
                          const SizedBox(height: 8),
                          ..._spaced(statusActions),
                        ],
                        const SizedBox(height: 14),
                        const _GroupHeading('Estimate record'),
                        const SizedBox(height: 8),
                        ..._spaced(recordActions),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static List<Widget> _spaced(List<Widget> actions) => [
    for (var index = 0; index < actions.length; index++) ...[
      actions[index],
      if (index != actions.length - 1) const SizedBox(height: 8),
    ],
  ];

  static void _finish(BuildContext context, EstimateAction action) =>
      Navigator.of(context).pop(action);
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.accent,
    required this.surface,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color accent;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    backgroundColor: surface,
    borderColor: accent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(detail),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

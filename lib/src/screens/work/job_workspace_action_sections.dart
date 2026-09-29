part of 'job_workspace_screen.dart';

class _ReceiptsSection extends StatelessWidget {
  const _ReceiptsSection({
    required this.job,
    required this.sitePhotos,
    required this.onViewPhoto,
    required this.canLinkExpense,
    required this.canAttach,
    required this.canAttachPhotos,
    required this.onLinkExpense,
    required this.onAttachReceipt,
    required this.onAttachJobPhoto,
  });

  final ActiveJobRecord job;
  final List<WorkSitePhoto> sitePhotos;
  final ValueChanged<WorkSitePhoto> onViewPhoto;
  final bool canLinkExpense;
  final bool canAttach;
  final bool canAttachPhotos;
  final VoidCallback onLinkExpense;
  final VoidCallback onAttachReceipt;
  final VoidCallback onAttachJobPhoto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final receipts = job.receipts
        .where((item) => item.kind != JobAttachmentKind.jobPhoto)
        .toList();
    final photos = job.receipts
        .where((item) => item.kind == JobAttachmentKind.jobPhoto)
        .toList();
    return _WorkspaceSection(
      title: 'Job photos and receipts',
      icon: Icons.attach_file_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: colors.surfaceContainerLow,
            child: const Text(
              'Add receipts for purchases tied to this job, or add photos that document the work. '
              'Extracted receipt details never change another record until you review and confirm them.',
            ),
          ),
          if (canLinkExpense || canAttach || canAttachPhotos) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canLinkExpense)
                  FilledButton.icon(
                    key: const ValueKey('job-link-expense'),
                    onPressed: onLinkExpense,
                    icon: const Icon(Icons.link_outlined),
                    label: const Text('Link existing expense'),
                  ),
                if (canAttach) ...[
                  OutlinedButton.icon(
                    key: const ValueKey('job-attach-receipt'),
                    onPressed: onAttachReceipt,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Add receipt'),
                  ),
                ],
                if (canAttachPhotos) ...[
                  OutlinedButton.icon(
                    key: const ValueKey('job-attach-photo'),
                    onPressed: onAttachJobPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Add job photo'),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Receipts and linked expenses',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (receipts.isEmpty)
            Text(
              'No receipts or expenses linked.',
              style: TextStyle(color: colors.onSurfaceVariant),
            )
          else
            for (final receipt in receipts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(receipt.name),
                subtitle: Text('${receipt.source} · ${receipt.status}'),
              ),
          const SizedBox(height: 12),
          const Text(
            'Job photos',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (photos.isEmpty && sitePhotos.isEmpty)
            Text(
              'No job photos attached.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          for (final photo in sitePhotos)
            ListTile(
              key: ValueKey('job-photo-${photo.id}'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_outlined),
              title: Text(photo.name),
              subtitle: photo.note.isEmpty ? null : Text(photo.note),
              trailing: const Icon(Icons.open_in_new_outlined),
              onTap: () => onViewPhoto(photo),
            ),
          if (photos.isNotEmpty)
            for (final photo in photos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_outlined),
                title: Text(photo.name),
                subtitle: Text('${photo.source} · ${photo.status}'),
              ),
        ],
      ),
    );
  }
}

class _JobActions extends StatelessWidget {
  const _JobActions({
    required this.job,
    required this.permissions,
    required this.onStatus,
    required this.onReschedule,
    required this.onReassign,
  });

  final ActiveJobRecord job;
  final JobWorkspacePermissions permissions;
  final ValueChanged<JobStatus> onStatus;
  final VoidCallback onReschedule;
  final VoidCallback onReassign;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (permissions.canChangeStatus)
        for (final action in _JobActionsScreen._statusActions(job.status))
          _JobActionButton(
            key: ValueKey('job-inline-${action.name}'),
            filled: action != _JobAction.pauseWork,
            icon: action.icon,
            label: action.label,
            onPressed: () => onStatus(action.targetStatus!),
          ),
      if (permissions.canEditJob &&
          (PrototypeOperationsScope.maybeOf(
                context,
              )?.workSession?.permissions.canScheduleJobs ??
              true))
        _JobActionButton(
          icon: Icons.event_repeat_outlined,
          label: 'Reschedule job',
          onPressed: onReschedule,
        ),
      if (permissions.canEditJob)
        _JobActionButton(
          icon: Icons.person_add_alt_1_outlined,
          label: 'Reassign job',
          onPressed: onReassign,
        ),
      if (permissions.canChangeStatus)
        PopupMenuButton<JobStatus>(
          initialValue: job.status,
          onSelected: onStatus,
          itemBuilder: (_) => [
            for (final status in JobStatus.values)
              PopupMenuItem(value: status, child: Text(status.label)),
          ],
          child: const _JobActionButtonContent(
            icon: Icons.swap_horiz_outlined,
            label: 'Change status',
          ),
        ),
    ];
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 21;
    return _WorkspaceSection(
      title: 'Job actions',
      icon: Icons.task_alt_outlined,
      child: largeText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  actions[index],
                  if (index != actions.length - 1) const SizedBox(height: 8),
                ],
              ],
            )
          : Wrap(spacing: 8, runSpacing: 8, children: actions),
    );
  }
}

class _JobActionButton extends StatelessWidget {
  const _JobActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = _JobActionButtonContent(icon: icon, label: label);
    return filled
        ? FilledButton(onPressed: onPressed, child: child)
        : OutlinedButton(onPressed: onPressed, child: child);
  }
}

class _JobActionButtonContent extends StatelessWidget {
  const _JobActionButtonContent({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(child: Text(label)),
      ],
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Text(
        status.label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

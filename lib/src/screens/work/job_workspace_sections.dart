part of 'job_workspace_screen.dart';

class _JobIdentity extends StatelessWidget {
  const _JobIdentity({required this.job});
  final ActiveJobRecord job;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SectionCard(
      backgroundColor: colors.surfaceContainerLow,
      child: Wrap(
        spacing: 18,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            Icons.home_repair_service_outlined,
            size: 30,
            color: colors.primary,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${job.id} · ${job.customerName} · ${job.scheduledTime}',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          _StatusLabel(status: job.status),
        ],
      ),
    );
  }
}

class _WorkspaceSection extends StatelessWidget {
  const _WorkspaceSection({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 9, 8, 9),
            color: colors.surfaceContainerHigh,
            child: Row(
              children: [
                Icon(icon, size: 19, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({
    required this.job,
    required this.canContact,
    required this.onContact,
  });
  final ActiveJobRecord job;
  final bool canContact;
  final ValueChanged<_CustomerContactAction> onContact;

  @override
  Widget build(BuildContext context) => _WorkspaceSection(
    title: 'Customer and job location',
    icon: Icons.person_pin_circle_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Info(label: 'Customer', value: job.customerName),
        _Info(label: 'Address', value: job.serviceAddress),
        _Info(label: 'Phone', value: job.customerPhone),
        _Info(label: 'Email', value: job.customerEmail),
        if (canContact) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => onContact(_CustomerContactAction.call),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
                icon: const Icon(Icons.call_outlined),
                label: const Text('Call customer'),
              ),
              OutlinedButton.icon(
                onPressed: () => onContact(_CustomerContactAction.message),
                icon: const Icon(Icons.message_outlined),
                label: const Text('Message customer'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Calling uses this device\'s phone service or a connected phone.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ],
    ),
  );
}

class _ScopeSection extends StatelessWidget {
  const _ScopeSection({required this.job});
  final ActiveJobRecord job;
  @override
  Widget build(BuildContext context) => _WorkspaceSection(
    title: 'What needs to be done',
    icon: Icons.assignment_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(job.description),
        const SizedBox(height: 12),
        _Info(label: 'Assigned to', value: job.assignedTechnician),
        _Info(label: 'Work vehicle', value: job.assignedVehicle),
        _Info(label: 'Appointment', value: job.scheduledTime),
      ],
    ),
  );
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.job,
    required this.canEdit,
    required this.onEdit,
  });
  final ActiveJobRecord job;
  final bool canEdit;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) => _WorkspaceSection(
    title: 'Notes for this job',
    icon: Icons.note_alt_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(job.technicianNotes),
        if (canEdit) ...[
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit notes'),
            ),
          ),
        ],
      ],
    ),
  );
}

class _EstimateSection extends StatelessWidget {
  const _EstimateSection({
    required this.job,
    required this.canAdd,
    required this.canViewCustomerPrice,
    required this.onAdd,
  });
  final ActiveJobRecord job;
  final bool canAdd;
  final bool canViewCustomerPrice;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final materials = job.lineItems
        .where(
          (item) => item.kind == JobLineKind.material && !item.isJobAddition,
        )
        .toList();
    final labor = job.lineItems
        .where((item) => item.kind == JobLineKind.labor && !item.isJobAddition)
        .toList();
    final other = job.lineItems
        .where(
          (item) =>
              (item.kind == JobLineKind.equipment ||
                  item.kind == JobLineKind.fee) &&
              !item.isJobAddition,
        )
        .toList();
    final additions = job.lineItems
        .where((item) => item.isJobAddition)
        .toList();
    return _WorkspaceSection(
      title: 'Materials and labor for this job',
      icon: Icons.request_quote_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Info(label: 'Estimate', value: job.estimateNumber),
          _Info(label: 'Pricing', value: job.estimateTerms),
          if (canAdd) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const ValueKey('job-add-material'),
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add materials'),
              ),
            ),
          ],
          const Divider(height: 22),
          const Text(
            'Quoted items remain separate from additions recorded during the job.',
          ),
          const SizedBox(height: 14),
          _LineItemGroup(
            title: 'Materials list',
            items: materials,
            canViewCustomerPrice: canViewCustomerPrice,
          ),
          if (labor.isNotEmpty) ...[
            const SizedBox(height: 14),
            _LineItemGroup(
              title: 'Labor included',
              items: labor,
              canViewCustomerPrice: canViewCustomerPrice,
            ),
          ],
          if (other.isNotEmpty) ...[
            const SizedBox(height: 14),
            _LineItemGroup(
              title: 'Other charges',
              items: other,
              canViewCustomerPrice: canViewCustomerPrice,
            ),
          ],
          if (additions.isNotEmpty) ...[
            const SizedBox(height: 14),
            _LineItemGroup(
              title: 'Added during this job',
              items: additions,
              canViewCustomerPrice: canViewCustomerPrice,
            ),
          ],
          if (canViewCustomerPrice) ...[
            const Divider(height: 22),
            _JobAmountRow(
              label: 'Quoted or planned total',
              amount: job.quotedTotal,
              emphasize: true,
            ),
            if (job.invoiceCandidateTotal > 0)
              _JobAmountRow(
                label: 'For invoice review',
                amount: job.invoiceCandidateTotal,
              ),
            if (job.approvalRequiredTotal > 0)
              _JobAmountRow(
                label: 'Customer approval required',
                amount: job.approvalRequiredTotal,
              ),
          ],
        ],
      ),
    );
  }
}

class _LineItemGroup extends StatelessWidget {
  const _LineItemGroup({
    required this.title,
    required this.items,
    required this.canViewCustomerPrice,
  });
  final String title;
  final List<JobLineItem> items;
  final bool canViewCustomerPrice;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      if (items.isEmpty)
        Text(
          'None listed.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        )
      else
        for (var index = 0; index < items.length; index++) ...[
          _LineItemRow(
            item: items[index],
            canViewCustomerPrice: canViewCustomerPrice,
          ),
          if (index != items.length - 1) const Divider(height: 18),
        ],
    ],
  );
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({required this.item, required this.canViewCustomerPrice});
  final JobLineItem item;
  final bool canViewCustomerPrice;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final source = item.sourceStockId != null
        ? 'Used from recorded truck stock'
        : item.sourceExpenseId != null
        ? 'Linked to a recorded expense or receipt'
        : item.isJobAddition
        ? 'Added during this job'
        : null;
    final treatment = item.isJobAddition
        ? item.resolvedJobMaterialBillingTreatment
        : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(item.kind.icon, size: 18, color: colors.onSurfaceVariant),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.description,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                canViewCustomerPrice
                    ? '${_quantity(item.quantity)} ${item.unit} × ${jobMoney(item.unitPrice)}'
                    : '${_quantity(item.quantity)} ${item.unit}',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              if (treatment != null)
                Text(
                  treatment.statusLabel,
                  style: TextStyle(
                    color: treatment == JobMaterialBillingTreatment.nonBillable
                        ? colors.onSurfaceVariant
                        : colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (item.technicianNote case final note?)
                Text(
                  note,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              if (source != null)
                Text(
                  source,
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (treatment == JobMaterialBillingTreatment.nonBillable)
          const Text(
            'Not billed',
            style: TextStyle(fontWeight: FontWeight.w600),
          )
        else if (canViewCustomerPrice)
          Text(
            jobMoney(item.total),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

class _JobAmountRow extends StatelessWidget {
  const _JobAmountRow({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final double amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          jobMoney(amount),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: emphasize ? 16 : 14,
          ),
        ),
      ],
    ),
  );
}

String _quantity(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);

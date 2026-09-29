part of 'work_job_editor.dart';

class _JobFormError extends StatelessWidget {
  const _JobFormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return SectionCard(
      borderColor: semantic.danger,
      backgroundColor: semantic.dangerSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: semantic.danger),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _SourceEstimateBanner extends StatelessWidget {
  const _SourceEstimateBanner({required this.record});

  final WorkRecord record;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return SectionCard(
      borderColor: semantic.success,
      backgroundColor: semantic.successSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.verified_outlined, color: semantic.success),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Approved ${record.kind == WorkRecordKind.quote ? 'quote' : 'estimate'} ${record.number}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Revision ${record.revision} stays unchanged and linked to this job.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobIdentitySection extends StatelessWidget {
  const _JobIdentitySection({
    required this.number,
    required this.title,
    required this.purchaseOrder,
    required this.scope,
    required this.customers,
    required this.selectedClient,
    required this.selectedLocation,
    required this.locations,
    required this.pricing,
    required this.onClientChanged,
    required this.onLocationChanged,
    required this.onAddClient,
    required this.onPricingChanged,
  });

  final String number;
  final TextEditingController title;
  final TextEditingController purchaseOrder;
  final TextEditingController scope;
  final List<WorkCustomerProfile> customers;
  final String? selectedClient;
  final String? selectedLocation;
  final List<WorkServiceLocation> locations;
  final WorkPricingModel pricing;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String?> onLocationChanged;
  final VoidCallback onAddClient;
  final ValueChanged<WorkPricingModel>? onPricingChanged;

  @override
  Widget build(BuildContext context) => UtilityFormSection(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Customer and work',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 3),
        Text(number),
        const SizedBox(height: 12),
        TextField(
          controller: purchaseOrder,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Purchase order number (optional)',
          ),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const ValueKey('job-client-field'),
          child: DropdownButtonFormField<String>(
            key: ValueKey('job-client-value-${selectedClient ?? 'none'}'),
            initialValue: selectedClient,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Client'),
            items: [
              if (selectedClient != null &&
                  !customers.any((customer) => customer.name == selectedClient))
                DropdownMenuItem(
                  value: selectedClient,
                  child: Text(selectedClient!),
                ),
              for (final customer in customers)
                DropdownMenuItem(
                  value: customer.name,
                  child: Text(customer.name),
                ),
            ],
            onChanged: onClientChanged,
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('job-add-client'),
            onPressed: onAddClient,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Add new client'),
          ),
        ),
        KeyedSubtree(
          key: const ValueKey('job-location-field'),
          child: DropdownButtonFormField<String>(
            key: ValueKey('job-location-value-${selectedLocation ?? 'none'}'),
            initialValue: selectedLocation,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Service location'),
            items: [
              if (selectedLocation != null &&
                  !locations.any(
                    (location) => location.address == selectedLocation,
                  ))
                DropdownMenuItem(
                  value: selectedLocation,
                  child: Text(selectedLocation!),
                ),
              for (final location in locations)
                DropdownMenuItem(
                  value: location.address,
                  child: Text(location.label),
                ),
            ],
            onChanged: locations.isEmpty ? null : onLocationChanged,
          ),
        ),
        if (selectedLocation != null) ...[
          const SizedBox(height: 5),
          Text(
            selectedLocation!.replaceAll('\n', ', '),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('job-title-field'),
          controller: title,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Job title',
            hintText: 'Example: Replace kitchen faucet',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('job-scope-field'),
          controller: scope,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'What needs to be done',
            helperText: 'The assigned team sees these instructions in the job.',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<WorkPricingModel>(
          initialValue: pricing,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Pricing method'),
          items: const [
            DropdownMenuItem(
              value: WorkPricingModel.flatRate,
              child: Text('Flat rate'),
            ),
            DropdownMenuItem(
              value: WorkPricingModel.timeAndMaterials,
              child: Text('Time and materials'),
            ),
          ],
          onChanged: onPricingChanged == null
              ? null
              : (value) {
                  if (value != null) onPricingChanged!(value);
                },
        ),
      ],
    ),
  );
}

class _JobScheduleSection extends StatelessWidget {
  const _JobScheduleSection({
    required this.start,
    required this.end,
    required this.bufferMinutes,
    required this.onBufferChanged,
    this.onFindOpening,
    required this.onStartDay,
    required this.onStartTime,
    required this.onEndDay,
    required this.onEndTime,
  });

  final DateTime start;
  final DateTime end;
  final int bufferMinutes;
  final ValueChanged<int> onBufferChanged;
  final VoidCallback? onFindOpening;
  final VoidCallback onStartDay;
  final VoidCallback onStartTime;
  final VoidCallback onEndDay;
  final VoidCallback onEndTime;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final localizations = MaterialLocalizations.of(context);
    return SectionCard(
      borderColor: semantic.planned,
      backgroundColor: semantic.plannedSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Schedule', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('job-start-date'),
                onPressed: onStartDay,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(localizations.formatMediumDate(start)),
              ),
              OutlinedButton.icon(
                key: const ValueKey('job-start-time'),
                onPressed: onStartTime,
                icon: const Icon(Icons.schedule_outlined),
                label: Text(
                  localizations.formatTimeOfDay(TimeOfDay.fromDateTime(start)),
                ),
              ),
              OutlinedButton.icon(
                key: const ValueKey('job-end-date'),
                onPressed: onEndDay,
                icon: const Icon(Icons.event_available_outlined),
                label: Text(localizations.formatMediumDate(end)),
              ),
              OutlinedButton.icon(
                key: const ValueKey('job-end-time'),
                onPressed: onEndTime,
                icon: const Icon(Icons.more_time_outlined),
                label: Text(
                  localizations.formatTimeOfDay(TimeOfDay.fromDateTime(end)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            key: const ValueKey('job-schedule-gap'),
            initialValue: bufferMinutes,
            decoration: const InputDecoration(
              labelText: 'Minimum gap between jobs',
              helperText:
                  'Leave time for travel, cleanup, or a job running long.',
            ),
            items:
                [
                      0,
                      15,
                      30,
                      60,
                      120,
                      if (!const [0, 15, 30, 60, 120].contains(bufferMinutes))
                        bufferMinutes,
                    ]
                    .map(
                      (minutes) => DropdownMenuItem(
                        value: minutes,
                        child: Text(
                          minutes == 0 ? 'No gap' : '$minutes minutes',
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) onBufferChanged(value);
            },
          ),
          if (onFindOpening != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton(
                key: const ValueKey('new-job-find-opening'),
                onPressed: onFindOpening,
                child: const Text('Find an opening'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JobAssignmentSection extends StatelessWidget {
  const _JobAssignmentSection({
    required this.assignee,
    required this.employeeIds,
    required this.onEmployeesChanged,
    required this.beforeAddEmployee,
    required this.vehicle,
    required this.onAssigneeChanged,
    required this.onVehicleChanged,
  });

  final String? assignee;
  final List<String> employeeIds;
  final ValueChanged<List<String>> onEmployeesChanged;
  final Future<void> Function() beforeAddEmployee;
  final String? vehicle;
  final ValueChanged<String?> onAssigneeChanged;
  final ValueChanged<String?> onVehicleChanged;

  @override
  Widget build(BuildContext context) => UtilityFormSection(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Assignment', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text('A scheduled job may remain unassigned for dispatch.'),
        const SizedBox(height: 12),
        if (PrototypeOperationsScope.of(context).directorySession != null) ...[
          for (final employee
              in PrototypeOperationsScope.of(context)
                  .directorySession!
                  .employees
                  .where((e) => e.active || employeeIds.contains(e.id)))
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                employee.active ? employee.name : "${employee.name} (inactive)",
              ),
              value: employeeIds.contains(employee.id),
              onChanged: (checked) => onEmployeesChanged([
                ...employeeIds.where((id) => id != employee.id),
                if (checked == true) employee.id,
              ]),
            ),
          AddJobEmployeeButton(
            beforeOpen: beforeAddEmployee,
            onCreated: (employee) =>
                onEmployeesChanged([...employeeIds, employee.id]),
          ),
          if (PrototypeOperationsScope.of(
            context,
          ).directorySession!.employees.isEmpty)
            const Text(
              'No employees added yet. You can assign this job later.',
            ),
        ] else
          DropdownButtonFormField<String>(
            key: const ValueKey('job-assignee-field'),
            initialValue: assignee,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Employee'),
            items: [
              for (final employee in demoEmployees)
                DropdownMenuItem(
                  value: employee.name,
                  child: Text(employee.name),
                ),
            ],
            onChanged: onAssigneeChanged,
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const ValueKey('job-vehicle-field'),
          initialValue: vehicle,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Vehicle'),
          items: [
            for (final name
                in (PrototypeOperationsScope.of(
                      context,
                    ).directorySession?.vehicles.map((v) => v.name) ??
                    demoVehicles.map((v) => v.name)))
              DropdownMenuItem(value: name, child: Text(name)),
          ],
          onChanged: onVehicleChanged,
        ),
      ],
    ),
  );
}

class _JobItemsSection extends StatelessWidget {
  const _JobItemsSection({
    required this.itemCount,
    required this.total,
    required this.lockedToEstimate,
    required this.onOpen,
  });

  final int itemCount;
  final double total;
  final bool lockedToEstimate;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    child: ListTile(
      key: const ValueKey('job-items-section'),
      minTileHeight: 60,
      leading: const Icon(Icons.inventory_2_outlined),
      title: Text(lockedToEstimate ? 'Approved work items' : 'Job items'),
      subtitle: Text(
        itemCount == 0
            ? 'Add labor, materials, or other charges'
            : '$itemCount ${itemCount == 1 ? 'item' : 'items'} · \$${total.toStringAsFixed(2)}',
      ),
      trailing: Icon(
        lockedToEstimate
            ? Icons.lock_outline_rounded
            : Icons.chevron_right_rounded,
      ),
      onTap: lockedToEstimate ? null : onOpen,
    ),
  );
}

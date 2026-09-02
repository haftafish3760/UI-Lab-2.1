import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'customer_edit_screen.dart';
import 'estimate_detail_screen.dart';
import 'estimate_editor_screen.dart';
import 'estimate_models.dart';
import 'work_job_editor.dart';
import 'work_contact_models.dart';
import 'work_detail_header.dart';
import 'work_models.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({
    required this.initialCustomer,
    required this.selectedDay,
    super.key,
  });

  final WorkCustomerProfile initialCustomer;
  final DateTime selectedDay;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late var _customer = widget.initialCustomer;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          final available = math.max(
            0,
            constraints.maxWidth - insets.horizontal,
          );
          final layout = AppLayoutEngine.detailWorkspaceFor(
            available.toDouble(),
            textScaler: MediaQuery.textScalerOf(context),
          );
          return ListView(
            padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
            children: [
              Center(
                child: SizedBox(
                  width: layout.workspaceWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WorkDetailHeader(
                        label: 'Client Details',
                        selectedDay: widget.selectedDay,
                        onBack: () => Navigator.of(context).pop(_customer),
                      ),
                      const SizedBox(height: 18),
                      _CustomerIdentity(customer: _customer, onEdit: _edit),
                      const SizedBox(height: 14),
                      _CustomerEstimates(
                        estimates: _customerEstimates,
                        onOpen: _openEstimate,
                        onCreate: _createEstimate,
                      ),
                      const SizedBox(height: 14),
                      _CustomerDetailLanes(customer: _customer, layout: layout),
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

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<WorkCustomerProfile>(
      MaterialPageRoute(
        builder: (_) => CustomerEditScreen(
          initialCustomer: _customer,
          selectedDay: widget.selectedDay,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() => _customer = updated);
  }

  List<WorkRecord> get _customerEstimates =>
      PrototypeOperationsScope.of(context).workRecords
          .where(
            (record) =>
                record.kind == WorkRecordKind.estimate &&
                record.client == _customer.name,
          )
          .toList()
        ..sort(
          (left, right) => (right.createdOn ?? DateTime(0)).compareTo(
            left.createdOn ?? DateTime(0),
          ),
        );

  Future<void> _createEstimate() async {
    final store = PrototypeOperationsScope.of(context);
    final estimate = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => EstimateEditorScreen(
          initialDay: widget.selectedDay,
          initialClient: _customer.name,
        ),
      ),
    );
    if (!mounted || estimate == null) return;
    store.addWorkRecord(estimate);
    setState(() {});
  }

  Future<void> _openEstimate(WorkRecord estimate) async {
    final store = PrototypeOperationsScope.of(context);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EstimateDetailScreen(
          initialRecord: estimate,
          onUpdated: store.updateWorkRecord,
          onCreateJob: _createJob,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _createJob(WorkRecord estimate) async {
    final store = PrototypeOperationsScope.of(context);
    final job = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => WorkJobEditor(
          sourceEstimate: estimate,
          initialDay:
              estimate.estimateDates?.proposedServiceOn ?? widget.selectedDay,
        ),
      ),
    );
    if (!mounted || job == null) return;
    store.addWorkRecord(job);
    store.updateWorkRecord(
      estimate.withEstimateStage(EstimateStage.converted, DateTime.now()),
    );
  }
}

class _CustomerEstimates extends StatelessWidget {
  const _CustomerEstimates({
    required this.estimates,
    required this.onOpen,
    required this.onCreate,
  });

  final List<WorkRecord> estimates;
  final ValueChanged<WorkRecord> onOpen;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final active = estimates
        .where((estimate) => estimate.resolvedEstimateStage.isOpen)
        .toList();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active estimates',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('${active.length} active · ${estimates.length} total'),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('New estimate'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (estimates.isEmpty)
            const Text('No estimates are linked to this client yet.')
          else
            for (final estimate in estimates) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(estimate.title),
                subtitle: Text(
                  '${estimate.number} · ${estimate.resolvedEstimateStage.label}',
                ),
                trailing: Text('\$${estimate.total.toStringAsFixed(2)}'),
                onTap: () => onOpen(estimate),
              ),
              if (estimate != estimates.last) const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _CustomerIdentity extends StatelessWidget {
  const _CustomerIdentity({required this.customer, required this.onEdit});

  final WorkCustomerProfile customer;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 10,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.name, style: Theme.of(context).textTheme.titleLarge),
            if (customer.companyName.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(customer.companyName),
            ],
            const SizedBox(height: 3),
            Text('${customer.linkedRecordCount} linked Work records'),
          ],
        ),
        FilledButton.icon(
          key: const ValueKey('edit-customer-button'),
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit client information'),
        ),
      ],
    ),
  );
}

class _CustomerDetailLanes extends StatelessWidget {
  const _CustomerDetailLanes({required this.customer, required this.layout});

  final WorkCustomerProfile customer;
  final DetailWorkspaceLayout layout;

  @override
  Widget build(BuildContext context) {
    final contact = _CustomerSection(
      title: 'Contact and billing',
      icon: Icons.contact_phone_outlined,
      children: [
        _DetailValue(label: 'Phone', value: customer.phone),
        _DetailValue(label: 'Email', value: customer.email),
        _DetailValue(
          label: 'Preferred contact',
          value: customer.preferredContact,
        ),
        _DetailValue(label: 'Billing address', value: customer.billingAddress),
      ],
    );
    final locations = _CustomerSection(
      title: 'Service locations',
      icon: Icons.location_on_outlined,
      children: [
        for (final location in customer.locations)
          _LocationDetail(location: location),
      ],
    );
    final notes = _CustomerSection(
      title: 'Notes and history',
      icon: Icons.history_rounded,
      children: [
        _DetailValue(label: 'Client notes', value: customer.notes),
        _DetailValue(
          label: 'Linked history',
          value:
              '${customer.linkedRecordCount} estimates, jobs, invoices, payments, or related Work records',
        ),
      ],
    );
    if (layout.columns == 1) {
      return Column(
        children: [
          contact,
          SizedBox(height: layout.gap),
          locations,
          SizedBox(height: layout.gap),
          notes,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: layout.columnWidth,
          child: Column(
            children: [
              contact,
              SizedBox(height: layout.gap),
              notes,
            ],
          ),
        ),
        SizedBox(width: layout.gap),
        SizedBox(width: layout.columnWidth, child: locations),
      ],
    );
  }
}

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1) const Divider(height: 20),
        ],
      ],
    ),
  );
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}

class _LocationDetail extends StatelessWidget {
  const _LocationDetail({required this.location});

  final WorkServiceLocation location;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(location.label, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(location.address),
      if (location.accessNotes.isNotEmpty) ...[
        const SizedBox(height: 5),
        Text(
          'Access: ${location.accessNotes}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );
}

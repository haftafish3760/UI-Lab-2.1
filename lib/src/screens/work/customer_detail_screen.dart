import '../../../l10n/app_localizations_extension.dart';
import '../../data/work/customer_work_history.dart';
import 'work_overview_scope.dart';
import 'invoice_detail_screen.dart';
import 'job_workspace_screen.dart';
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

part 'customer_detail_sections.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({
    required this.initialCustomer,
    required this.selectedDay,
    this.selectForDocument = false,
    super.key,
  });

  final WorkCustomerProfile initialCustomer;
  final DateTime selectedDay;
  final bool selectForDocument;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late var _customer = widget.initialCustomer;

  bool get _canViewCustomer =>
      PrototypeOperationsScope.of(
        context,
      ).directorySession?.permissions.canViewCustomers ??
      true;
  bool get _canEditCustomer =>
      _canViewCustomer &&
      (PrototypeOperationsScope.of(
            context,
          ).directorySession?.permissions.canManageCustomers ??
          true);
  bool get _canCreateEstimate =>
      PrototypeOperationsScope.of(context)
          .workSession
          ?.permissions
          .editableKinds
          .contains(WorkRecordKind.estimate) ??
      true;

  @override
  Widget build(BuildContext context) {
    if (!_canViewCustomer) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client information')),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('You do not have permission to view saved clients.'),
          ),
        ),
      );
    }
    final directory = PrototypeOperationsScope.of(context).directorySession;
    if (directory != null) {
      final current = directory.customers
          .where((c) => c.id == _customer.id)
          .firstOrNull;
      if (current == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Client information')),
          body: const SafeArea(
            child: Text('This client is no longer available.'),
          ),
        );
      }
      _customer = current;
    }
    return Scaffold(
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
                          onBack: () => Navigator.of(
                            context,
                          ).pop(widget.selectForDocument ? null : _customer),
                        ),
                        if (widget.selectForDocument)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              key: const ValueKey('select-client-for-document'),
                              onPressed: () {
                                if (!_canViewCustomer) return;
                                final currentDirectory =
                                    PrototypeOperationsScope.of(
                                      context,
                                    ).directorySession;
                                final selected = currentDirectory == null
                                    ? _customer
                                    : currentDirectory.customers
                                          .where((c) => c.id == _customer.id)
                                          .firstOrNull;
                                if (selected != null) {
                                  Navigator.of(context).pop(selected);
                                }
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: Text(context.l10n.workUseClient),
                            ),
                          ),
                        const SizedBox(height: 18),
                        _CustomerIdentity(
                          customer: _customer,
                          recordCount: _customerEstimates.length,
                          onEdit: _canEditCustomer ? _edit : null,
                        ),
                        const SizedBox(height: 14),
                        _CustomerEstimates(
                          estimates: _customerEstimates,
                          onOpen: _openEstimate,
                          onCreate: _canCreateEstimate ? _createEstimate : null,
                        ),
                        const SizedBox(height: 14),
                        _CustomerDetailLanes(
                          customer: _customer,
                          recordCount: _customerEstimates.length,
                          layout: layout,
                        ),
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

  Future<void> _edit() async {
    if (!_canEditCustomer) return;
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

  List<WorkRecord> get _customerEstimates => customerWorkHistory(
    customer: _customer,
    directory: PrototypeOperationsScope.of(context).customers,
    visibleRecords: visibleWorkOverviewRecords(context),
  );

  Future<void> _createEstimate() async {
    if (!_canViewCustomer || !_canCreateEstimate) return;
    final store = PrototypeOperationsScope.of(context);
    final estimate = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => EstimateEditorScreen(
          initialDay: widget.selectedDay,
          initialClient: _customer.name,
          initialCustomer: _customer,
          createdByEmployeeId: store.workSession?.permissions.actorEmployeeId,
        ),
      ),
    );
    if (!mounted || estimate == null) return;
    store.addWorkRecord(estimate);
    setState(() {});
  }

  Future<void> _openEstimate(WorkRecord estimate) async {
    if (!_canViewCustomer) return;
    final current = _customerEstimates
        .where((record) => record.id == estimate.id)
        .firstOrNull;
    if (current == null) return;
    estimate = current;
    if (estimate.kind != WorkRecordKind.estimate) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => estimate.kind == WorkRecordKind.invoice
              ? InvoiceDetailScreen(record: estimate)
              : JobWorkspaceScreen(
                  workRecord: estimate,
                  onWorkRecordUpdated: PrototypeOperationsScope.of(
                    context,
                  ).updateWorkRecord,
                ),
        ),
      );
      return;
    }
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
    if (store.workSession == null) {
      store.addWorkRecord(job);
      store.updateWorkRecord(
        estimate.withEstimateStage(EstimateStage.converted, DateTime.now()),
      );
    }
  }
}

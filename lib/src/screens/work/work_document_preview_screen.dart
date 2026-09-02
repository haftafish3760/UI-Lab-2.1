import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'estimate_models.dart';
import 'work_contact_models.dart';
import 'work_detail_header.dart';
import 'estimate_items_screen.dart';
import 'work_models.dart';

part 'work_document_preview_actions.dart';

enum WorkDocumentPreviewAction { createJob, deliver }

class WorkDocumentPreviewScreen extends StatefulWidget {
  const WorkDocumentPreviewScreen({
    required this.record,
    this.onRecordUpdated,
    this.canDeliverCustomerCopy,
    super.key,
  });

  final WorkRecord record;
  final ValueChanged<WorkRecord>? onRecordUpdated;
  final bool? canDeliverCustomerCopy;

  @override
  State<WorkDocumentPreviewScreen> createState() =>
      _WorkDocumentPreviewScreenState();
}

class _WorkDocumentPreviewScreenState extends State<WorkDocumentPreviewScreen> {
  late WorkRecord _record = widget.record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey('document-preview-${_record.id}'),
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
                    width: layout.workspaceWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: '${_record.kind.label} preview',
                          selectedDay:
                              _record.createdOn ??
                              DateUtils.dateOnly(DateTime.now()),
                          onBack: () => Navigator.of(context).pop(),
                          showDateContext: true,
                        ),
                        const SizedBox(height: 16),
                        _PreviewHeading(
                          record: _record,
                          canDeliverCustomerCopy: _canDeliverCustomerCopy,
                          onDelivery: _requestDelivery,
                        ),
                        const SizedBox(height: 12),
                        _DocumentPage(record: _record),
                        if (_record.kind == WorkRecordKind.estimate) ...[
                          const SizedBox(height: 12),
                          _CustomerApprovalStatus(record: _record),
                        ],
                        const SizedBox(height: 12),
                        _DocumentActions(
                          record: _record,
                          onEditItems: widget.onRecordUpdated == null
                              ? null
                              : _editItems,
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

  Future<void> _editItems() async {
    final items = await Navigator.of(context).push<List<WorkLineItem>>(
      MaterialPageRoute(
        builder: (_) => EstimateItemsScreen(
          initialItems: _record.items,
          pricing: _record.pricing,
          selectedDay: _record.estimateDates?.createdOn ?? _record.createdOn,
        ),
      ),
    );
    if (!mounted || items == null) return;
    final updated = _record.reviseItems(items, changedOn: DateTime.now());
    if (identical(updated, _record)) return;
    setState(() => _record = updated);
    widget.onRecordUpdated?.call(updated);
  }

  bool get _canDeliverCustomerCopy {
    if (widget.canDeliverCustomerCopy != null) {
      return widget.canDeliverCustomerCopy!;
    }
    if (_record.kind != WorkRecordKind.estimate) return true;
    return _record.resolvedEstimateStage != EstimateStage.draft &&
        _record.companyReviewAllowsCustomerApproval;
  }

  void _requestDelivery() {
    if (_record.kind == WorkRecordKind.estimate) {
      Navigator.of(context).pop(WorkDocumentPreviewAction.deliver);
      return;
    }
    _showPdfDeliveryOptions(context, _record);
  }
}

class _PreviewHeading extends StatelessWidget {
  const _PreviewHeading({
    required this.record,
    required this.canDeliverCustomerCopy,
    required this.onDelivery,
  });
  final WorkRecord record;
  final bool canDeliverCustomerCopy;
  final VoidCallback onDelivery;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 8,
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 3),
            Text(
              'Customer-facing ${record.kind.label.toLowerCase()} · ${record.status.label}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      if (record.kind != WorkRecordKind.estimate || canDeliverCustomerCopy)
        OutlinedButton.icon(
          key: const ValueKey('document-delivery-action'),
          onPressed: onDelivery,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(
            record.kind == WorkRecordKind.estimate
                ? 'Continue to send or share'
                : 'PDF delivery options',
          ),
        )
      else
        _PreviewDeliveryGate(record: record),
    ],
  );
}

class _DocumentPage extends StatelessWidget {
  const _DocumentPage({required this.record});
  final WorkRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final store = PrototypeOperationsScope.of(context);
    final customer = _customerFor(store.customers, record.client);
    return SectionCard(
      backgroundColor: colors.surface,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DocumentMasthead(record: record, company: store.companyProfile),
          const Divider(height: 28),
          _DocumentParties(record: record, customer: customer),
          const SizedBox(height: 20),
          _LineItemTable(items: record.items),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SizedBox(width: 300, child: _Totals(record: record)),
          ),
          const Divider(height: 28),
          const Text(
            'Terms and conditions',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(record.terms),
        ],
      ),
    );
  }

  WorkCustomerProfile? _customerFor(
    List<WorkCustomerProfile> customers,
    String name,
  ) {
    for (final customer in customers) {
      if (customer.name == name) return customer;
    }
    return null;
  }
}

class _DocumentMasthead extends StatelessWidget {
  const _DocumentMasthead({required this.record, required this.company});
  final WorkRecord record;
  final WorkCompanyProfile company;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 18,
    runSpacing: 12,
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.start,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              company.companyName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(company.businessCategory),
            Text(company.address),
            Text(company.phone),
            Text(company.email),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            record.kind.label.toUpperCase(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(record.number),
          Text(_dateLabel(context, record.createdOn)),
        ],
      ),
    ],
  );
}

class _DocumentParties extends StatelessWidget {
  const _DocumentParties({required this.record, required this.customer});
  final WorkRecord record;
  final WorkCustomerProfile? customer;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 28,
    runSpacing: 12,
    children: [
      _PartyBlock(
        label: 'Bill to',
        value: customer == null
            ? record.client
            : '${customer!.name}\n${customer!.billingAddress}\n${customer!.phone}\n${customer!.email}',
      ),
      _PartyBlock(
        label: 'Job location',
        value: customer?.locations.isNotEmpty == true
            ? '${customer!.locations.first.label}\n${customer!.locations.first.address}'
            : 'No service location selected',
      ),
      _PartyBlock(label: 'Pricing', value: record.pricing.label),
    ],
  );
}

class _PartyBlock extends StatelessWidget {
  const _PartyBlock({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 3),
        Text(value),
      ],
    ),
  );
}

class _LineItemTable extends StatelessWidget {
  const _LineItemTable({required this.items});
  final List<WorkLineItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (items.isEmpty) {
      return const Text(
        'No customer line items are attached to this document.',
      );
    }
    return Column(
      children: [
        Container(
          color: colors.surfaceContainerHigh,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: const Row(
            children: [
              SizedBox(width: 54, child: Text('Qty')),
              Expanded(child: Text('Description')),
              SizedBox(
                width: 94,
                child: Text('Total', textAlign: TextAlign.end),
              ),
            ],
          ),
        ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 54, child: Text(_quantity(item))),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (item.description.isNotEmpty)
                        Text(
                          item.description,
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 94,
                  child: Text(_money(item.total), textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.record});
  final WorkRecord record;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _TotalRow(
        label: 'Subtotal',
        value: _money(record.items.fold(0, (sum, item) => sum + item.total)),
      ),
      _TotalRow(label: 'Discount', value: _money(record.discount)),
      _TotalRow(label: 'Tax', value: _money(record.tax)),
      const Divider(height: 16),
      _TotalRow(
        label: record.kind == WorkRecordKind.invoice
            ? 'Total due'
            : 'Estimate total',
        value: _money(record.total),
        strong: true,
      ),
    ],
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

extension on WorkRecordKind {
  String get label => switch (this) {
    WorkRecordKind.estimate => 'Estimate',
    WorkRecordKind.job => 'Job',
    WorkRecordKind.invoice => 'Invoice',
  };
}

extension on WorkPricingModel {
  String get label => switch (this) {
    WorkPricingModel.flatRate => 'Flat rate',
    WorkPricingModel.timeAndMaterials => 'Time and materials',
  };
}

String _dateLabel(BuildContext context, DateTime? value) => value == null
    ? 'Date not recorded'
    : MaterialLocalizations.of(context).formatMediumDate(value);

String _quantity(WorkLineItem item) {
  final value = item.quantity == item.quantity.roundToDouble()
      ? item.quantity.toInt().toString()
      : item.quantity.toStringAsFixed(2);
  return '$value ${item.unit}';
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

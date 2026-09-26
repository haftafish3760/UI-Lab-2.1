import 'package:flutter/material.dart';
import '../../shared/calendar_width_section.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/work/invoice_payment_balance.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/operations_workspace.dart';
import '../../shared/section_card.dart';
import '../../shared/recorded_entries_section.dart';
import '../../shared/operational_section_heading.dart';
import '../../theme/operational_card_palette.dart';
import '../../theme/app_semantic_colors.dart';
import 'invoice_detail_screen.dart';
import 'invoice_payment_entry_screen.dart';
import 'invoice_payment_picker_screen.dart';
import 'invoice_permissions.dart';
import 'work_detail_header.dart';
import 'work_models.dart';
import 'work_month_calendar.dart';

part 'payment_record_row.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({
    this.initialDay,
    this.permissions = const InvoicePermissions.development(),
    super.key,
  });

  final DateTime? initialDay;
  final InvoicePermissions permissions;

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late var _selectedDay = DateUtils.dateOnly(
    widget.initialDay ?? DateTime.now(),
  );

  PrototypeOperationsStore get _store => PrototypeOperationsScope.of(context);

  @override
  Widget build(BuildContext context) {
    if (!widget.permissions.canViewFinancials) {
      return const Scaffold(
        key: ValueKey('payments-screen'),
        body: SafeArea(
          child: Center(
            child: Text('You do not have permission to view payments.'),
          ),
        ),
      );
    }
    final payments = _paymentsOn(_selectedDay);
    final pageWidth = MediaQuery.sizeOf(context).width;
    final pageInsets = AppLayoutEngine.pageInsetsFor(pageWidth);
    final compactActions =
        AppLayoutEngine.workFor(
          pageWidth - pageInsets.horizontal,
          textScaler: MediaQuery.textScalerOf(context),
        ).columns ==
        1;
    return Scaffold(
      key: const ValueKey('payments-screen'),
      floatingActionButton:
          widget.permissions.canRecordPayment && compactActions
          ? FloatingActionButton.extended(
              key: const ValueKey('record-payment-fab'),
              onPressed: _recordPayment,
              icon: const Icon(Icons.add_card_outlined),
              label: const Text('Record payment'),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.workFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 96),
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: insets.left,
                    right: insets.right,
                  ),
                  child: OperationsWorkspaceFrame(
                    layout: layout,
                    primaryContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: 'Payments',
                          selectedDay: _selectedDay,
                          onBack: () => Navigator.of(context).pop(),
                          showDateContext: true,
                        ),
                        const SizedBox(height: 14),
                        _PaymentsHeading(
                          totalCents: payments.fold(
                            0,
                            (sum, entry) => sum + entry.amountCents,
                          ),
                        ),
                        if (widget.permissions.canRecordPayment &&
                            !compactActions) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FilledButton.icon(
                              key: const ValueKey('record-payment-inline'),
                              onPressed: _recordPayment,
                              icon: const Icon(Icons.add_card_outlined),
                              label: const Text('Record payment'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _PaymentList(
                          payments: payments,
                          store: _store,
                          permissions: widget.permissions,
                        ),
                      ],
                    ),
                    followingContent: layout.columns == 1
                        ? null
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Payments calendar',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              WorkMonthCalendar(
                                maximumWidth: layout.laneWidth,
                                selectedDay: _selectedDay,
                                recordKind: CalendarRecordKind.payment,
                                entryCountForDay: (day) =>
                                    _paymentsOn(day).length,
                                onDaySelected: _openDay,
                              ),
                            ],
                          ),
                  ),
                ),
                if (layout.columns == 1) ...[
                  SizedBox(height: layout.gap),
                  CalendarWidthSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Payments calendar',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        WorkMonthCalendar(
                          maximumWidth: AppLayoutEngine.calendarMaximum,
                          selectedDay: _selectedDay,
                          recordKind: CalendarRecordKind.payment,
                          entryCountForDay: (day) => _paymentsOn(day).length,
                          onDaySelected: _openDay,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<PrototypeFinancialEntry> _paymentsOn(DateTime day) => _store
      .financialEntries
      .where(
        (entry) =>
            entry.kind == PrototypeFinancialKind.paymentReceived &&
            DateUtils.isSameDay(entry.occurredOn, day),
      )
      .toList();

  void _openDay(DateTime day) {
    setState(() => _selectedDay = DateUtils.dateOnly(day));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PaymentDayScreen(initialDay: day, permissions: widget.permissions),
      ),
    );
  }

  Future<void> _recordPayment() async {
    if (!widget.permissions.canRecordPayment) return;
    final invoices = _store.workRecords
        .where(
          (record) =>
              record.kind == WorkRecordKind.invoice &&
              record.status != WorkRecordStatus.draft &&
              _balanceCentsFor(record) > 0,
        )
        .toList();
    if (invoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No open invoice can receive a payment.')),
      );
      return;
    }
    final invoice = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => InvoicePaymentPickerScreen(
          invoices: invoices,
          selectedDay: _selectedDay,
          balanceCentsFor: _balanceCentsFor,
        ),
      ),
    );
    if (!mounted || invoice == null) return;
    final entry = await Navigator.of(context).push<PrototypeFinancialEntry>(
      MaterialPageRoute(
        builder: (_) => InvoicePaymentEntryScreen(
          invoice: invoice,
          balanceCents: _balanceCentsFor(invoice),
          initialDay: _selectedDay,
        ),
      ),
    );
    if (!mounted || entry == null) return;
    final saved = await _store.recordInvoicePayment(invoice, entry);
    if (!mounted || saved) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _store.workSession?.failureMessage ??
              'The payment was not saved. Please try again.',
        ),
      ),
    );
  }

  int _balanceCentsFor(WorkRecord invoice) {
    return invoiceBalanceCents(invoice, _store.financialEntries);
  }
}

class PaymentDayScreen extends StatelessWidget {
  const PaymentDayScreen({
    required this.initialDay,
    this.permissions = const InvoicePermissions.development(),
    super.key,
  });

  final DateTime initialDay;
  final InvoicePermissions permissions;

  @override
  Widget build(BuildContext context) {
    if (!permissions.canViewFinancials) {
      return const Scaffold(
        key: ValueKey('payment-day-screen'),
        body: SafeArea(
          child: Center(
            child: Text('You do not have permission to view payments.'),
          ),
        ),
      );
    }
    final store = PrototypeOperationsScope.of(context);
    final payments = store.financialEntries
        .where(
          (entry) =>
              entry.kind == PrototypeFinancialKind.paymentReceived &&
              DateUtils.isSameDay(entry.occurredOn, initialDay),
        )
        .toList();
    return Scaffold(
      key: const ValueKey('payment-day-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: 'Payment day',
                          selectedDay: initialDay,
                          onBack: () => Navigator.of(context).pop(),
                          showDateContext: true,
                        ),
                        const SizedBox(height: 12),
                        _PaymentList(
                          payments: payments,
                          store: store,
                          permissions: permissions,
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
}

class _PaymentsHeading extends StatelessWidget {
  const _PaymentsHeading({required this.totalCents});
  final int totalCents;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Row(
      children: [
        const Icon(Icons.payments_outlined),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payments received',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Text(
          _moneyCents(totalCents),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _PaymentList extends StatelessWidget {
  const _PaymentList({
    required this.payments,
    required this.store,
    required this.permissions,
  });
  final List<PrototypeFinancialEntry> payments;
  final PrototypeOperationsStore store;
  final InvoicePermissions permissions;

  @override
  Widget build(BuildContext context) => RecordedEntriesSection(
    builder: (context) => Column(
      children: [
        OperationalSectionHeading(
          background: OperationalCardPalette.entries.start,
          foreground: OperationalCardPalette.entries.foreground,
          child: Row(
            children: [
              const Icon(Icons.receipt_long_outlined),
              const SizedBox(width: 8),
              const Expanded(child: Text('Payment entries')),
              Text('${payments.length}'),
            ],
          ),
        ),
        if (payments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No payments are recorded for this date.'),
          )
        else
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                for (var index = 0; index < payments.length; index++) ...[
                  _PaymentRecordRow(
                    entry: payments[index],
                    invoice: _invoiceFor(store, payments[index].sourceId),
                    permissions: permissions,
                  ),
                  if (index < payments.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
      ],
    ),
  );
}

WorkRecord? _invoiceFor(PrototypeOperationsStore store, String reference) =>
    store.workRecords
        .where(
          (record) =>
              record.kind == WorkRecordKind.invoice &&
              (record.id == reference || record.number == reference),
        )
        .firstOrNull;

String _moneyCents(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

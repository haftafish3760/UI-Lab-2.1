import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/work/invoice_payment_draft_workflow.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/work/work_persistence_session.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'work_detail_header.dart';
import 'work_models.dart';

part 'invoice_payment_draft_recovery.dart';

class InvoicePaymentEntryScreen extends StatefulWidget {
  const InvoicePaymentEntryScreen({
    required this.invoice,
    required this.balanceCents,
    required this.initialDay,
    this.recoveredWorkflow,
    super.key,
  });

  final WorkRecord invoice;
  final int balanceCents;
  final DateTime initialDay;

  /// The editor owns closing this selected workflow; leaving retains its input.
  final InvoicePaymentDraftController? recoveredWorkflow;

  @override
  State<InvoicePaymentEntryScreen> createState() =>
      _InvoicePaymentEntryScreenState();
}

class _InvoicePaymentEntryScreenState extends State<InvoicePaymentEntryScreen>
    with DraftNavigationGuard {
  WorkPersistenceSession? _work;
  late InvoicePaymentDraftController? _workflow = widget.recoveredWorkflow;
  InvoicePaymentInput? _previewInput;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _draftSubscription;
  bool _initialized = false;
  bool _draftReady = false;
  bool _saving = false;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;
  void _refresh(VoidCallback change) => setState(change);
  int get _balanceCents => _workflow?.balanceCents ?? widget.balanceCents;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _work = PrototypeOperationsScope.maybeOf(context)?.workSession;
      unawaited(_openPaymentDraft());
    }
  }

  late final TextEditingController _amount = TextEditingController(
    text: (_balanceCents / 100).toStringAsFixed(2),
  );
  final _note = TextEditingController();
  late DateTime _receivedOn = DateUtils.dateOnly(widget.initialDay);
  var _method = 'Card';
  String? _error;

  @override
  void dispose() {
    unawaited(_draftSubscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      key: const ValueKey('invoice-payment-entry-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final width = AppLayoutEngine.formWorkspaceWidthFor(
              constraints.maxWidth - insets.horizontal,
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 96),
              children: [
                Center(
                  child: SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: 'Record payment',
                          selectedDay: _receivedOn,
                          onBack: () => leaveDraftRoute(),
                          showDateContext: true,
                        ),
                        if (_draft != null)
                          EditorDraftStatus(
                            state: _draft!.state,
                            onRetry: _draft!.retry,
                            onDiscard: _discardPaymentDraft,
                          ),
                        if (!_draftReady && _error == null)
                          const Text('Opening saved input…'),
                        if (_draftReady) ...[
                          const SizedBox(height: 16),
                          Text(
                            widget.invoice.number,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '${widget.invoice.client} · ${widget.invoice.title}',
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Remaining balance: \$${(_balanceCents / 100).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Payment received',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  key: const ValueKey('invoice-payment-amount'),
                                  controller: _amount,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Amount received',
                                    prefixText: r'$ ',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  initialValue: _method,
                                  decoration: const InputDecoration(
                                    labelText: 'Payment method',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Card',
                                      child: Text('Card'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Check',
                                      child: Text('Check'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Cash',
                                      child: Text('Cash'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Bank transfer',
                                      child: Text('Bank transfer'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Other',
                                      child: Text('Other'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      _changePaymentInput(
                                        () => _method = value,
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 10),
                                ListTile(
                                  key: const ValueKey('invoice-payment-date'),
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Date received'),
                                  subtitle: Text(
                                    MaterialLocalizations.of(
                                      context,
                                    ).formatMediumDate(_receivedOn),
                                  ),
                                  trailing: const Icon(
                                    Icons.edit_calendar_outlined,
                                  ),
                                  onTap: _pickDate,
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _note,
                                  minLines: 2,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Reference or note (optional)',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_error case final message?) ...[
                          const SizedBox(height: 10),
                          Text(
                            message,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: FilledButton.icon(
              key: const ValueKey('save-invoice-payment'),
              onPressed: _draftReady && !_saving ? _save : null,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Save payment'),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedOn,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Choose payment date',
    );
    if (mounted && picked != null) {
      _changePaymentInput(() => _receivedOn = DateUtils.dateOnly(picked));
    }
  }

  Future<void> _save() async {
    if (!_draftReady || _saving) return;
    await _confirmPayment();
  }
}

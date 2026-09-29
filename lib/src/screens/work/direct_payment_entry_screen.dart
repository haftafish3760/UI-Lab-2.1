import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/work/direct_payment_draft_workflow.dart';
import '../../data/work/invoice_payment_draft_workflow.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import 'work_detail_header.dart';
import 'work_models.dart';

class DirectPaymentEntryScreen extends StatefulWidget {
  const DirectPaymentEntryScreen({
    required this.initialDay,
    this.related,
    this.recoveredWorkflow,
    super.key,
  });

  final DateTime initialDay;
  final WorkRecord? related;
  final DirectPaymentDraftController? recoveredWorkflow;

  @override
  State<DirectPaymentEntryScreen> createState() =>
      _DirectPaymentEntryScreenState();
}

class _DirectPaymentEntryScreenState extends State<DirectPaymentEntryScreen>
    with DraftNavigationGuard {
  DirectPaymentDraftController? _workflow;
  StreamSubscription<DraftSaveState>? _draftSubscription;
  bool _opened = false;
  bool _saving = false;
  String? _error;

  final _amount = TextEditingController();
  final _payer = TextEditingController();
  final _description = TextEditingController();
  final _note = TextEditingController();
  final _amountFocus = FocusNode();
  final _payerFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  late DateTime _receivedOn = DateUtils.dateOnly(widget.initialDay);
  var _method = 'Cash';
  var _linkKind = PaymentLinkKind.none;
  var _sourceId = '';

  @override
  DraftAutosaveSession? get navigationDraft => _workflow?.session;
  @override
  bool get blockDraftNavigation => _saving;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_opened) {
      _opened = true;
      unawaited(_open());
    }
  }

  @override
  void dispose() {
    unawaited(_draftSubscription?.cancel());
    unawaited(_workflow?.session.close().catchError((Object _) {}));
    _amount.dispose();
    _payer.dispose();
    _description.dispose();
    _note.dispose();
    _amountFocus.dispose();
    _payerFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final work = PrototypeOperationsScope.of(context).workSession;
    if (work == null) {
      setState(() => _error = 'Work storage is unavailable.');
      return;
    }
    DirectPaymentDraftController? openedWorkflow;
    try {
      final workflow =
          widget.recoveredWorkflow ??
          await work.openDirectPaymentDraft(
            initialDay: widget.initialDay,
            related: widget.related,
          );
      openedWorkflow = workflow;
      if (!mounted) {
        await workflow.session.close();
        return;
      }
      work.validateDirectPaymentHandoff(workflow);
      final input = workflow.input;
      _workflow = workflow;
      _amount.text = input.amount;
      _payer.text = input.payerName;
      _description.text = input.description;
      _note.text = input.note;
      _receivedOn = input.receivedOn;
      _method = input.method;
      _linkKind = input.linkKind;
      _sourceId = input.sourceId;
      for (final controller in [_amount, _payer, _description, _note]) {
        controller.addListener(_capture);
      }
      _draftSubscription = workflow.session.changes.listen((_) {
        if (mounted) setState(() {});
      });
      setState(() {});
    } on DirectPaymentInputValidation catch (error) {
      await openedWorkflow?.session.close().catchError((Object _) {});
      if (mounted) setState(() => _error = error.message);
    } on Object {
      await openedWorkflow?.session.close().catchError((Object _) {});
      if (mounted) {
        setState(
          () => _error =
              'Saved payment input could not be opened. Leave this screen and retry.',
        );
      }
    }
  }

  void _capture() {
    if (_saving || _workflow == null) return;
    final input = _workflow!.input.copyWith(
      amount: _amount.text,
      payerName: _payer.text,
      description: _description.text,
      note: _note.text,
      method: _method,
      receivedOn: _receivedOn,
      linkKind: _linkKind,
      sourceId: _sourceId,
    );
    _workflow!.updateInput(input);
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_workflow == null || _saving) return;
    try {
      _capture();
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
      setState(() {
        _saving = true;
        _error = null;
      });
      final payment = await _workflow!.confirm();
      if (payment == null) {
        throw StateError('Payment was not saved.');
      }
      if (mounted) await finishDraftRoute(payment);
    } on DirectPaymentInputValidation catch (error) {
      _showError(error.message);
    } on Object {
      if (mounted) {
        final work = PrototypeOperationsScope.of(context).workSession;
        _showError(
          _workflow?.session.hasFailure == true
              ? 'Your latest input has not been saved on this device. Retry saving it before recording the payment.'
              : work?.failureMessage ??
                    'Payment was not saved. Your input is kept for retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _discard() async {
    if (_saving || _workflow == null) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard unfinished payment?'),
        content: const Text('The payment has not been recorded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard input'),
          ),
        ],
      ),
    );
    if (discard != true || !mounted) return;
    try {
      await _workflow!.session.discard();
      if (mounted) await finishDraftRoute();
    } on Object {
      _showError(
        'Could not discard the unfinished payment. Your input is still on this screen.',
      );
    }
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = await showDatePicker(
      context: context,
      initialDate: _receivedOn.isAfter(today) ? today : _receivedOn,
      firstDate: DateTime(2000),
      lastDate: today,
      helpText: 'Choose payment date',
    );
    if (day != null && mounted) {
      setState(() => _receivedOn = DateUtils.dateOnly(day));
      _capture();
    }
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      key: const ValueKey('direct-payment-entry-screen'),
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
                          label: widget.related?.kind == WorkRecordKind.estimate
                              ? 'Record deposit'
                              : 'Record payment',
                          selectedDay: _receivedOn,
                          onBack: () => leaveDraftRoute(),
                          showDateContext: true,
                        ),
                        if (_workflow?.session.state == DraftSaveState.notSaved)
                          EditorDraftStatus(
                            state: _workflow!.session.state,
                            onRetry: _workflow!.session.retry,
                          ),
                        if (_workflow == null && _error == null)
                          const Text('Opening saved input…'),
                        if (_workflow != null) ...[
                          const SizedBox(height: 12),
                          Form(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  key: const ValueKey('direct-payment-amount'),
                                  controller: _amount,
                                  focusNode: _amountFocus,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) =>
                                      _payerFocus.requestFocus(),
                                  decoration: _lineDecoration(
                                    'Amount received',
                                    prefixText: r'$ ',
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  key: const ValueKey('direct-payment-payer'),
                                  controller: _payer,
                                  focusNode: _payerFocus,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) =>
                                      _descriptionFocus.requestFocus(),
                                  decoration: _lineDecoration(
                                    'Customer or payer (optional)',
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  key: const ValueKey(
                                    'direct-payment-description',
                                  ),
                                  controller: _description,
                                  focusNode: _descriptionFocus,
                                  textInputAction: TextInputAction.done,
                                  decoration: _lineDecoration(
                                    'What was this payment for?',
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _linkPicker(context),
                                if (_linkKind == PaymentLinkKind.estimate ||
                                    _linkKind == PaymentLinkKind.job) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'This records money received for this work. It does not automatically reduce a later invoice.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                                const SizedBox(height: 20),
                                DropdownButtonFormField<String>(
                                  key: ValueKey(
                                    'direct-payment-method-$_method',
                                  ),
                                  initialValue: _method,
                                  decoration: _lineDecoration('Payment method'),
                                  items: [
                                    for (final method
                                        in InvoicePaymentInput.paymentMethods)
                                      DropdownMenuItem(
                                        value: method,
                                        child: Text(method),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _method = value);
                                    _capture();
                                  },
                                ),
                                const SizedBox(height: 12),
                                ListTile(
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
                                const Divider(height: 1),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _note,
                                  minLines: 2,
                                  maxLines: 4,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  decoration: _lineDecoration(
                                    'Reference or note (optional)',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: TextButton(
                                    onPressed: _saving ? null : _discard,
                                    child: const Text(
                                      'Discard unfinished payment',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  minimum: const EdgeInsets.all(12),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: FilledButton.icon(
                        key: const ValueKey('save-direct-payment'),
                        onPressed: _workflow != null && !_saving ? _save : null,
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Save payment'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _linkPicker(BuildContext context) {
    final work = PrototypeOperationsScope.of(context).workSession;
    final records = PrototypeOperationsScope.of(context).workRecords.where(
      (record) =>
          (record.kind == WorkRecordKind.job ||
              record.kind == WorkRecordKind.estimate) &&
          (work == null ||
              work.permissions.visibleCreatorIds.contains(
                record.createdByEmployeeId,
              )),
    );
    final choices = <String, String>{'none': 'No linked job or estimate'};
    for (final record in records) {
      choices['${record.kind.name}:${record.id}'] =
          '${record.kind == WorkRecordKind.job ? 'Job' : 'Estimate'} ${record.number} · ${record.title}';
    }
    final selected = _linkKind == PaymentLinkKind.none
        ? 'none'
        : '${_linkKind.name}:$_sourceId';
    if (!choices.containsKey(selected)) {
      choices[selected] = 'Linked work unavailable — review before saving';
    }
    return DropdownButtonFormField<String>(
      key: ValueKey('direct-payment-link-$selected'),
      initialValue: selected,
      isExpanded: true,
      decoration: _lineDecoration('Link to work (optional)'),
      items: [
        for (final choice in choices.entries)
          DropdownMenuItem(value: choice.key, child: Text(choice.value)),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          if (value == 'none') {
            _linkKind = PaymentLinkKind.none;
            _sourceId = '';
          } else {
            final separator = value.indexOf(':');
            _linkKind = PaymentLinkKind.values.byName(
              value.substring(0, separator),
            );
            _sourceId = value.substring(separator + 1);
          }
        });
        _capture();
      },
    );
  }

  InputDecoration _lineDecoration(String label, {String? prefixText}) =>
      InputDecoration(
        labelText: label,
        prefixText: prefixText,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: false,
        isDense: true,
        border: const UnderlineInputBorder(),
        enabledBorder: const UnderlineInputBorder(),
        focusedBorder: const UnderlineInputBorder(),
      );
}

import 'documents/customer_pdf_screen.dart';
import 'work_customer_document.dart';
import '../../data/work/work_export_audit.dart';
import 'work_pdf_delivery.dart';
import '../../data/work/models/work_contact_models.dart';
import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/work/work_persistence_session.dart';
import '../../data/work/estimate_delivery_draft_workflow.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'estimate_models.dart';
import 'work_detail_header.dart';
import 'work_models.dart';

part 'estimate_delivery_draft_recovery.dart';

class EstimateDeliveryScreen extends StatefulWidget {
  const EstimateDeliveryScreen({
    required this.record,
    this.recoveredWorkflow,
    super.key,
  });
  final WorkRecord record;
  final EstimateDeliveryDraftController? recoveredWorkflow;

  @override
  State<EstimateDeliveryScreen> createState() => _EstimateDeliveryScreenState();
}

class _EstimateDeliveryScreenState extends State<EstimateDeliveryScreen>
    with DraftNavigationGuard {
  var _method = EstimateDeliveryMethod.email;
  WorkRecord? _preparedRecord;
  final _recipient = TextEditingController();
  var _reviewed = false;
  var _initialized = false;
  late WorkRecord _base = widget.record;
  WorkPersistenceSession? _work;
  late EstimateDeliveryDraftController? _workflow = widget.recoveredWorkflow;
  EstimateDeliveryInput? _previewInput;
  DraftAutosaveSession? get _draft => _workflow?.session;
  bool _bindingRecipient = false;
  StreamSubscription<DraftSaveState>? _subscription;
  bool _ready = false, _saving = false;
  String? _error;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    unawaited(_openDeliveryDraft());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    _recipient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      key: const ValueKey('estimate-delivery-screen'),
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
                    width: layout.columns == 1
                        ? layout.columnWidth
                        : layout.workspaceWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: _base.kind == WorkRecordKind.quote
                              ? 'Send quote'
                              : 'Send estimate',
                          selectedDay:
                              _base.estimateDates?.createdOn ?? DateTime.now(),
                          onBack: () => leaveDraftRoute(),
                          showDateContext: true,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Choose delivery method',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_base.number} · Revision ${_base.revision} · ${_base.client}',
                        ),
                        const SizedBox(height: 14),
                        _DeliveryMethodCard(
                          selected: _method,
                          onSelected: (method) {
                            if (_ready) _selectMethod(method);
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_draft != null)
                          EditorDraftStatus(
                            showRoutineStatus: false,
                            state: _draft!.state,
                            onRetry: _draft!.retry,
                            onDiscard: _discardDelivery,
                          ),
                        if (_error != null) Text(_error!),
                        if (!_ready && _error == null)
                          const Text('Opening saved delivery…'),
                        SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Recipient and document review',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Check the recipient before opening the composer.',
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                key: const ValueKey(
                                  'estimate-delivery-recipient',
                                ),
                                controller: _recipient,
                                enabled:
                                    _ready &&
                                    !_saving &&
                                    _preparedRecord == null,
                                decoration: InputDecoration(
                                  labelText: _recipientLabel,
                                ),
                              ),
                              const SizedBox(height: 20),
                              OutlinedButton.icon(
                                key: const ValueKey(
                                  'preview-estimate-for-delivery',
                                ),
                                onPressed: _ready && !_saving
                                    ? _previewCustomerCopy
                                    : null,
                                icon: const Icon(Icons.picture_as_pdf_outlined),
                                label: const Text('View customer PDF'),
                              ),
                              const SizedBox(height: 12),
                              CheckboxListTile(
                                value: _reviewed,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Text(
                                  'I reviewed the customer copy and recipient',
                                ),
                                subtitle: Text(
                                  'You are reviewing revision ${_base.revision}. This does not record customer approval.',
                                ),
                                onChanged:
                                    !_ready ||
                                        _saving ||
                                        _preparedRecord != null
                                    ? null
                                    : (value) {
                                        setState(
                                          () => _reviewed = value ?? false,
                                        );
                                        _captureDelivery();
                                      },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SectionCard(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .withValues(alpha: .55),
                          child: const Text(
                            'Email and text open a composer with the recipient and PDF where supported. Review them before sending. Some text apps cannot attach PDFs; use email or Share PDF instead. Opening a composer does not confirm delivery or customer approval.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          key: const ValueKey('confirm-estimate-delivery'),
                          onPressed: _ready && _reviewed && !_saving
                              ? _confirm
                              : null,
                          icon: const Icon(Icons.task_alt_outlined),
                          label: const Text('Continue to sharing'),
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
    ),
  );

  Future<void> _previewCustomerCopy() async {
    final work = _work;
    if (!_ready || _saving || work == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _draft?.flush();
      final record = _preparedRecord ?? _base;
      final expected = _preparedRecord == null
          ? _workflow!.input.baseRevision
          : work.storageRevisionFor(record.id);
      final saved = await WorkExportAudit(
        work,
      ).assertCurrent(record.id, expected, expectedDocument: record);
      if (!mounted) return;
      final store = PrototypeOperationsScope.of(context);
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => CustomerPdfScreen(
            document: workCustomerDocument(
              saved,
              store.companyProfile,
              resolveWorkDocumentCustomer(saved, store.customers),
            ),
          ),
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'The customer PDF could not open. Your input is saved; try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _recipientLabel => switch (_method) {
    EstimateDeliveryMethod.email => 'Customer email address',
    EstimateDeliveryMethod.textMessage => 'Customer mobile number',
    EstimateDeliveryMethod.deviceShare => 'Share recipient or destination',
    EstimateDeliveryMethod.savedPdf => 'Saved copy label',
    EstimateDeliveryMethod.print => 'Printed copy recipient',
    EstimateDeliveryMethod.inPerson => 'Customer name',
  };

  void _selectMethod(EstimateDeliveryMethod method) {
    if (!_ready || _saving || _preparedRecord != null) return;
    if (_workflow != null) {
      _workflow!.selectMethod(method);
    } else {
      _previewInput = _previewInput!.withMethod(
        method,
        estimateDeliveryRecipient(
          _base,
          method,
          PrototypeOperationsScope.maybeOf(context)?.customers ??
              const <WorkCustomerProfile>[],
        ),
      );
    }
    final input = _workflow?.input ?? _previewInput!;
    _bindingRecipient = true;
    _recipient.text = input.recipient;
    _bindingRecipient = false;
    setState(() {
      _method = input.method;
      _reviewed = input.reviewed;
    });
  }
}

class _DeliveryMethodCard extends StatelessWidget {
  const _DeliveryMethodCard({required this.selected, required this.onSelected});
  final EstimateDeliveryMethod selected;
  final ValueChanged<EstimateDeliveryMethod> onSelected;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final method in const [
          EstimateDeliveryMethod.email,
          EstimateDeliveryMethod.textMessage,
          EstimateDeliveryMethod.deviceShare,
          EstimateDeliveryMethod.savedPdf,
          EstimateDeliveryMethod.print,
        ])
          ListTile(
            key: ValueKey('delivery-${method.name}'),
            leading: Icon(
              selected == method
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
            ),
            title: Text(_methodLabel(method)),
            subtitle: Text(_methodHelp(method)),
            onTap: () => onSelected(method),
          ),
      ],
    ),
  );
}

String _methodLabel(EstimateDeliveryMethod method) => switch (method) {
  EstimateDeliveryMethod.email => 'Email PDF to customer',
  EstimateDeliveryMethod.textMessage => 'Text message',
  EstimateDeliveryMethod.deviceShare => 'Share from this device',
  EstimateDeliveryMethod.savedPdf => 'Save PDF copy',
  EstimateDeliveryMethod.print => 'Print customer copy',
  EstimateDeliveryMethod.inPerson => 'Sign in person',
};

String _methodHelp(EstimateDeliveryMethod method) => switch (method) {
  EstimateDeliveryMethod.email || EstimateDeliveryMethod.textMessage =>
    'Choose your email or messaging app. PDF attachment support depends on that app.',
  EstimateDeliveryMethod.deviceShare =>
    'Use the device share sheet after the customer PDF is generated.',
  EstimateDeliveryMethod.savedPdf => 'Keep a customer-ready PDF file.',
  EstimateDeliveryMethod.print => 'Print the exact customer copy.',
  EstimateDeliveryMethod.inPerson => 'Customer signs on this device.',
};

import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/work/estimate_approval_draft_workflow.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import '../../data/storage/draft_autosave_session.dart';
import 'estimate_signature_screen.dart';
import 'work_models.dart';

part 'estimate_approval_draft_persistence.dart';

/// Approval is a child of the originating estimate, never a details-page detour.
class EstimateApprovalScreen extends StatefulWidget {
  const EstimateApprovalScreen({
    required this.record,
    this.recoveredWorkflow,
    this.embedded = false,
    this.onSaved,
    this.onClose,
    super.key,
  });
  final WorkRecord record;
  final bool embedded;
  final Future<void> Function(WorkRecord)? onSaved;
  final Future<void> Function()? onClose;
  final EstimateApprovalDraftController? recoveredWorkflow;

  @override
  State<EstimateApprovalScreen> createState() => EstimateApprovalScreenState();
}

class EstimateApprovalScreenState extends State<EstimateApprovalScreen>
    with DraftNavigationGuard {
  @override
  DraftAutosaveSession? get navigationDraft =>
      _approvalDraft?.session ?? _signature.currentState?.draft;
  @override
  bool get blockDraftNavigation =>
      _saving || (_signature.currentState?.isSaving ?? false);
  @override
  bool get requiresDraftPopGuard =>
      navigationDraft != null ||
      _showSignature ||
      _method != null ||
      _name.text != widget.record.client ||
      _note.text.isNotEmpty;
  @override
  Future<void> leaveDraftRoute([Object? result]) => _close();

  @override
  void initState() {
    super.initState();
    _name.addListener(_refreshInput);
    _note.addListener(_refreshInput);
  }

  void _refreshInput() {
    _captureApproval();
    if (mounted) setState(() {});
  }

  EstimateApprovalDraftController? _approvalDraft;
  StreamSubscription<DraftSaveState>? _approvalSubscription;
  bool _openingApproval = false, _approvalReady = false;
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.record.client);
  final _note = TextEditingController();
  CustomerApprovalMethod? _method;
  final _signature = GlobalKey<EstimateSignatureScreenState>();
  bool _showSignature = false;
  bool _saving = false;
  bool _termsAccepted = false;
  String? _error;

  @override
  void dispose() {
    unawaited(_approvalSubscription?.cancel());
    unawaited(_approvalDraft?.session.close().catchError((Object _) {}));
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _sign() async {
    final work = PrototypeOperationsScope.of(context).workSession;
    if (_saving ||
        !_termsAccepted ||
        work == null ||
        !work.permissions.canCollectSignature) {
      return;
    }
    setState(() => _showSignature = true);
  }

  Future<void> _record() async {
    final work = PrototypeOperationsScope.of(context).workSession;
    if (_saving ||
        !_termsAccepted ||
        work == null ||
        !work.permissions.canRecordCustomerApproval ||
        !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      _captureApproval();
      final record = await _approvalDraft!.confirm();
      if (record == null) {
        throw StateError(
          work.failureMessage ??
              'Approval could not be saved. Please try again.',
        );
      }
      if (mounted) await _finish(record);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is StateError
              ? error.message.toString()
              : 'Approval could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_openingApproval) {
      _openingApproval = true;
      unawaited(_openApproval());
    }
  }

  bool get isSaving => blockDraftNavigation;
  Future<void> flushInput() async {
    await _approvalDraft?.session.flush();
    await _signature.currentState?.draft?.flush();
  }

  Future<void> _finish(WorkRecord record) async {
    if (widget.embedded) {
      await widget.onSaved?.call(record);
    } else {
      await finishDraftRoute(record);
    }
  }

  bool _closing = false;
  Future<void> _close() async {
    if (_closing || blockDraftNavigation) return;
    _closing = true;
    try {
      if (mounted) {
        try {
          await _approvalDraft?.session.flush();
          await _signature.currentState?.draft?.flush();
          if (mounted) {
            if (widget.embedded) {
              await widget.onClose?.call();
            } else {
              await finishDraftRoute();
            }
          }
        } on Object {
          if (mounted) {
            setState(
              () => _error =
                  'Your signature input could not be saved. Please retry before leaving.',
            );
          }
        }
      }
    } finally {
      _closing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = PrototypeOperationsScope.of(
      context,
    ).workSession?.permissions;
    final record = _approvalDraft?.input.base ?? widget.record;
    final allowed =
        access != null &&
        access.canEdit(record) &&
        record.companyReviewAllowsCustomerApproval;
    final form = Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (allowed) ...[
            if (!widget.embedded) ...[
              Text(record.title, style: Theme.of(context).textTheme.titleLarge),
              Text(record.client),
              Text('${record.number} · Version ${record.revision}'),
              Text(
                '${record.kind == WorkRecordKind.quote ? 'Quote total' : 'Estimated total'}: \$${record.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Work to be approved',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(record.detail),
              for (final item in record.items) ...[
                const SizedBox(height: 12),
                Text(item.name),
                Text(
                  '${item.quantity} ${item.unit} · \$${item.total.toStringAsFixed(2)}',
                ),
              ],
              const SizedBox(height: 12),
              Text('Discount: \$${record.discount.toStringAsFixed(2)}'),
              Text('Tax: \$${record.tax.toStringAsFixed(2)}'),
              const SizedBox(height: 20),
              Text(
                'Terms and conditions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                record.terms.trim().isEmpty
                    ? 'No terms have been added to this document.'
                    : record.terms,
              ),
              if (record.estimateDates?.validityDays case final days?) ...[
                const SizedBox(height: 12),
                Text(
                  'Price guaranteed for $days days from the date sent to the customer.',
                ),
              ],
              if (record.requiredDepositCents > 0) ...[
                const SizedBox(height: 12),
                Text(
                  'Required deposit: \$${(record.requiredDepositCents / 100).toStringAsFixed(2)}',
                ),
              ],
              const SizedBox(height: 16),
            ],
            CheckboxListTile(
              key: const ValueKey('approval-terms-accepted'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _termsAccepted,
              title: const Text(
                'The customer accepts the work, price, and terms shown above.',
              ),
              onChanged: blockDraftNavigation || !_approvalReady
                  ? null
                  : (value) => setState(() {
                      _termsAccepted = value ?? false;
                      _captureApproval();
                    }),
            ),
            const SizedBox(height: 16),
          ],
          if (!allowed)
            const Text(
              'This document is not available for customer approval with your current access or company review status.',
            )
          else ...[
            if (record.hasCurrentCustomerApproval) ...[
              const Text('Customer approval recorded for this version.'),
              if (record.hasCurrentCustomerSignature)
                Text(
                  'Signed by ${record.customerSignature!.signedBy} on ${MaterialLocalizations.of(context).formatMediumDate(record.customerSignature!.signedOn.toLocal())}',
                ),
              const SizedBox(height: 12),
            ],
            if (access.canCollectSignature && !_showSignature)
              FilledButton.icon(
                icon: const Icon(Icons.draw_outlined),
                onPressed: _saving || !_approvalReady || !_termsAccepted
                    ? null
                    : _sign,
                key: const ValueKey('approval-sign-in-person'),
                label: const Text('Add customer signature'),
              ),
            if (_showSignature && access.canCollectSignature)
              EstimateSignatureScreen(
                key: _signature,
                record: record,
                embedded: true,
                approvalEnabled: _termsAccepted,
                onSaved: _finish,
                onDiscarded: () => setState(() => _showSignature = false),
                onStateChanged: () {
                  if (mounted) setState(() {});
                },
              ),
            if (access.canRecordCustomerApproval && !_showSignature) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Record approval without a signature',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CustomerApprovalMethod>(
                    initialValue: _method,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'How did the customer approve?',
                    ),
                    items: [
                      for (final method in CustomerApprovalMethod.values)
                        if (method != CustomerApprovalMethod.signedEstimate)
                          DropdownMenuItem(
                            value: method,
                            child: Text(method.label),
                          ),
                    ],
                    onChanged: _saving || !_approvalReady
                        ? null
                        : (value) => setState(() {
                            _method = value;
                            _captureApproval();
                          }),
                    validator: (value) => value == null
                        ? 'Choose how the customer approved.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('approval-customer-name'),
                    controller: _name,
                    enabled: !_saving && _approvalReady,
                    decoration: const InputDecoration(
                      labelText: 'Customer name',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter the customer’s name.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('approval-details'),
                    controller: _note,
                    enabled: !_saving && _approvalReady,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Approval details',
                    ),
                    validator: (value) =>
                        _method == CustomerApprovalMethod.other &&
                            (value == null || value.trim().isEmpty)
                        ? 'Describe the approval.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving || !_approvalReady || !_termsAccepted
                        ? null
                        : _record,
                    child: const Text('Record approval'),
                  ),
                ],
              ),
            ],
          ],
          if (_approvalDraft?.session.state == DraftSaveState.notSaved)
            EditorDraftStatus(
              state: _approvalDraft!.session.state,
              onRetry: _approvalDraft!.session.retry,
            ),
          if (!_approvalReady && _error == null)
            const Text('Opening approval…'),
          if (_error != null) Text(_error!, semanticsLabel: _error),
          const SizedBox(height: 20),
          OutlinedButton(
            key: const ValueKey('close-estimate-approval'),
            onPressed: _saving ? null : _close,
            child: Text(widget.embedded ? 'Back to editing' : 'Close'),
          ),
        ],
      ),
    );
    if (widget.embedded) return form;
    return guardDraftNavigation(
      Scaffold(
        key: const ValueKey('estimate-approval-screen'),
        appBar: AppBar(
          title: const Text('Customer signature and approval'),
          leading: BackButton(onPressed: _close),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            return SingleChildScrollView(
              padding: insets.copyWith(top: 12, bottom: 24),
              child: Center(
                child: SizedBox(
                  width: AppLayoutEngine.formWorkspaceWidthFor(
                    constraints.maxWidth - insets.horizontal,
                  ),
                  child: form,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

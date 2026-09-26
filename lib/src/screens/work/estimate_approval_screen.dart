import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/estimate_customer_approval.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../data/storage/draft_autosave_session.dart';
import 'estimate_signature_screen.dart';
import 'work_models.dart';

/// Approval is a child of the originating estimate, never a details-page detour.
class EstimateApprovalScreen extends StatefulWidget {
  const EstimateApprovalScreen({required this.record, super.key});
  final WorkRecord record;

  @override
  State<EstimateApprovalScreen> createState() => _EstimateApprovalScreenState();
}

class _EstimateApprovalScreenState extends State<EstimateApprovalScreen>
    with DraftNavigationGuard {
  @override
  DraftAutosaveSession? get navigationDraft => null;
  @override
  bool get blockDraftNavigation => _saving;
  @override
  bool get requiresDraftPopGuard =>
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
    if (mounted) setState(() {});
  }

  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.record.client);
  final _note = TextEditingController();
  CustomerApprovalMethod? _method;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _sign() async {
    final work = PrototypeOperationsScope.of(context).workSession;
    if (_saving || work == null || !work.permissions.canCollectSignature) {
      return;
    }
    final signed = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => EstimateSignatureScreen(record: widget.record),
      ),
    );
    if (mounted && signed != null) await _finish(signed);
  }

  Future<void> _record() async {
    final work = PrototypeOperationsScope.of(context).workSession;
    if (_saving ||
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
      final record = widget.record.recordCustomerApproval(
        WorkCustomerApproval(
          method: _method!,
          customerName: _name.text.trim(),
          recordedByEmployeeId: work.permissions.actorEmployeeId,
          recordedOn: DateTime.now().toUtc(),
          revision: widget.record.revision,
          note: _note.text.trim(),
        ),
      );
      final saved = await work.save(
        records: [record],
        expectedStorageRevisions: {record.id: _storageRevision!},
      );
      if (!saved) {
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

  int? _storageRevision;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storageRevision ??= PrototypeOperationsScope.of(
      context,
    ).workSession?.storageRevisionFor(widget.record.id);
  }

  Future<bool> _canLeave() async {
    if (_saving) return false;
    if (_method == null &&
        _name.text == widget.record.client &&
        _note.text.isEmpty) {
      return true;
    }
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave without recording approval?'),
            content: const Text(
              'Your estimate is saved. The approval information entered here will be discarded.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard approval'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _finish(WorkRecord record) => finishDraftRoute(record);

  bool _closing = false;
  Future<void> _close() async {
    if (_closing || _saving) return;
    _closing = true;
    try {
      if (await _canLeave() && mounted) await finishDraftRoute();
    } finally {
      _closing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = PrototypeOperationsScope.of(
      context,
    ).workSession?.permissions;
    final record = widget.record;
    final allowed =
        access != null &&
        access.canEdit(record) &&
        record.companyReviewAllowsCustomerApproval;
    return guardDraftNavigation(
      Scaffold(
        key: const ValueKey('estimate-approval-screen'),
        appBar: AppBar(
          title: const Text('Customer approval'),
          leading: BackButton(onPressed: _close),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final width = AppLayoutEngine.formWorkspaceWidthFor(
              constraints.maxWidth - insets.horizontal,
            );
            return SingleChildScrollView(
              padding: insets.copyWith(top: 12, bottom: 24),
              child: Center(
                child: SizedBox(
                  width: width,
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          record.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(record.client),
                        Text('${record.number} · Version ${record.revision}'),
                        Text(
                          'Estimated total: \$${record.total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        if (!allowed)
                          const Text(
                            'This estimate is not available for customer approval with your current access or company review status.',
                          )
                        else ...[
                          if (record.hasCurrentCustomerApproval) ...[
                            const Text(
                              'Customer approval recorded for this version.',
                            ),
                            if (record.hasCurrentCustomerSignature)
                              Text(
                                'Signed by ${record.customerSignature!.signedBy} on ${MaterialLocalizations.of(context).formatMediumDate(record.customerSignature!.signedOn.toLocal())}',
                              ),
                            const SizedBox(height: 12),
                          ],
                          if (access.canCollectSignature)
                            OutlinedButton(
                              onPressed: _saving ? null : _sign,
                              key: const ValueKey('approval-sign-in-person'),
                              child: const Text('Review and sign in person'),
                            ),
                          if (access.canRecordCustomerApproval) ...[
                            const SizedBox(height: 16),
                            SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Already approved another way?',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<
                                    CustomerApprovalMethod
                                  >(
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText:
                                          'How did the customer approve?',
                                    ),
                                    items: [
                                      for (final method
                                          in CustomerApprovalMethod.values)
                                        if (method !=
                                            CustomerApprovalMethod
                                                .signedEstimate)
                                          DropdownMenuItem(
                                            value: method,
                                            child: Text(method.label),
                                          ),
                                    ],
                                    onChanged: _saving
                                        ? null
                                        : (value) =>
                                              setState(() => _method = value),
                                    validator: (value) => value == null
                                        ? 'Choose how the customer approved.'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _name,
                                    enabled: !_saving,
                                    decoration: const InputDecoration(
                                      labelText: 'Customer name',
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Enter the customer’s name.'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _note,
                                    enabled: !_saving,
                                    minLines: 2,
                                    maxLines: 5,
                                    decoration: const InputDecoration(
                                      labelText: 'Approval details',
                                    ),
                                    validator: (value) =>
                                        _method ==
                                                CustomerApprovalMethod.other &&
                                            (value == null ||
                                                value.trim().isEmpty)
                                        ? 'Describe the approval.'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    onPressed: _saving ? null : _record,
                                    child: const Text('Record approval'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                        if (_error != null)
                          Text(_error!, semanticsLabel: _error),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(12),
          child: Align(
            heightFactor: 1,
            child: OutlinedButton(
              onPressed: _saving ? null : _close,
              child: const Text('Close'),
            ),
          ),
        ),
      ),
    );
  }
}

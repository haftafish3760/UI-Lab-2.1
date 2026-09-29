import 'proposal_approval_history_screen.dart';
import 'proposal_invoice_action.dart';
import 'estimate_review_section.dart';
import 'estimate_approval_screen.dart';
import 'direct_payment_entry_screen.dart';
import '../../shared/editor_input_lock.dart';
import '../../data/work/work_persistence_session.dart';
import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/storage/local_record_command.dart';
import '../../data/work/work_record_codec.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../shared/operations_workspace.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/operational_card_palette.dart';

import 'estimate_delivery_screen.dart';
import 'estimate_editor_screen.dart';
import 'estimate_items_screen.dart';
import 'stored_estimate_items_editor.dart';
import 'estimate_models.dart';
import 'estimate_signature_screen.dart';
import 'estimate_review_reason_dialog.dart';
import 'work_detail_header.dart';
import 'work_document_preview_screen.dart';
import 'work_models.dart';
import 'work_activity_screen.dart';

part 'estimate_detail_widgets.dart';
part 'estimate_detail_record_cards.dart';
part 'estimate_detail_commands.dart';

part 'estimate_primary_actions.dart';
part 'estimate_company_review_card.dart';
part 'estimate_company_review_handlers.dart';

class EstimateDetailScreen extends StatefulWidget {
  const EstimateDetailScreen({
    required this.initialRecord,
    required this.onUpdated,
    required this.onCreateJob,
    this.permissions = const EstimatePermissions.development(),
    this.openApprovalOnEntry = false,
    this.reviewBeforeSave = false,
    this.onEditSection,
    this.onCustomerApproval,
    super.key,
  });

  final WorkRecord initialRecord;
  final ValueChanged<WorkRecord> onUpdated, onCreateJob;
  final EstimatePermissions permissions;
  final Future<WorkRecord?> Function()? onCustomerApproval;
  final bool openApprovalOnEntry;
  final bool reviewBeforeSave;
  final Future<WorkRecord?> Function(EstimateReviewSection)? onEditSection;

  @override
  State<EstimateDetailScreen> createState() => _EstimateDetailScreenState();
}

class _EstimateDetailScreenState extends State<EstimateDetailScreen> {
  late var _record = widget.initialRecord;
  var _saving = false;
  var _editingSection = false;
  var _initializedPersistence = false;
  int _baseStorageRevision = 0;
  void _refreshActions(VoidCallback change) => setState(change);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedPersistence) return;
    _initializedPersistence = true;
    if (widget.reviewBeforeSave) return;
    final work = PrototypeOperationsScope.maybeOf(context)?.workSession;
    final current = work?.records
        .where((record) => record.id == _record.id)
        .firstOrNull;
    if (widget.openApprovalOnEntry) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _recordCustomerApproval();
      });
    }
    if (current != null) {
      _record = current;
      _baseStorageRevision = work!.storageRevisionFor(current.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EditorInputLock(
      locked: _saving || _editingSection,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          final layout = AppLayoutEngine.workFor(
            constraints.maxWidth - insets.horizontal,
            textScaler: MediaQuery.textScalerOf(context),
          );

          final overview = Column(
            children: [
              const SizedBox(height: 12),

              _editableSection(
                EstimateReviewSection.dates,
                _EstimateDatesCard(
                  record: _record,
                  onEdit: _canEditSections
                      ? () => _editReviewSection(EstimateReviewSection.dates)
                      : null,
                ),
              ),
              if (!widget.reviewBeforeSave) ...[
                _jobActions(),
                ProposalInvoiceAction(sourceId: _record.id),
                if (_record.customerSignature != null ||
                    _record.customerApprovals.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('Approved versions'),
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) =>
                            ProposalApprovalHistoryScreen(recordId: _record.id),
                      ),
                    ),
                  ),
              ],
            ],
          );
          final content = Column(
            children: [
              _editableSection(
                EstimateReviewSection.work,
                _EstimateScopeCard(
                  record: _record,
                  onEdit: _canEditSections
                      ? () => _editReviewSection(EstimateReviewSection.work)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              _editableSection(
                EstimateReviewSection.items,
                _EstimateItemsCard(
                  record: _record,
                  onEdit: _canEditSections
                      ? () => _editReviewSection(EstimateReviewSection.items)
                      : null,
                  onEditPricing: _canEditSections
                      ? () => _editReviewSection(EstimateReviewSection.pricing)
                      : null,
                ),
              ),
              if (!widget.reviewBeforeSave || layout.columns < 3) ...[
                const SizedBox(height: 12),
                _editableSection(
                  EstimateReviewSection.terms,
                  _EstimateTermsCard(
                    record: _record,
                    onEdit: _canEditSections
                        ? () => _editReviewSection(EstimateReviewSection.terms)
                        : null,
                  ),
                ),
              ],
              if (!widget.reviewBeforeSave && _record.requiredDepositCents > 0)
                _depositActions(),
            ],
          );
          return Scaffold(
            key: ValueKey('estimate-detail-${_record.id}'),
            body: SafeArea(
              child: ListView(
                padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
                children: [
                  Center(
                    child: SizedBox(
                      width: layout.workspaceWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          WorkDetailHeader(
                            label: widget.reviewBeforeSave
                                ? 'Review estimate'
                                : 'Estimate details',
                            selectedDay:
                                _record.estimateDates?.createdOn ??
                                _record.createdOn ??
                                DateTime.now(),
                            onBack: () => Navigator.of(context).pop(),
                            showDateContext: false,
                          ),
                          const SizedBox(height: 14),
                          _EstimateStatusCard(record: _record),
                          const SizedBox(height: 14),
                          SizedBox(
                            key: ValueKey('document-preview-${_record.id}'),
                          ),
                          _EstimateDetailHeading(
                            record: _record,
                            onContinueEditing: widget.reviewBeforeSave
                                ? () => Navigator.pop(context, false)
                                : null,
                            onEditCustomer: _canEditSections
                                ? () => _editReviewSection(
                                    EstimateReviewSection.customer,
                                  )
                                : null,
                            onEditWork: _canEditSections
                                ? () => _editReviewSection(
                                    EstimateReviewSection.work,
                                  )
                                : null,
                            onEditDate: _canEditSections
                                ? () => _editReviewSection(
                                    EstimateReviewSection.dates,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          if (widget.reviewBeforeSave)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Review your information before saving. Tap a section to make changes.',
                              ),
                            ),
                          if (!widget.reviewBeforeSave &&
                              _record.requiresCompanyReview) ...[
                            const SizedBox(height: 14),
                            _EstimateCompanyReviewCard(
                              record: _record,
                              permissions: widget.permissions,
                              onApprove: _approveCompanyReview,
                              onReturn: _returnCompanyReview,
                              onReject: _rejectCompanyReview,
                              onEdit: _editEstimate,
                              onSubmit: _submitCompanyReview,
                            ),
                          ],
                          const SizedBox(height: 14),
                          OperationsLaneGrid(
                            layout: layout,
                            children: [
                              content,
                              overview,
                              if (!widget.reviewBeforeSave ||
                                  layout.columns >= 3)
                                Column(
                                  children: [
                                    if (widget.reviewBeforeSave)
                                      _editableSection(
                                        EstimateReviewSection.terms,
                                        _EstimateTermsCard(
                                          record: _record,
                                          onEdit: _canEditSections
                                              ? () => _editReviewSection(
                                                  EstimateReviewSection.terms,
                                                )
                                              : null,
                                        ),
                                      ),
                                    if (!widget.reviewBeforeSave) ...[
                                      _documentActions(),
                                      const SizedBox(height: 12),
                                      _EstimateHistoryCard(record: _record),
                                    ],
                                    const SizedBox(height: 12),
                                    if (!widget.reviewBeforeSave)
                                      WorkActivityButton(record: _record),
                                  ],
                                ),
                            ],
                          ),
                          if (_canEditSections)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton.icon(
                                key: const ValueKey('review-add-photos'),
                                onPressed: () => _editReviewSection(
                                  EstimateReviewSection.photos,
                                ),
                                icon: const Icon(Icons.add_a_photo_outlined),
                                label: Text(
                                  _record.sitePhotos.isEmpty
                                      ? 'Add photos'
                                      : 'Add photos · ${_record.sitePhotos.length} attached',
                                ),
                              ),
                            ),
                          if (!widget.reviewBeforeSave) _approvalActions(),
                          if (widget.reviewBeforeSave &&
                              widget.onCustomerApproval != null)
                            _actionSection('Customer signature and approval', [
                              const Text(
                                'Save this estimate, then let the customer sign in person or record their approval.',
                              ),
                              OutlinedButton.icon(
                                key: const ValueKey('review-customer-approval'),
                                icon: const Icon(Icons.draw_outlined),
                                label: const Text(
                                  'Save and get customer approval',
                                ),
                                onPressed: () async {
                                  if (_saving || _editingSection) return;
                                  setState(() => _editingSection = true);
                                  try {
                                    final updated =
                                        await widget.onCustomerApproval!();
                                    if (mounted && updated != null) {
                                      setState(() => _record = updated);
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _editingSection = false);
                                    }
                                  }
                                },
                              ),
                            ]),
                          if (widget.reviewBeforeSave) ...[
                            const SizedBox(height: 24),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                FilledButton(
                                  key: const ValueKey(
                                    'confirm-estimate-review',
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Save estimate'),
                                ),
                                OutlinedButton(
                                  key: const ValueKey(
                                    'continue-editing-bottom',
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Continue editing'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool get _canEditSections => widget.reviewBeforeSave
      ? widget.onEditSection != null
      : widget.permissions.canEditItems;

  Widget _editableSection(EstimateReviewSection section, Widget child) {
    if (!_canEditSections) return child;
    return KeyedSubtree(
      key: ValueKey('review-section-${section.name}'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editReviewSection(section),
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }

  Future<void> _editReviewSection(EstimateReviewSection section) async {
    if (_saving || _editingSection) return;
    setState(() => _editingSection = true);
    try {
      if (widget.reviewBeforeSave) {
        final revised = await widget.onEditSection?.call(section);
        if (mounted && revised != null) setState(() => _record = revised);
      } else if (section == EstimateReviewSection.items) {
        await _editItems();
      } else {
        await _editEstimate(section: section);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your changes are kept in the form. Return to editing to finish them.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _editingSection = false);
    }
  }
}

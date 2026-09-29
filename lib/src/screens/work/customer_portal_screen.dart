import '../../data/work/work_customer_review_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/prototype_operations_store.dart';
import '../../shared/documents/customer_portal_gateway.dart';
import '../../shared/documents/customer_portal_scope.dart';
import '../../shared/utility_form_section.dart';
import 'estimate_models.dart';
import 'work_customer_document.dart';
import 'work_models.dart';

class CustomerPortalScreen extends StatefulWidget {
  const CustomerPortalScreen({required this.record, super.key});
  final WorkRecord record;
  @override
  State<CustomerPortalScreen> createState() => _CustomerPortalScreenState();
}

class _CustomerPortalScreenState extends State<CustomerPortalScreen> {
  CustomerReviewLink? _link;
  bool _busy = false, _initialized = false;
  WorkCustomerReviewSession _session(CustomerPortalGateway gateway) {
    final store = PrototypeOperationsScope.of(context);
    final work = store.workSession;
    if (work == null) throw StateError('Open a saved document first.');
    return WorkCustomerReviewSession(
      work: work,
      record: widget.record,
      gateway: gateway,
      document: workCustomerDocument(
        widget.record,
        store.companyProfile,
        resolveWorkDocumentCustomer(widget.record, store.customers),
        financialEntries: store.financialEntries,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _run((gateway) async {
          final saved = await _session(gateway).restore();
          if (mounted) setState(() => _link = saved);
        });
      }
    });
  }

  String? _message;

  void _authorize() {
    final work = PrototypeOperationsScope.of(context).workSession;
    if (work == null) throw StateError('A saved document is required.');
    work.requireActiveDraftOwner();
    final current = work.records
        .where((r) => r.id == widget.record.id)
        .firstOrNull;
    if (current == null ||
        current.revision != widget.record.revision ||
        !work.permissions.canShareDocuments ||
        !work.permissions.canEdit(current)) {
      throw StateError('Reopen the document with permission to share it.');
    }
    if (current.kind == WorkRecordKind.estimate &&
        (current.resolvedEstimateStage == EstimateStage.draft ||
            !current.companyReviewAllowsCustomerApproval)) {
      throw StateError(
        'Mark the estimate ready and complete any company approval first.',
      );
    }
    if (current.kind == WorkRecordKind.invoice &&
        !work.permissions.canIssueInvoices) {
      throw StateError('You do not have permission to share this invoice.');
    }
  }

  Future<void> _run(
    Future<void> Function(CustomerPortalGateway) operation,
  ) async {
    if (_busy) return;
    final gateway = CustomerPortalScope.maybeOf(context);
    if (gateway == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      _authorize();
      await operation(gateway);
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _message = error is StateError
              ? error.message.toString()
              : 'The portal could not be reached. Your document is still saved.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create(CustomerPortalGateway gateway) async {
    final store = PrototypeOperationsScope.of(context);
    final document = workCustomerDocument(
      widget.record,
      store.companyProfile,
      resolveWorkDocumentCustomer(widget.record, store.customers),
      financialEntries: store.financialEntries,
    );
    final link = await gateway.create(widget.record.id, document);
    if (!mounted) return;
    try {
      _authorize();
      await _session(gateway).retain(link);
    } on Object {
      await gateway.revoke(link);
      rethrow;
    }
    setState(() => _link = link);
  }

  @override
  Widget build(BuildContext context) {
    final configured = CustomerPortalScope.maybeOf(context) != null;
    final link = _link;
    return Scaffold(
      appBar: AppBar(title: const Text('Customer review link')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            UtilityFormSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.record.number,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(widget.record.client),
                  Text(widget.record.title),
                  const SizedBox(height: 8),
                  Text(
                    configured
                        ? 'Create a private link for the customer to review this document. Anyone with the link can open it; send it only to the intended customer.'
                        : 'Online customer review is not connected for this installation yet. You can share the PDF from the document’s sharing options. A live link needs the company’s online account and portal address.',
                  ),
                ],
              ),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_message!, semanticsLabel: _message),
              ),
            if (configured && link == null)
              FilledButton.icon(
                onPressed: _busy ? null : () => _run(_create),
                icon: const Icon(Icons.link),
                label: Text(_busy ? 'Creating link…' : 'Create customer link'),
              ),
            if (link != null) ...[
              Center(
                child: QrImageView(
                  data: link.url.toString(),
                  size: 240,
                  backgroundColor: Colors.white,
                  semanticsLabel: 'Private customer review link QR code',
                ),
              ),
              Text(
                'Link expires ${MaterialLocalizations.of(context).formatFullDate(link.expiresAt)}.',
              ),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run((_) async {
                        final box = context.findRenderObject() as RenderBox?;
                        await SharePlus.instance.share(
                          ShareParams(
                            text:
                                'Please review ${widget.record.number}: ${link.url}',
                            sharePositionOrigin: box == null
                                ? const Rect.fromLTWH(0, 0, 1, 1)
                                : box.localToGlobal(Offset.zero) & box.size,
                          ),
                        );
                      }),
                icon: const Icon(Icons.share),
                label: const Text('Share by email or text'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run((_) async {
                        await Clipboard.setData(
                          ClipboardData(text: link.url.toString()),
                        );
                        if (mounted) {
                          setState(() => _message = 'Private link copied.');
                        }
                      }),
                child: const Text('Copy link'),
              ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _run((gateway) async {
                        final message = await _session(gateway).check(link);
                        if (mounted) setState(() => _message = message);
                      }),
                child: const Text('Check customer response'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run((gateway) async {
                        await gateway.revoke(link);
                        await _session(gateway).markRevoked();
                        if (mounted) {
                          setState(() {
                            _link = null;
                            _message =
                                'The link is no longer available to the customer.';
                          });
                        }
                      }),
                child: const Text('Turn off this link'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/proposal_approval_history.dart';
import '../../data/work/models/work_models.dart';
import '../../layout/app_layout_engine.dart';
import 'work_overview_scope.dart';

class ProposalApprovalHistoryScreen extends StatefulWidget {
  const ProposalApprovalHistoryScreen({required this.recordId, super.key});
  final String recordId;
  @override
  State<ProposalApprovalHistoryScreen> createState() =>
      _ProposalApprovalHistoryScreenState();
}

class _ProposalApprovalHistoryScreenState
    extends State<ProposalApprovalHistoryScreen> {
  final Map<int, WorkRecord> _versions = {};
  int? _next;
  bool _started = false, _loading = false, _more = true;
  Object? _sessionIdentity;
  int _generation = 0;
  String? _error;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final identity = PrototypeOperationsScope.of(context).workSession;
    if (!_started || !identical(identity, _sessionIdentity)) {
      _sessionIdentity = identity;
      _generation++;
      _versions.clear();
      _next = null;
      _loading = false;
      _more = true;
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    if (_loading) return;
    final work = PrototypeOperationsScope.of(context).workSession;
    final generation = _generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (work == null) throw StateError('Document history is unavailable.');
      final page = await work.approvedProposalHistory(
        widget.recordId,
        beforeStorageRevision: _next,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        for (final record in page.records) {
          _versions.putIfAbsent(record.revision, () => record);
        }
        _next = page.nextBefore;
        _more = _next != null;
      });
    } on Object {
      if (mounted && generation == _generation) {
        setState(() {
          _versions.clear();
          _next = null;
          _more = true;
          _error =
              'History could not be verified or loaded. Saved records have been kept.';
        });
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = visibleWorkOverviewRecords(
      context,
    ).any((r) => r.id == widget.recordId);
    return Scaffold(
      appBar: AppBar(title: const Text('Approved versions')),
      body: !visible
          ? const Center(child: Text('This document is unavailable.'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final insets = AppLayoutEngine.pageInsetsFor(
                  constraints.maxWidth,
                );
                return SingleChildScrollView(
                  padding: insets,
                  child: Center(
                    child: SizedBox(
                      width: AppLayoutEngine.formWorkspaceWidthFor(
                        constraints.maxWidth - insets.horizontal,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Open an approved version to see the work, price, terms and approval saved at that time.',
                          ),
                          const SizedBox(height: 16),
                          for (final record in _versions.values)
                            ExpansionTile(
                              key: ValueKey(
                                'approved-version-${record.revision}',
                              ),
                              title: Text(
                                'Version ${record.revision} · \$${record.total.toStringAsFixed(2)}',
                              ),
                              subtitle: Text(
                                record.hasCurrentCustomerSignature
                                    ? 'Signed by ${record.customerSignature!.signedBy}'
                                    : 'Approval recorded without a signature',
                              ),
                              children: [
                                _ApprovedVersionDetails(record: record),
                              ],
                            ),
                          if (!_loading &&
                              _error == null &&
                              _versions.isEmpty &&
                              !_more)
                            const Text('No approved versions have been saved.'),
                          if (_loading)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          if (_error != null) Text(_error!),
                          if (!_loading && (_more || _error != null))
                            TextButton(
                              onPressed: _load,
                              child: Text(
                                _error == null
                                    ? 'Load earlier versions'
                                    : 'Retry',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ApprovedVersionDetails extends StatelessWidget {
  const _ApprovedVersionDetails({required this.record});
  final WorkRecord record;
  @override
  Widget build(BuildContext context) {
    final signature = record.customerSignature;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(record.title, style: Theme.of(context).textTheme.titleMedium),
          Text(record.client),
          const SizedBox(height: 12),
          Text(record.detail),
          for (final item in record.items)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${item.name}: ${item.quantity} ${item.unit} · \$${item.total.toStringAsFixed(2)}',
              ),
            ),
          const SizedBox(height: 12),
          Text('Discount: \$${record.discount.toStringAsFixed(2)}'),
          Text('Tax: \$${record.tax.toStringAsFixed(2)}'),
          Text('Total: \$${record.total.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          Text(
            'Terms and conditions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(record.terms.isEmpty ? 'No terms were recorded.' : record.terms),
          const SizedBox(height: 16),
          if (signature != null && signature.isCurrentFor(record.revision)) ...[
            Text(
              'Signed by ${signature.signedBy} · ${MaterialLocalizations.of(context).formatFullDate(signature.signedOn.toLocal())}',
            ),
            if (signature.ink?.hasInk == true)
              Semantics(
                label: 'Saved customer signature',
                image: true,
                child: SizedBox(
                  height: 150,
                  child: CustomPaint(
                    painter: _SavedSignaturePainter(
                      signature.ink!,
                      Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
          ],
          for (final approval in record.customerApprovals.where(
            (a) => a.revision == record.revision,
          )) ...[
            Text('${approval.customerName} · ${approval.method.label}'),
            Text(
              MaterialLocalizations.of(
                context,
              ).formatFullDate(approval.recordedOn.toLocal()),
            ),
            if (approval.note.isNotEmpty) Text(approval.note),
          ],
        ],
      ),
    );
  }
}

class _SavedSignaturePainter extends CustomPainter {
  _SavedSignaturePainter(this.ink, this.color);
  final SignatureInk ink;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = ink.strokeWidth ?? 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in ink.strokes) {
      if (stroke.isEmpty) continue;
      final path = Path()
        ..moveTo(stroke.first.$1 * size.width, stroke.first.$2 * size.height);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.$1 * size.width, point.$2 * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SavedSignaturePainter old) =>
      old.ink != ink || old.color != color;
}

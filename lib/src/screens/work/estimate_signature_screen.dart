import 'dart:async';
import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/work_persistence_session.dart';
import '../../data/work/estimate_signature_draft_workflow.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import '../../shared/section_card.dart';

import 'work_models.dart';

part 'estimate_signature_draft_recovery.dart';

class EstimateSignatureScreen extends StatefulWidget {
  const EstimateSignatureScreen({
    required this.record,
    this.recoveredWorkflow,
    this.forBusiness = false,
    this.embedded = false,
    this.onSaved,
    this.onDiscarded,
    this.onStateChanged,
    this.approvalEnabled = true,
    super.key,
  });
  final WorkRecord record;
  final bool forBusiness;
  final bool embedded;
  final bool approvalEnabled;
  final Future<void> Function(WorkRecord)? onSaved;
  final VoidCallback? onDiscarded;
  final VoidCallback? onStateChanged;
  final EstimateSignatureDraftController? recoveredWorkflow;

  @override
  State<EstimateSignatureScreen> createState() =>
      EstimateSignatureScreenState();
}

class EstimateSignatureScreenState extends State<EstimateSignatureScreen>
    with DraftNavigationGuard {
  bool get _forBusiness => _workflow?.input.forBusiness ?? widget.forBusiness;
  late final _name = TextEditingController(
    text: widget.forBusiness ? '' : _base.client,
  );
  final _strokes = <List<Offset>>[];
  var _accepted = false;
  DraftAutosaveSession? get draft => _draft;
  bool get isSaving => _saving;
  double _strokeWidth = 3;
  final _padKey = GlobalKey();
  late WorkRecord _base = widget.record;
  WorkPersistenceSession? _work;
  late EstimateSignatureDraftController? _workflow = widget.recoveredWorkflow;
  EstimateSignatureInput? _previewInput;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _subscription;
  bool _initialized = false, _ready = false, _saving = false;
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
    unawaited(_openSignatureDraft());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _content(context);
    return guardDraftNavigation(
      Scaffold(
        key: const ValueKey('estimate-signature-screen'),
        appBar: AppBar(
          title: Text(_forBusiness ? 'Business signature' : 'Review and sign'),
          leading: BackButton(onPressed: () => leaveDraftRoute()),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final insets = AppLayoutEngine.pageInsetsFor(
                constraints.maxWidth,
              );
              final width = AppLayoutEngine.formWorkspaceWidthFor(
                constraints.maxWidth - insets.horizontal,
              );
              return SingleChildScrollView(
                padding: insets.copyWith(top: 12, bottom: 28),
                child: Center(
                  child: SizedBox(width: width, child: _content(context)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (!widget.embedded) ...[
        const SizedBox(height: 16),
        Text(
          _forBusiness
              ? 'Sign for your business'
              : widget.record.kind == WorkRecordKind.quote
              ? 'Approve quote in person'
              : 'Approve estimate in person',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '${_base.number} · Revision ${_base.revision} · \$${_base.total.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_base.title, style: Theme.of(context).textTheme.titleMedium),
              Text(_base.detail),
              const SizedBox(height: 12),
              Text(
                'Work and prices',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final item in _base.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(item.name),
                      Text(
                        '${item.quantity} ${item.unit} · \$${item.total.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              const Divider(),
              Text(
                'Subtotal: \$${_base.items.fold<double>(0, (sum, item) => sum + item.total).toStringAsFixed(2)}',
              ),
              Text('Discount: \$${_base.discount.toStringAsFixed(2)}'),
              Text('Tax: \$${_base.tax.toStringAsFixed(2)}'),
              Text(
                '${_base.kind == WorkRecordKind.quote ? 'Quote total' : 'Estimated total'}: \$${_base.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Terms and conditions',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(_base.terms),
              if (_base.requiredDepositCents > 0)
                Text(
                  'Required deposit: \$${(_base.requiredDepositCents / 100).toStringAsFixed(2)}',
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (_draft?.state == DraftSaveState.notSaved)
        EditorDraftStatus(
          state: _draft!.state,
          onRetry: _draft!.retry,
          onDiscard: _discardSignature,
        ),
      if (_error != null) Text(_error!),
      if (!_ready && _error == null) const Text('Opening saved signature…'),
      if (_ready)
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const ValueKey('signature-customer-name'),
                controller: _name,
                decoration: InputDecoration(
                  labelText: _forBusiness ? 'Your name' : 'Customer name',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _ink.hasInk ? 'Signature added' : 'Customer signature needed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 12),
              const Text('Signature thickness'),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in [
                    (2.0, 'Fine'),
                    (3.0, 'Medium'),
                    (4.0, 'Bold'),
                  ])
                    ChoiceChip(
                      key: ValueKey('signature-thickness-${option.$2}'),
                      label: Text(option.$2),
                      selected: _strokeWidth == option.$1,
                      onSelected: _saving
                          ? null
                          : (_) {
                              setState(() {
                                _strokeWidth = option.$1;
                                _accepted = false;
                              });
                              _captureSignature();
                            },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Sign here with a finger or stylus',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Container(
                key: _padKey,
                height: 210,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: GestureDetector(
                  key: const ValueKey('estimate-signature-pad'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) =>
                      _addInk(details.localPosition, newStroke: true),
                  onPanUpdate: (details) => _addInk(details.localPosition),
                  child: CustomPaint(
                    painter: _SignaturePainter(
                      strokes: _strokes,
                      strokeWidth: _strokeWidth,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    child: _strokes.isEmpty
                        ? Center(
                            child: Text(
                              'Sign inside this box',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _clearSignature,
                    child: const Text('Clear'),
                  ),
                ],
              ),
              CheckboxListTile(
                key: const ValueKey('signature-approval-confirmed'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _accepted,
                title: Text(
                  _forBusiness
                      ? 'I sign revision ${_base.revision} on behalf of my business'
                      : 'I approve revision ${_base.revision} for \$${_base.total.toStringAsFixed(2)}',
                ),
                subtitle: const Text(
                  'This signature applies to this revision. Changes require a fresh review and approval.',
                ),
                onChanged: _ink.hasInk
                    ? (value) => _changeAcceptance(value ?? false)
                    : null,
              ),
            ],
          ),
        ),
      const SizedBox(height: 16),
      FilledButton.icon(
        key: const ValueKey('save-customer-signature'),
        onPressed:
            widget.approvalEnabled &&
                _ready &&
                !_saving &&
                _accepted &&
                _ink.hasInk
            ? _save
            : null,
        icon: const Icon(Icons.verified_outlined),
        label: Text(
          _forBusiness ? 'Save business signature' : 'Save customer approval',
        ),
      ),
    ],
  );
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({
    required this.strokes,
    required this.color,
    required this.strokeWidth,
  });
  final double strokeWidth;
  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(
          Offset(stroke.first.dx * size.width, stroke.first.dy * size.height),
          1.1,
          paint..style = PaintingStyle.fill,
        );
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()
        ..moveTo(stroke.first.dx * size.width, stroke.first.dy * size.height);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

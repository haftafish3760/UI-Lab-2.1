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
import 'work_detail_header.dart';
import 'work_models.dart';

part 'estimate_signature_draft_recovery.dart';

class EstimateSignatureScreen extends StatefulWidget {
  const EstimateSignatureScreen({
    required this.record,
    this.recoveredWorkflow,
    super.key,
  });
  final WorkRecord record;
  final EstimateSignatureDraftController? recoveredWorkflow;

  @override
  State<EstimateSignatureScreen> createState() =>
      _EstimateSignatureScreenState();
}

class _EstimateSignatureScreenState extends State<EstimateSignatureScreen>
    with DraftNavigationGuard {
  late final _name = TextEditingController(text: _base.client);
  final _strokes = <List<Offset>>[];
  var _accepted = false;
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
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      key: const ValueKey('estimate-signature-screen'),
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
                          label: 'Customer signature',
                          selectedDay:
                              _base.estimateDates?.createdOn ?? DateTime.now(),
                          onBack: () => leaveDraftRoute(),
                          showDateContext: true,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Approve estimate in person',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_base.number} · Revision ${_base.revision} · \$${_base.total.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 14),
                        if (_draft != null)
                          EditorDraftStatus(
                            state: _draft!.state,
                            onRetry: _draft!.retry,
                            onDiscard: _discardSignature,
                          ),
                        if (_error != null) Text(_error!),
                        if (!_ready && _error == null)
                          const Text('Opening saved signature…'),
                        if (_ready)
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  key: const ValueKey(
                                    'signature-customer-name',
                                  ),
                                  controller: _name,
                                  decoration: const InputDecoration(
                                    labelText: 'Customer name',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Sign below',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  key: _padKey,
                                  height: 210,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: GestureDetector(
                                    key: const ValueKey(
                                      'estimate-signature-pad',
                                    ),
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (details) => _addInk(
                                      details.localPosition,
                                      newStroke: true,
                                    ),
                                    onPanUpdate: (details) =>
                                        _addInk(details.localPosition),
                                    child: CustomPaint(
                                      painter: _SignaturePainter(
                                        strokes: _strokes,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                      child: _strokes.isEmpty
                                          ? Center(
                                              child: Text(
                                                'Use a finger or stylus to sign',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: TextButton.icon(
                                    onPressed: _clearSignature,
                                    icon: const Icon(Icons.clear_rounded),
                                    label: const Text('Clear signature'),
                                  ),
                                ),
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  value: _accepted,
                                  title: Text(
                                    'I approve revision ${_base.revision} for \$${_base.total.toStringAsFixed(2)}',
                                  ),
                                  subtitle: const Text(
                                    'Changing customer-visible scope or price will cancel this approval and require a new signature.',
                                  ),
                                  onChanged: (value) =>
                                      _changeAcceptance(value ?? false),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          key: const ValueKey('save-customer-signature'),
                          onPressed:
                              _ready && !_saving && _accepted && _ink.hasInk
                              ? _save
                              : null,
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text('Save customer approval'),
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
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({required this.strokes, required this.color});
  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.25
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

import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'work_detail_header.dart';
import 'work_models.dart';

class EstimateSignatureScreen extends StatefulWidget {
  const EstimateSignatureScreen({required this.record, super.key});
  final WorkRecord record;

  @override
  State<EstimateSignatureScreen> createState() =>
      _EstimateSignatureScreenState();
}

class _EstimateSignatureScreenState extends State<EstimateSignatureScreen> {
  late final _name = TextEditingController(text: widget.record.client);
  final _strokes = <List<Offset>>[];
  var _accepted = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                            widget.record.estimateDates?.createdOn ??
                            DateTime.now(),
                        onBack: () => Navigator.of(context).pop(),
                        showDateContext: true,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Approve estimate in person',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.record.number} · Revision ${widget.record.revision} · \$${widget.record.total.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              key: const ValueKey('signature-customer-name'),
                              controller: _name,
                              decoration: const InputDecoration(
                                labelText: 'Customer name',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sign below',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Container(
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
                                onPanStart: (details) => setState(
                                  () => _strokes.add([details.localPosition]),
                                ),
                                onPanUpdate: (details) => setState(
                                  () =>
                                      _strokes.last.add(details.localPosition),
                                ),
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
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton.icon(
                                onPressed: () => setState(_strokes.clear),
                                icon: const Icon(Icons.clear_rounded),
                                label: const Text('Clear signature'),
                              ),
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: _accepted,
                              title: Text(
                                'I approve revision ${widget.record.revision} for \$${widget.record.total.toStringAsFixed(2)}',
                              ),
                              subtitle: const Text(
                                'Changing customer-visible scope or price will cancel this approval and require a new signature.',
                              ),
                              onChanged: (value) =>
                                  setState(() => _accepted = value ?? false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const ValueKey('save-customer-signature'),
                        onPressed: _accepted && _strokes.isNotEmpty
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
  );

  void _save() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter the customer name.')));
      return;
    }
    Navigator.of(context).pop(_name.text.trim());
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({required this.strokes, required this.color});
  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.1, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../data/device_capabilities/device_workload_service.dart';
import '../../shared/local_document_path_scope.dart';

/// Bounded screen preview. Reading also uses a separately bounded working copy.
/// The original file remains available; this does not compress saved evidence.
class ReceiptPhotoPreview extends StatefulWidget {
  const ReceiptPhotoPreview({
    required this.path,
    required this.name,
    this.fullScreen = false,
    super.key,
  });
  final String path;
  final String name;
  final bool fullScreen;

  @override
  State<ReceiptPhotoPreview> createState() => _ReceiptPhotoPreviewState();
}

class _ReceiptPhotoPreviewState extends State<ReceiptPhotoPreview> {
  final _transform = TransformationController();
  final _viewport = GlobalKey();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ReceiptPhotoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _transform.value = Matrix4.identity();
  }

  void _zoom(double factor) {
    final box = _viewport.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final oldScale = _transform.value.getMaxScaleOnAxis();
    final nextScale = (oldScale * factor).clamp(1.0, 6.0);
    final center = box.size.center(Offset.zero);
    final point = _transform.toScene(center);
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        center.dx - point.dx * nextScale,
        center.dy - point.dy * nextScale,
        0,
        1,
      )
      ..scaleByDouble(nextScale, nextScale, 1, 1);
    if (nextScale == 1) _transform.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final String resolved;
    try {
      resolved = LocalDocumentPathScope.resolvePath(context, widget.path);
    } catch (_) {
      return const Center(
        child: Text('This receipt photo could not be located.'),
      );
    }
    final side = math
        .sqrt(DeviceWorkloadService.instance.latest.maxImagePixels)
        .floor();
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => _zoom(1.5),
                icon: const Icon(Icons.zoom_in),
                label: const Text('Zoom in'),
              ),
              TextButton.icon(
                onPressed: () => _zoom(1 / 1.5),
                icon: const Icon(Icons.zoom_out),
                label: const Text('Zoom out'),
              ),
              TextButton(
                onPressed: () => _transform.value = Matrix4.identity(),
                child: const Text('Fit receipt'),
              ),
              if (!widget.fullScreen)
                TextButton.icon(
                  icon: const Icon(Icons.fullscreen),
                  label: const Text('Full screen'),
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        body: SafeArea(
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Back to receipt'),
                                ),
                              ),
                              Expanded(
                                child: ReceiptPhotoPreview(
                                  path: resolved,
                                  name: widget.name,
                                  fullScreen: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: InteractiveViewer(
              key: _viewport,
              transformationController: _transform,
              minScale: 1,
              maxScale: 6,
              child: Center(
                child: Image(
                  image: ResizeImage(
                    FileImage(File(resolved)),
                    width: side,
                    height: side,
                    policy: ResizeImagePolicy.fit,
                  ),
                  fit: BoxFit.contain,
                  semanticLabel: 'Preview of ${widget.name}',
                  errorBuilder: (_, _, _) =>
                      const Text('This receipt photo could not be opened.'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

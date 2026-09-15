import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../data/device_capabilities/device_workload_service.dart';
import '../../shared/local_document_path_scope.dart';

/// Bounded screen preview. Reading also uses a separately bounded working copy.
/// The original file remains available; this does not compress saved evidence.
class ReceiptPhotoPreview extends StatelessWidget {
  const ReceiptPhotoPreview({
    required this.path,
    required this.name,
    super.key,
  });
  final String path;
  final String name;

  @override
  Widget build(BuildContext context) {
    final String resolved;
    try {
      resolved = LocalDocumentPathScope.resolvePath(context, path);
    } catch (_) {
      return const Center(
        child: Text('This receipt photo could not be located.'),
      );
    }
    final side = math
        .sqrt(DeviceWorkloadService.instance.latest.maxImagePixels)
        .floor();
    return InteractiveViewer(
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
          semanticLabel: 'Preview of $name',
          errorBuilder: (_, _, _) =>
              const Text('This receipt photo could not be opened.'),
        ),
      ),
    );
  }
}

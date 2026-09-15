import 'documents/pdf/pdf_document_view.dart';
import 'dart:io';
import 'local_document_path_scope.dart';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

enum LocalDocumentKind { image, pdf }

/// Read-only, zoomable preview for app-retained local evidence.
///
/// The caller remains responsible for authorization before providing a path.
/// This widget never copies, exports, deletes, or changes the source file.
class LocalDocumentPreview extends StatelessWidget {
  const LocalDocumentPreview({
    required this.path,
    required this.kind,
    required this.semanticsLabel,
    super.key,
  });

  final String path;
  final LocalDocumentKind kind;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final String resolvedPath;
    try {
      resolvedPath = LocalDocumentPathScope.resolvePath(context, path);
    } on Object {
      return const _DocumentUnavailable(
        message: 'This document could not be located.',
      );
    }
    return Semantics(
      label: semanticsLabel,
      image: kind == LocalDocumentKind.image,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: kind == LocalDocumentKind.pdf
              ? PdfDocumentView(key: ValueKey(resolvedPath), open: () => PdfDocument.openFile(resolvedPath))
              : _LocalImagePreview(path: resolvedPath),
        ),
      ),
    );
  }
}

class _LocalImagePreview extends StatelessWidget {
  const _LocalImagePreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) => InteractiveViewer(
    minScale: 1,
    maxScale: 6,
    child: Center(
      child: Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _DocumentUnavailable(
          message: 'This receipt image could not be opened.',
        ),
      ),
    ),
  );
}

class _DocumentUnavailable extends StatelessWidget {
  const _DocumentUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, size: 34),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

import 'dart:async';
import 'dart:io';

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
  Widget build(BuildContext context) => Semantics(
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
            ? _LocalPdfPreview(path: path)
            : _LocalImagePreview(path: path),
      ),
    ),
  );
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

class _LocalPdfPreview extends StatefulWidget {
  const _LocalPdfPreview({required this.path});

  final String path;

  @override
  State<_LocalPdfPreview> createState() => _LocalPdfPreviewState();
}

class _LocalPdfPreviewState extends State<_LocalPdfPreview> {
  late final Future<PdfDocument> _document;
  late final PdfController _controller;
  var _page = 1;
  int? _pageCount;

  @override
  void initState() {
    super.initState();
    _document = PdfDocument.openFile(widget.path);
    _controller = PdfController(document: _document);
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(
      _document.then<void>((document) => document.close(), onError: (_) {}),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      PdfView(
        controller: _controller,
        backgroundDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
        ),
        builders: PdfViewBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          pageLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, _) => const _DocumentUnavailable(
            message: 'This receipt PDF could not be opened.',
          ),
        ),
        onDocumentLoaded: (document) {
          if (mounted) setState(() => _pageCount = document.pagesCount);
        },
        onPageChanged: (page) {
          if (mounted) setState(() => _page = page);
        },
      ),
      if (_pageCount case final count?)
        PositionedDirectional(
          end: 10,
          bottom: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withAlpha(232),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: Text('Page $_page of $count'),
            ),
          ),
        ),
    ],
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

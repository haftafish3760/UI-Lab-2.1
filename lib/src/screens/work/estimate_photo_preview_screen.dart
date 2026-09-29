import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/local_document_preview.dart';
import 'work_models.dart';

/// Read-only preview of a photo already supplied by the authorized estimate
/// editor. No second media copy, upload, or external application is created.
class EstimatePhotoPreviewScreen extends StatelessWidget {
  const EstimatePhotoPreviewScreen({
    required this.photo,
    this.title = 'Estimate photo',
    super.key,
  });

  final WorkSitePhoto photo;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          final width = AppLayoutEngine.formWorkspaceWidthFor(
            constraints.maxWidth - insets.horizontal,
          );
          return SingleChildScrollView(
            padding: insets.copyWith(top: 12, bottom: 24),
            child: Center(
              child: SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      photo.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: constraints.maxHeight * .65,
                      child: LocalDocumentPreview(
                        path: photo.path,
                        kind: LocalDocumentKind.image,
                        semanticsLabel: '$title: ${photo.name}',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Zoom in to inspect the photo.'),
                    const SizedBox(height: 16),
                    Text(
                      'Photo details',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(photo.note.isEmpty ? 'No details added' : photo.note),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

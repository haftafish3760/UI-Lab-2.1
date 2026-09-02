import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'work_detail_header.dart';
import 'work_models.dart';

class EstimateSitePhotosScreen extends StatefulWidget {
  const EstimateSitePhotosScreen({
    required this.initialDay,
    required this.initialPhotos,
    super.key,
  });

  final DateTime initialDay;
  final List<WorkSitePhoto> initialPhotos;

  @override
  State<EstimateSitePhotosScreen> createState() =>
      _EstimateSitePhotosScreenState();
}

class _EstimateSitePhotosScreenState extends State<EstimateSitePhotosScreen> {
  late final _photos = [...widget.initialPhotos];
  final _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('estimate-site-photos-screen'),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          final layout = AppLayoutEngine.detailWorkspaceFor(
            constraints.maxWidth - insets.horizontal,
            textScaler: MediaQuery.textScalerOf(context),
          );
          return ListView(
            padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 96),
            children: [
              Center(
                child: SizedBox(
                  width: layout.columnWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WorkDetailHeader(
                        label: 'Job-site photos',
                        selectedDay: widget.initialDay,
                        onBack: () => Navigator.of(context).pop(),
                        showDateContext: true,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Photos and notes',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Keep a visual record of the work before pricing it. These photos stay inside the company unless you choose to include them later.',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            key: const ValueKey('take-estimate-photo'),
                            onPressed: _takePhoto,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Take photo'),
                          ),
                          OutlinedButton.icon(
                            key: const ValueKey('choose-estimate-photos'),
                            onPressed: _choosePhotos,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Choose photos'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _chooseImageFile,
                            icon: const Icon(Icons.folder_open_outlined),
                            label: const Text('Choose image file'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_photos.isEmpty)
                        const SectionCard(
                          child: Text(
                            'No job-site photos yet. Add the pictures needed to recognize the work later.',
                          ),
                        )
                      else
                        for (final photo in _photos) ...[
                          _SitePhotoRow(
                            photo: photo,
                            onNote: () => _editNote(photo),
                            onRemove: () => setState(
                              () => _photos.removeWhere(
                                (candidate) => candidate.id == photo.id,
                              ),
                            ),
                          ),
                          if (photo != _photos.last) const SizedBox(height: 8),
                        ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.all(12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: FilledButton.icon(
            key: const ValueKey('save-estimate-photos'),
            onPressed: () => Navigator.of(context).pop(_photos),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save photos and notes'),
          ),
        ),
      ),
    ),
  );

  Future<void> _takePhoto() async => _pickImages(() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      requestFullMetadata: false,
    );
    return image == null ? const [] : [image];
  }, WorkSitePhotoSource.camera);

  Future<void> _choosePhotos() async => _pickImages(
    () => _imagePicker.pickMultiImage(requestFullMetadata: false),
    WorkSitePhotoSource.library,
  );

  Future<void> _chooseImageFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        dialogTitle: 'Choose job-site photos',
      );
      if (!mounted || result.isEmpty) return;
      setState(() {
        for (final file in result) {
          final path = file.path?.trim();
          if (path == null || path.isEmpty) continue;
          _photos.add(_photo(path, file.name, WorkSitePhotoSource.file));
        }
      });
    } catch (error) {
      _showPickerError(error);
    }
  }

  Future<void> _pickImages(
    Future<List<XFile>> Function() pick,
    WorkSitePhotoSource source,
  ) async {
    try {
      final images = await pick();
      if (!mounted || images.isEmpty) return;
      setState(() {
        for (final image in images) {
          _photos.add(_photo(image.path, image.name, source));
        }
      });
    } catch (error) {
      _showPickerError(error);
    }
  }

  WorkSitePhoto _photo(
    String path,
    String name,
    WorkSitePhotoSource source,
  ) => WorkSitePhoto(
    id: 'site-photo-${DateTime.now().microsecondsSinceEpoch}-${_photos.length}',
    path: path,
    name: name,
    source: source,
    addedOn: DateTime.now(),
  );

  Future<void> _editNote(WorkSitePhoto photo) async {
    final controller = TextEditingController(text: photo.note);
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Example: Shutoff valve is behind the water heater.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save note'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || note == null) return;
    final index = _photos.indexWhere((candidate) => candidate.id == photo.id);
    if (index < 0) return;
    setState(() => _photos[index] = photo.withNote(note));
  }

  void _showPickerError(Object error) {
    if (!mounted) return;
    final message =
        error is PlatformException && error.message?.isNotEmpty == true
        ? error.message!
        : 'The device could not open that photo source. Please try again.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SitePhotoRow extends StatelessWidget {
  const _SitePhotoRow({
    required this.photo,
    required this.onNote,
    required this.onRemove,
  });

  final WorkSitePhoto photo;
  final VoidCallback onNote;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 64,
            height: 64,
            child: File(photo.path).existsSync()
                ? Image.file(File(photo.path), fit: BoxFit.cover)
                : const ColoredBox(
                    color: Colors.black12,
                    child: Icon(Icons.broken_image_outlined),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                photo.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(photo.note.isEmpty ? 'No note added' : photo.note),
              TextButton(
                onPressed: onNote,
                child: const Text('Add or edit note'),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Photo actions',
          onSelected: (value) {
            if (value == 'note') onNote();
            if (value == 'remove') onRemove();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'note', child: Text('Add or edit note')),
            PopupMenuItem(value: 'remove', child: Text('Remove photo')),
          ],
        ),
      ],
    ),
  );
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../layout/app_layout_engine.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/storage/local_media_picker_request.dart';
import '../../data/work/estimate_photo_media_workflow.dart';
import '../../data/storage/local_record_identity.dart';
import '../../data/work/estimate_photos_draft_input.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/nested_editor_draft_status.dart';
import '../../shared/section_card.dart';
import '../../shared/local_document_path_scope.dart';
import 'work_detail_header.dart';
import 'work_models.dart';
import 'estimate_photo_note_dialog.dart';

part 'estimate_photo_media.dart';

class EstimateSitePhotosScreen extends StatefulWidget {
  const EstimateSitePhotosScreen({
    required this.initialDay,
    required this.initialPhotos,
    this.retainPhotoFile,
    this.draftSession,
    this.mediaWorkflow,
    this.recoveryInput,
    this.onDraftChanged,
    super.key,
  });

  final Future<String> Function(String path)? retainPhotoFile;
  final DraftAutosaveSession? draftSession;
  final EstimatePhotoMediaWorkflow? mediaWorkflow;
  final EstimatePhotosDraftInput? recoveryInput;
  final ValueChanged<EstimatePhotosDraftInput>? onDraftChanged;
  final DateTime initialDay;
  final List<WorkSitePhoto> initialPhotos;

  @override
  State<EstimateSitePhotosScreen> createState() =>
      _EstimateSitePhotosScreenState();
}

class _EstimateSitePhotosScreenState extends State<EstimateSitePhotosScreen>
    with DraftNavigationGuard {
  @override
  DraftAutosaveSession? get navigationDraft => widget.draftSession;
  bool _importing = false;
  EstimatePhotoSelection? _pendingMedia;
  bool _checkedMedia = false;
  bool get _mediaLocked => _importing || _pendingMedia != null;
  void _refreshMedia(VoidCallback change) {
    if (mounted) setState(change);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checkedMedia) {
      _checkedMedia = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadPendingMedia();
      });
    }
  }

  @override
  bool get blockDraftNavigation => _importing;
  var _pendingNotes = <String, String>{};
  @override
  void initState() {
    super.initState();
    final input = widget.recoveryInput;
    if (input != null) {
      _photos
        ..clear()
        ..addAll(input.photos);
      _pendingNotes = Map.of(input.pendingNotes);
    }
  }

  EstimatePhotosDraftInput get _photoInput =>
      EstimatePhotosDraftInput(photos: _photos, pendingNotes: _pendingNotes);
  void _publishPhotos() => widget.onDraftChanged?.call(_photoInput);
  void _changePhotos(VoidCallback change) {
    setState(change);
    _publishPhotos();
  }

  late final _photos = [...widget.initialPhotos];
  final _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
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
                          onBack: () => leaveDraftRoute(),
                          showDateContext: true,
                        ),
                        if (widget.draftSession != null)
                          NestedEditorDraftStatus(
                            session: widget.draftSession!,
                          ),
                        if (_pendingMedia != null) _pendingMediaNotice(),
                        if (_pendingNotes.isNotEmpty)
                          const Text(
                            'Open the photo note to continue unfinished input before saving photos.',
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
                              onPressed: _mediaLocked ? null : _takePhoto,
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: const Text('Take photo'),
                            ),
                            OutlinedButton.icon(
                              key: const ValueKey('choose-estimate-photos'),
                              onPressed: _mediaLocked ? null : _choosePhotos,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Choose photos'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _mediaLocked ? null : _chooseImageFile,
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
                              onNote: () {
                                if (!_mediaLocked) _editNote(photo);
                              },
                              onRemove: () {
                                if (_mediaLocked) return;
                                _changePhotos(() {
                                  _photos.removeWhere(
                                    (candidate) => candidate.id == photo.id,
                                  );
                                  _pendingNotes.remove(photo.id);
                                });
                              },
                            ),
                            if (photo != _photos.last)
                              const SizedBox(height: 8),
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
              onPressed: _pendingNotes.isEmpty && !_mediaLocked
                  ? () => leaveDraftRoute(_photoInput.confirmedPhotos())
                  : null,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save photos and notes'),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _takePhoto() async {
    if (await _pickNativeMedia(MediaPickerSource.camera)) return;
    await _pickImages(() async {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        requestFullMetadata: false,
      );
      return image == null ? const [] : [image];
    }, WorkSitePhotoSource.camera);
  }

  Future<void> _choosePhotos() async {
    if (await _pickNativeMedia(MediaPickerSource.library)) return;
    await _pickImages(
      () => _imagePicker.pickMultiImage(requestFullMetadata: false),
      WorkSitePhotoSource.library,
    );
  }

  Future<void> _chooseImageFile() async {
    if (await _pickNativeMedia(MediaPickerSource.files)) return;
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        dialogTitle: 'Choose job-site photos',
      );
      if (!mounted || result.isEmpty) return;
      for (final file in result) {
        final path = file.path?.trim();
        if (path == null || path.isEmpty) continue;
        await _retainPhoto(path, file.name, WorkSitePhotoSource.file);
      }
    } catch (error) {
      _showPickerError(error);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _pickImages(
    Future<List<XFile>> Function() pick,
    WorkSitePhotoSource source,
  ) async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final images = await pick();
      if (!mounted || images.isEmpty) return;
      for (final image in images) {
        await _retainPhoto(image.path, image.name, source);
      }
    } catch (error) {
      _showPickerError(error);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _retainPhoto(
    String path,
    String name,
    WorkSitePhotoSource source,
  ) async {
    final retainedPath = await widget.retainPhotoFile?.call(path) ?? path;
    if (!mounted) return;
    _changePhotos(() => _photos.add(_photo(retainedPath, name, source)));
    await widget.draftSession?.flush();
  }

  WorkSitePhoto _photo(String path, String name, WorkSitePhotoSource source) =>
      WorkSitePhoto(
        id: newLocalRecordIdentity('site-photo'),
        path: path,
        name: name,
        source: source,
        addedOn: DateTime.now(),
      );

  Future<void> _editNote(WorkSitePhoto photo) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => EstimatePhotoNoteDialog(
        initialText: _pendingNotes[photo.id] ?? photo.note,
        onChanged: (value) =>
            _changePhotos(() => _pendingNotes[photo.id] = value),
      ),
    );
    if (!mounted || note == null) return;
    final index = _photos.indexWhere((candidate) => candidate.id == photo.id);
    if (index < 0) return;
    _changePhotos(() {
      _photos[index] = photo.withNote(note);
      _pendingNotes.remove(photo.id);
    });
  }

  void _showPickerError(Object error) {
    if (!mounted) return;
    final permissionDenied = error is PlatformException &&
        {'camera_access_denied', 'camera_access_denied_without_prompt',
         'camera_access_restricted', 'photo_access_denied', 'photo_access_restricted'}.contains(error.code);
    final message = permissionDenied
        ? 'Access was not allowed. You can allow Camera in your phone Settings, or choose an existing photo. Your saved work is unchanged.'
        : error is PlatformException && error.message?.isNotEmpty == true
        ? error.message!
        : 'The photo could not be retained. Existing photos and input have been kept. Please try again.';
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

  Widget _preview(BuildContext context) {
    const missing = ColoredBox(
      color: Colors.black12,
      child: Icon(Icons.broken_image_outlined),
    );
    try {
      final file = File(
        LocalDocumentPathScope.resolvePath(context, photo.path),
      );
      if (!file.existsSync()) return missing;
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => missing,
      );
    } on Object {
      return missing;
    }
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(width: 64, height: 64, child: _preview(context)),
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

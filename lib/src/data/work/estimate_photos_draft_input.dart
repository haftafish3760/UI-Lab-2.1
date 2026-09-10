import 'models/work_models.dart';
import 'work_record_detail_codec.dart';

/// Stable photo identities and unfinished notes, independent of visual order
/// controls, dialog placement, or the widget used to edit a note.
class EstimatePhotosDraftInput {
  EstimatePhotosDraftInput({
    required List<WorkSitePhoto> photos,
    required Map<String, String> pendingNotes,
  }) : photos = List.unmodifiable(photos),
       pendingNotes = Map.unmodifiable(pendingNotes);
  final List<WorkSitePhoto> photos;
  final Map<String, String> pendingNotes;
  Map<String, Object?> toPayload() => {
    'photos': photos.map(encodeWorkSitePhoto).toList(),
    'pendingNotes': Map<String, String>.of(pendingNotes),
  };
  factory EstimatePhotosDraftInput.fromPayload(Map<String, Object?> input) =>
      EstimatePhotosDraftInput(
        photos: (input['photos'] as List)
            .map(
              (photo) =>
                  decodeWorkSitePhoto((photo as Map).cast<String, Object?>()),
            )
            .toList(),
        pendingNotes: (input['pendingNotes'] as Map).cast<String, String>(),
      );
  List<WorkSitePhoto> confirmedPhotos() {
    if (pendingNotes.isNotEmpty) {
      throw StateError('Finish or discard unfinished photo notes first.');
    }
    return photos;
  }
}

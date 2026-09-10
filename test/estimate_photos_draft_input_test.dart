import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_photos_draft_input.dart';

void main() {
  test(
    'legacy photo input preserves order and raw notes without mutable aliases',
    () {
      final raw = <String, Object?>{
        'photos': <Object?>[],
        'pendingNotes': <String, String>{'photo': ' Half-written '},
      };
      final input = EstimatePhotosDraftInput.fromPayload(raw);
      expect(input.toPayload(), raw);
      expect(input.confirmedPhotos, throwsStateError);
      (raw['pendingNotes'] as Map)['photo'] = 'changed elsewhere';
      expect(input.pendingNotes['photo'], ' Half-written ');
      expect(() => input.pendingNotes.clear(), throwsUnsupportedError);
      expect(() => input.photos.clear(), throwsUnsupportedError);
      final encoded = input.toPayload();
      (encoded['pendingNotes'] as Map).clear();
      expect(input.pendingNotes, isNotEmpty);
      final complete = EstimatePhotosDraftInput(photos: [], pendingNotes: {});
      expect(complete.confirmedPhotos(), isEmpty);
    },
  );
  test('malformed unfinished notes do not silently become confirmed state', () {
    expect(
      () => EstimatePhotosDraftInput.fromPayload({
        'photos': [],
        'pendingNotes': {'photo': 3},
      }),
      throwsA(isA<TypeError>()),
    );
  });
}

import 'dart:collection';

import 'package:path/path.dart' as path;

String? normalizedReceiptPhotoPath(String photoPath) {
  final trimmed = photoPath.trim();
  if (trimmed.isEmpty || trimmed != photoPath) return null;
  final normalized = path.normalize(trimmed);
  if (normalized != trimmed) return null;
  return normalized;
}

List<String> uniqueNormalizedReceiptPhotoPaths(Iterable<String> photoPaths) {
  final uniquePaths = <String>[];
  final seenPaths = <String>{};
  for (final photoPath in photoPaths) {
    final normalized = normalizedReceiptPhotoPath(photoPath);
    if (normalized == null) continue;
    if (seenPaths.add(normalized)) uniquePaths.add(normalized);
  }
  return UnmodifiableListView(uniquePaths);
}

class ReceiptPhotoImportOrderPlan {
  const ReceiptPhotoImportOrderPlan._({
    required this.existingPhotoPaths,
    required this.importedPhotoPaths,
    required this.mergedPhotoPaths,
  });

  factory ReceiptPhotoImportOrderPlan.build({
    required Iterable<String> existingPhotoPaths,
    required Iterable<String> importedPhotoPaths,
  }) {
    final existing = uniqueNormalizedReceiptPhotoPaths(existingPhotoPaths);
    final merged = uniqueNormalizedReceiptPhotoPaths([
      ...existing,
      ...importedPhotoPaths,
    ]);
    return ReceiptPhotoImportOrderPlan._(
      existingPhotoPaths: existing,
      importedPhotoPaths: List.unmodifiable(merged.skip(existing.length)),
      mergedPhotoPaths: merged,
    );
  }

  final List<String> existingPhotoPaths;
  final List<String> importedPhotoPaths;
  final List<String> mergedPhotoPaths;

  bool get hasNewPhotos => importedPhotoPaths.isNotEmpty;
  int get firstImportedPhotoIndex => existingPhotoPaths.length;
}

bool receiptPhotoPathsAreUniqueAndNormalized(List<String> photoPaths) {
  final uniquePaths = uniqueNormalizedReceiptPhotoPaths(photoPaths);
  if (uniquePaths.length != photoPaths.length) return false;
  for (var index = 0; index < photoPaths.length; index++) {
    if (uniquePaths[index] != photoPaths[index]) return false;
  }
  return true;
}

bool receiptPhotoPathSetContains(
  Iterable<String> photoPaths,
  String candidatePath,
) {
  final normalizedCandidate = normalizedReceiptPhotoPath(candidatePath);
  if (normalizedCandidate == null) return false;
  for (final photoPath in photoPaths) {
    if (normalizedReceiptPhotoPath(photoPath) == normalizedCandidate) {
      return true;
    }
  }
  return false;
}

bool receiptPhotoPathOrderMatches(
  Iterable<String> expectedPaths,
  Iterable<String> currentPaths,
) {
  final expected = expectedPaths.toList(growable: false);
  final current = currentPaths.toList(growable: false);
  if (expected.length != current.length) return false;
  for (var index = 0; index < expected.length; index++) {
    final expectedPath = normalizedReceiptPhotoPath(expected[index]);
    final currentPath = normalizedReceiptPhotoPath(current[index]);
    if (expectedPath == null || currentPath == null) return false;
    if (expectedPath != currentPath) return false;
  }
  return true;
}

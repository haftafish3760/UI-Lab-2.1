import 'dart:math' as math;
import 'receipt_stitch_working_copy.dart';

import '../device_capabilities/device_workload_service.dart';
import 'image_pipeline/receipt_capture_models.dart';
import 'image_pipeline/receipt_image_processor.dart';
import 'receipt_stitch_text_evidence.dart';

/// Shared admission, bounded working-copy preparation and receipt stitching.
/// Original source paths remain authoritative on success and fallback.
class ReceiptStitchService {
  ReceiptStitchService({DeviceWorkloadService? workloads})
    : workloads = workloads ?? DeviceWorkloadService.instance;

  final DeviceWorkloadService workloads;

  Future<ReceiptStitchResult> stitch({
    required List<String> paths,
    List<ReceiptStitchTextEvidence>? textEvidence,
    bool Function()? cancelled,
    List<bool>? manualZeroOverlapPairs,
  }) async {
    if (paths.length < 2 || paths.length > 8) {
      throw ArgumentError('Stitching requires two to eight prepared sections.');
    }
    final input = List<String>.unmodifiable(paths);
    return workloads.run(
      (profile) async {
        var totalPixels = 0;
        var maximumPixels = 0;
        var encodedBytes = 0;
        void active() {
          workloads.requireActive();
          if (cancelled?.call() ?? false) {
            throw const DeviceWorkloadUnavailable(
              'Receipt processing cancelled.',
            );
          }
        }

        final workingPaths = <String>[];
        final perImagePixels = math.min(
          profile.maxImagePixels,
          (40 * 1024 * 1024) ~/ (16 * (input.length + 1)),
        );
        for (final path in input) {
          final copy = await ReceiptStitchWorkingCopy.prepare(
            path: path,
            maxPixels: perImagePixels,
            profile: profile,
            checkActive: active,
            beforeWrite: () async {
              await workloads.checkpoint();
            },
          );
          workingPaths.add(copy.path);
          totalPixels += copy.pixels;
          maximumPixels = math.max(maximumPixels, copy.pixels);
          encodedBytes += copy.encodedBytes;
        }
        // Source, comparison and transformed images plus output/encoder space.
        // Admission reserves 48 MiB; never start an image worker above that bound.
        final estimatedBytes =
            totalPixels * 16 + maximumPixels * 16 + encodedBytes;
        if (estimatedBytes > 48 * 1024 * 1024) {
          throw const DeviceWorkloadUnavailable(
            'These sections need smaller processing copies to combine safely.',
          );
        }
        await workloads.checkpoint();
        active();
        final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
          paths: workingPaths,
          textEvidence: textEvidence == null
              ? null
              : [
                  for (var index = 0; index < input.length; index++)
                    for (final evidence in textEvidence)
                      if (evidence.path == input[index])
                        ReceiptStitchTextEvidence(
                          path: workingPaths[index],
                          lines: evidence.lines,
                          positionedLines: evidence.positionedLines,
                        ),
                ],
          manualZeroOverlapPairs: manualZeroOverlapPairs,
          maxOutputPixels: math.min(totalPixels, profile.maxImagePixels * 2),
          maxOutputHeight: 20000,
          maxTargetWidth: profile.constrained ? 1000 : 1400,
          processingTimeout: const Duration(seconds: 30),
          shouldCancel: () =>
              workloads.stopRequested || (cancelled?.call() ?? false),
          // The transferred native registration bridge is not installed in UI
          // Lab. Dart registration supplies the tested geometry implementation.
          nativeRegistrationProposals: const [],
        );
        return ReceiptStitchResult(
          status: result.status,
          inputPaths: input,
          ocrSourcePaths: result.didStitch ? result.ocrSourcePaths : input,
          stitchedPath: result.stitchedPath,
          confidence: result.confidence,
          overlapPixels: result.overlapPixels,
          pairs: result.pairs,
          failedPairIndex: result.failedPairIndex,
          stitchedWidth: result.stitchedWidth,
          stitchedHeight: result.stitchedHeight,
          warning: result.warning,
          usedManualAdjustment: result.usedManualAdjustment,
          fallbackReasonCode: result.fallbackReasonCode,
        );
      },
      request: const DeviceWorkloadRequest(
        storageBytes: 48 * 1024 * 1024,
        memoryBytes: 48 * 1024 * 1024,
      ),
    );
  }
}

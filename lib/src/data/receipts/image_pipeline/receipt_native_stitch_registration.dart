import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
class ReceiptNativeRegistrationAnchor {
  const ReceiptNativeRegistrationAnchor({
    required this.previousX,
    required this.previousY,
    required this.nextX,
    required this.nextY,
  });

  factory ReceiptNativeRegistrationAnchor.fromPlatform(Object? value) {
    final map = value is Map ? value : const <Object?, Object?>{};
    double coordinate(String key) {
      final number = map[key];
      final coordinate = number is num ? number.toDouble() : double.nan;
      return coordinate.isFinite ? coordinate.clamp(0, 1) : double.nan;
    }

    return ReceiptNativeRegistrationAnchor(
      previousX: coordinate('previousX'),
      previousY: coordinate('previousY'),
      nextX: coordinate('nextX'),
      nextY: coordinate('nextY'),
    );
  }

  final double previousX;
  final double previousY;
  final double nextX;
  final double nextY;

  bool get isValid =>
      previousX.isFinite &&
      previousY.isFinite &&
      nextX.isFinite &&
      nextY.isFinite &&
      previousX >= 0 &&
      previousX <= 1 &&
      previousY >= 0 &&
      previousY <= 1 &&
      nextX >= 0 &&
      nextX <= 1 &&
      nextY >= 0 &&
      nextY <= 1;
}

@immutable
class ReceiptNativeRegistrationProposal {
  const ReceiptNativeRegistrationProposal({
    required this.pairIndex,
    required this.scale,
    required this.rotationDegrees,
    required this.confidence,
    required this.inlierCount,
    required this.reprojectionError,
    required this.anchors,
  });

  factory ReceiptNativeRegistrationProposal.fromPlatform(Object? value) {
    final map = value is Map ? value : const <Object?, Object?>{};
    final rawAnchors = map['anchors'];
    return ReceiptNativeRegistrationProposal(
      pairIndex: (map['pairIndex'] as num?)?.toInt() ?? -1,
      scale: (map['scale'] as num?)?.toDouble() ?? 1,
      rotationDegrees: (map['rotationDegrees'] as num?)?.toDouble() ?? 0,
      confidence: ((map['confidence'] as num?)?.toDouble() ?? 0).clamp(0, 1),
      inlierCount: (map['inlierCount'] as num?)?.toInt() ?? 0,
      reprojectionError:
          (map['reprojectionError'] as num?)?.toDouble() ?? double.infinity,
      anchors: rawAnchors is List
          ? List.unmodifiable(
              rawAnchors.map(ReceiptNativeRegistrationAnchor.fromPlatform),
            )
          : const <ReceiptNativeRegistrationAnchor>[],
    );
  }

  final int pairIndex;
  final double scale;
  final double rotationDegrees;
  final double confidence;
  final int inlierCount;
  final double reprojectionError;
  final List<ReceiptNativeRegistrationAnchor> anchors;

  bool get isUsable =>
      pairIndex >= 0 &&
      scale >= .75 &&
      scale <= 1.25 &&
      rotationDegrees.abs() <= 8 &&
      confidence >= .45 &&
      inlierCount >= 6 &&
      reprojectionError.isFinite &&
      reprojectionError <= 5 &&
      anchors.length >= 6 &&
      anchors.every((anchor) => anchor.isValid);
}

class ReceiptNativeStitchRegistration {
  const ReceiptNativeStitchRegistration({MethodChannel? channel})
    : _channel =
          channel ??
          const MethodChannel('maintainiac/receipt_stitch_registration');

  final MethodChannel _channel;

  Future<List<ReceiptNativeRegistrationProposal>> propose({
    required List<String> paths,
    required int comparisonWidth,
  }) async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        paths.length < 2) {
      return const <ReceiptNativeRegistrationProposal>[];
    }
    final safeWidth = comparisonWidth.clamp(240, 480);
    final maxFeatures = safeWidth <= 320
        ? 420
        : safeWidth <= 360
        ? 700
        : 1000;
    final timeout = Duration(
      milliseconds: safeWidth <= 320
          ? 1200
          : safeWidth <= 360
          ? 1600
          : 2200,
    );
    // Native registration is optional guidance. Bound its work independently
    // of the number of reviewed sources; every remaining pair still goes
    // through the Dart geometry/text/continuity search and ordered fallback.
    final proposalPaths = paths
        .take(_maximumNativeRegistrationPaths)
        .toList(growable: false);
    final requestId = ++_receiptNativeRegistrationRequestSerial;
    try {
      final raw = await _channel
          .invokeMethod<List<Object?>>('proposeTransforms', {
            'requestId': requestId,
            'paths': proposalPaths,
            'comparisonWidth': safeWidth,
            'maxFeatures': maxFeatures,
          })
          .timeout(timeout);
      if (raw == null) return const <ReceiptNativeRegistrationProposal>[];
      return List.unmodifiable(
        raw
            .map(ReceiptNativeRegistrationProposal.fromPlatform)
            .where((proposal) => proposal.isUsable),
      );
    } on TimeoutException {
      await _cancelTimedOutProposal(requestId);
      return const <ReceiptNativeRegistrationProposal>[];
    } on Object {
      // Native registration is proposal-only. Any unavailable library,
      // timeout, or device-specific failure falls back to the existing
      // OCR/geometry/image path and must never block receipt review.
      return const <ReceiptNativeRegistrationProposal>[];
    }
  }

  Future<void> _cancelTimedOutProposal(int requestId) async {
    try {
      await _channel.invokeMethod<bool>('cancelProposals', {
        'requestId': requestId,
      });
    } on Object {
      // Cancellation is best effort because registration is proposal-only.
    }
  }

  static const int _maximumNativeRegistrationPaths = 13;
}

int _receiptNativeRegistrationRequestSerial = 0;

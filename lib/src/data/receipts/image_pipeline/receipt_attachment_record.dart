part of 'receipt_capture_models.dart';

class ReceiptAttachmentRecord {
  const ReceiptAttachmentRecord({
    required this.id,
    required this.path,
    required this.kind,
    required this.dataSaverLevel,
    required this.createdAt,
    this.displayName = '',
    this.originalFileName = '',
    this.mimeType = '',
    this.importedText = '',
    this.byteSize,
    this.fileHash = '',
    this.pageCount,
    this.pageCountStatus = ReceiptPdfPageCountStatus.unknown,
    this.validationStatus = ReceiptPdfValidationStatus.notChecked,
    List<String> riskFlags = const [],
    List<String> documentSignals = const [],
    this.sourceLabel = '',
    this.linkedModule = '',
    this.linkedRecordId = '',
    this.isOriginalImmutable = true,
    this.storageState = ReceiptAttachmentStorageState.permanent,
    this.promotedAt,
    this.cleanedUpAt,
    this.readState = ReceiptAttachmentReadState.notRead,
    this.photoQualityScore,
    this.photoQualityIssueLabel = '',
    List<String> photoQualityWarnings = const [],
    this.photoWidth,
    this.photoHeight,
    this.photoBrightness,
    this.photoContrast,
    this.photoFocusScore,
    this.photoCropScore,
    this.photoTextBandScore,
  }) : _riskFlags = riskFlags,
       _documentSignals = documentSignals,
       _photoQualityWarnings = photoQualityWarnings;

  factory ReceiptAttachmentRecord.fromMap(Map<dynamic, dynamic> map) {
    return ReceiptAttachmentRecord(
      id: (map['id'] as String? ?? '').trim(),
      path: (map['path'] as String? ?? '').trim(),
      kind: ReceiptAttachmentKind.fromName(map['kind'] as String?),
      dataSaverLevel: ReceiptDataSaverLevel.fromName(
        map['dataSaverLevel'] as String?,
      ),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      displayName: map['displayName'] as String? ?? '',
      originalFileName: map['originalFileName'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? '',
      importedText: map['importedText'] as String? ?? '',
      byteSize: _finiteInt(map['byteSize']),
      fileHash: map['fileHash'] as String? ?? '',
      pageCount: _finiteInt(map['pageCount']),
      pageCountStatus: ReceiptPdfPageCountStatus.fromName(
        map['pageCountStatus'] as String?,
      ),
      validationStatus: ReceiptPdfValidationStatus.fromName(
        map['validationStatus'] as String?,
      ),
      riskFlags:
          (map['riskFlags'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      documentSignals:
          (map['documentSignals'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      sourceLabel: map['sourceLabel'] as String? ?? '',
      linkedModule: map['linkedModule'] as String? ?? '',
      linkedRecordId: map['linkedRecordId'] as String? ?? '',
      isOriginalImmutable: map['isOriginalImmutable'] as bool? ?? true,
      storageState: ReceiptAttachmentStorageState.fromName(
        map['storageState'] as String?,
      ),
      promotedAt: DateTime.tryParse(map['promotedAt'] as String? ?? ''),
      cleanedUpAt: DateTime.tryParse(map['cleanedUpAt'] as String? ?? ''),
      readState: ReceiptAttachmentReadState.fromName(
        map['readState'] as String?,
      ),
      photoQualityScore: _finiteInt(map['photoQualityScore']),
      photoQualityIssueLabel: map['photoQualityIssueLabel'] as String? ?? '',
      photoQualityWarnings:
          (map['photoQualityWarnings'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      photoWidth: _finiteInt(map['photoWidth']),
      photoHeight: _finiteInt(map['photoHeight']),
      photoBrightness: _finiteDouble(map['photoBrightness']),
      photoContrast: _finiteDouble(map['photoContrast']),
      photoFocusScore: _finiteDouble(map['photoFocusScore']),
      photoCropScore: _finiteDouble(map['photoCropScore']),
      photoTextBandScore: _finiteDouble(map['photoTextBandScore']),
    );
  }

  final String id;
  final String path;
  final ReceiptAttachmentKind kind;
  final ReceiptDataSaverLevel dataSaverLevel;
  final DateTime createdAt;
  final String displayName;
  final String originalFileName;
  final String mimeType;
  final String importedText;
  final int? byteSize;
  final String fileHash;
  final int? pageCount;
  final ReceiptPdfPageCountStatus pageCountStatus;
  final ReceiptPdfValidationStatus validationStatus;
  final List<String> _riskFlags;
  final List<String> _documentSignals;
  final String sourceLabel;
  final String linkedModule;
  final String linkedRecordId;
  final bool isOriginalImmutable;
  final ReceiptAttachmentStorageState storageState;
  final DateTime? promotedAt;
  final DateTime? cleanedUpAt;
  final ReceiptAttachmentReadState readState;
  final int? photoQualityScore;
  final String photoQualityIssueLabel;
  final List<String> _photoQualityWarnings;
  final int? photoWidth;
  final int? photoHeight;
  final double? photoBrightness;
  final double? photoContrast;
  final double? photoFocusScore;
  final double? photoCropScore;
  final double? photoTextBandScore;

  bool get isPhoto => kind == ReceiptAttachmentKind.photo;
  bool get isPdf => kind == ReceiptAttachmentKind.pdf;
  bool get isImportedText =>
      kind == ReceiptAttachmentKind.emailText ||
      kind == ReceiptAttachmentKind.textMessageText;
  bool get isReadOnlyProof => isOriginalImmutable && !isImportedText;
  List<String> get riskFlags => List<String>.unmodifiable(_riskFlags);
  List<String> get documentSignals =>
      List<String>.unmodifiable(_documentSignals);
  List<String> get photoQualityWarnings =>
      List<String>.unmodifiable(_photoQualityWarnings);
  bool get canEditProofFileInApp => false;
  bool get hasPhotoQualityReview =>
      isPhoto &&
      (photoQualityScore != null ||
          photoQualityIssueLabel.trim().isNotEmpty ||
          photoQualityWarnings.isNotEmpty);
  bool get photoQualityNeedsReview =>
      hasPhotoQualityReview &&
      ((photoQualityScore ?? 100) < 80 || photoQualityWarnings.isNotEmpty);

  String get photoQualityLabel {
    final score = photoQualityScore;
    if (score == null) return '';
    final issue = photoQualityIssueLabel.trim();
    if (issue.isEmpty) return 'Photo quality $score%';
    return 'Photo quality $score%: $issue';
  }

  String get proofAccessLabel {
    if (isImportedText) return 'editable receipt text';
    if (isPdf) return 'read-only PDF proof';
    return 'read-only receipt photo';
  }

  String get label {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    return switch (kind) {
      ReceiptAttachmentKind.photo => 'Receipt photo',
      ReceiptAttachmentKind.pdf => 'Receipt PDF',
      ReceiptAttachmentKind.emailText => 'Receipt text',
      ReceiptAttachmentKind.textMessageText => 'Receipt text',
    };
  }

  ReceiptAttachmentRecord copyWith({
    String? id,
    String? path,
    ReceiptAttachmentKind? kind,
    ReceiptDataSaverLevel? dataSaverLevel,
    DateTime? createdAt,
    String? displayName,
    String? originalFileName,
    String? mimeType,
    String? importedText,
    int? byteSize,
    String? fileHash,
    int? pageCount,
    ReceiptPdfPageCountStatus? pageCountStatus,
    ReceiptPdfValidationStatus? validationStatus,
    List<String>? riskFlags,
    List<String>? documentSignals,
    String? sourceLabel,
    String? linkedModule,
    String? linkedRecordId,
    bool? isOriginalImmutable,
    ReceiptAttachmentStorageState? storageState,
    DateTime? promotedAt,
    DateTime? cleanedUpAt,
    ReceiptAttachmentReadState? readState,
    int? photoQualityScore,
    String? photoQualityIssueLabel,
    List<String>? photoQualityWarnings,
    int? photoWidth,
    int? photoHeight,
    double? photoBrightness,
    double? photoContrast,
    double? photoFocusScore,
    double? photoCropScore,
    double? photoTextBandScore,
  }) {
    return ReceiptAttachmentRecord(
      id: id ?? this.id,
      path: path ?? this.path,
      kind: kind ?? this.kind,
      dataSaverLevel: dataSaverLevel ?? this.dataSaverLevel,
      createdAt: createdAt ?? this.createdAt,
      displayName: displayName ?? this.displayName,
      originalFileName: originalFileName ?? this.originalFileName,
      mimeType: mimeType ?? this.mimeType,
      importedText: importedText ?? this.importedText,
      byteSize: byteSize ?? this.byteSize,
      fileHash: fileHash ?? this.fileHash,
      pageCount: pageCount ?? this.pageCount,
      pageCountStatus: pageCountStatus ?? this.pageCountStatus,
      validationStatus: validationStatus ?? this.validationStatus,
      riskFlags: riskFlags ?? this.riskFlags,
      documentSignals: documentSignals ?? this.documentSignals,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      linkedModule: linkedModule ?? this.linkedModule,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      isOriginalImmutable: isOriginalImmutable ?? this.isOriginalImmutable,
      storageState: storageState ?? this.storageState,
      promotedAt: promotedAt ?? this.promotedAt,
      cleanedUpAt: cleanedUpAt ?? this.cleanedUpAt,
      readState: readState ?? this.readState,
      photoQualityScore: photoQualityScore ?? this.photoQualityScore,
      photoQualityIssueLabel:
          photoQualityIssueLabel ?? this.photoQualityIssueLabel,
      photoQualityWarnings: photoQualityWarnings ?? this.photoQualityWarnings,
      photoWidth: photoWidth ?? this.photoWidth,
      photoHeight: photoHeight ?? this.photoHeight,
      photoBrightness: photoBrightness ?? this.photoBrightness,
      photoContrast: photoContrast ?? this.photoContrast,
      photoFocusScore: photoFocusScore ?? this.photoFocusScore,
      photoCropScore: photoCropScore ?? this.photoCropScore,
      photoTextBandScore: photoTextBandScore ?? this.photoTextBandScore,
    );
  }

  ReceiptAttachmentRecord withPhotoQuality(ReceiptPhotoQualityCheck? quality) {
    if (quality == null || !isPhoto) return this;
    final qualityReadState = quality.isLikelyReadable
        ? readState
        : readState == ReceiptAttachmentReadState.readIntoForm
        ? readState
        : ReceiptAttachmentReadState.unreadable;
    return copyWith(
      photoQualityScore: quality.reviewScore,
      photoQualityIssueLabel: quality.primaryIssueLabel,
      photoQualityWarnings: quality.qualityWarnings,
      photoWidth: quality.width,
      photoHeight: quality.height,
      photoBrightness: quality.brightness,
      photoContrast: quality.contrast,
      photoFocusScore: quality.focusScore,
      photoCropScore: quality.cropScore,
      photoTextBandScore: quality.textBandScore,
      readState: qualityReadState,
    );
  }
}

int? _finiteInt(Object? value) {
  if (value is! num || !value.isFinite) return null;
  return value.toInt();
}

double? _finiteDouble(Object? value) {
  if (value is! num || !value.isFinite) return null;
  return value.toDouble();
}

String _bottomGhostSliceHandoffInstruction({required String suffix}) {
  return 'Add the bottom receipt section and repeat 3-5 readable lines in the top reference strip so subtotal, total, and final lines can be matched $suffix';
}

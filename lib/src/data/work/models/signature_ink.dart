/// Immutable normalized handwriting; coordinates are fractions of the pad.
class SignatureInk {
  SignatureInk(Iterable<Iterable<(double, double)>> strokes)
    : strokes = List.unmodifiable(
        strokes.map((stroke) => List<(double, double)>.unmodifiable(stroke)),
      ) {
    for (final stroke in this.strokes) {
      if (stroke.isEmpty) {
        throw const FormatException('Empty signature stroke.');
      }
      for (final point in stroke) {
        if (!point.$1.isFinite ||
            !point.$2.isFinite ||
            point.$1 < 0 ||
            point.$1 > 1 ||
            point.$2 < 0 ||
            point.$2 > 1) {
          throw const FormatException('Invalid signature point.');
        }
      }
    }
  }
  final List<List<(double, double)>> strokes;
  bool get hasInk => strokes.any((stroke) => stroke.length > 1);
  Map<String, Object?> toJson() => {
    'version': 1,
    'strokes': [
      for (final stroke in strokes)
        [
          for (final point in stroke) [point.$1, point.$2],
        ],
    ],
  };
  factory SignatureInk.fromJson(Map<String, Object?> json) {
    if (json['version'] != 1 || json['strokes'] is! List) {
      throw const FormatException('Unsupported signature drawing.');
    }
    return SignatureInk(
      (json['strokes'] as List).map((stroke) {
        if (stroke is! List) {
          throw const FormatException('Invalid signature stroke.');
        }
        return stroke.map((point) {
          if (point is! List ||
              point.length != 2 ||
              point[0] is! num ||
              point[1] is! num) {
            throw const FormatException('Invalid signature point.');
          }
          return ((point[0] as num).toDouble(), (point[1] as num).toDouble());
        });
      }),
    );
  }
}

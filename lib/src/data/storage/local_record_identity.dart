import 'dart:math';

/// Cryptographic identity independent of clock precision and device time.
String newLocalRecordIdentity(String prefix) {
  final random = Random.secure();
  final token = List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '$prefix-$token';
}

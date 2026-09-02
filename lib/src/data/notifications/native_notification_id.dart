int nativeNotificationIdFor(String notificationId) {
  var hash = 0x811c9dc5;
  for (final codeUnit in notificationId.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}

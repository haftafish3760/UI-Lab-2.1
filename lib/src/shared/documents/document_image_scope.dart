import 'dart:typed_data';
import 'package:flutter/widgets.dart';

typedef DocumentImageLoader = Future<Uint8List?> Function(String reference);

/// The app supplies an already-authorizing adapter. Rendering has no database.
class DocumentImageScope extends InheritedWidget {
  const DocumentImageScope({
    required this.load,
    required super.child,
    super.key,
  });
  final DocumentImageLoader load;
  static DocumentImageLoader? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DocumentImageScope>()?.load;
  @override
  bool updateShouldNotify(DocumentImageScope oldWidget) =>
      load != oldWidget.load;
}

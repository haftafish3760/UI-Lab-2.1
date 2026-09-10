import 'package:flutter/widgets.dart';

/// Supplies installation-specific file resolution without exposing databases,
/// restore manifests or historical-record rewriting to evidence widgets.
/// Callers still authorize the document before supplying its retained reference.
class LocalDocumentPathScope extends InheritedWidget {
  const LocalDocumentPathScope({
    required this.resolve,
    required super.child,
    super.key,
  });
  final String Function(String retainedReference) resolve;

  static String resolvePath(BuildContext context, String reference) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LocalDocumentPathScope>();
    // Existing installations use their current local paths. A supplied resolver
    // is authoritative: failure must never fall back to an old device path.
    return scope == null ? reference : scope.resolve(reference);
  }

  @override
  bool updateShouldNotify(LocalDocumentPathScope oldWidget) =>
      !identical(resolve, oldWidget.resolve);
}

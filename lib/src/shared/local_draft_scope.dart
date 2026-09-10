import 'package:flutter/widgets.dart';

import '../data/storage/draft_repository.dart';

/// App-owned repository contract for recoverable input across feature routes.
///
/// This supplies storage, not authorization. Editors must obtain organization
/// and actor identity from their authorized domain session before accessing it.
/// The application owns the database lifetime; routes must not close it.
class LocalDraftScope extends InheritedWidget {
  const LocalDraftScope({required this.store, required super.child, super.key});

  final DraftRepository store;

  static DraftRepository? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocalDraftScope>()?.store;

  @override
  bool updateShouldNotify(LocalDraftScope oldWidget) =>
      !identical(store, oldWidget.store);
}

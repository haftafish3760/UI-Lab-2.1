import 'package:flutter/widgets.dart';

/// Presentation ownership only. No database, route or draft schema belongs here.
class ApplicationHostController {
  ApplicationHostAttachment? _attachment;

  Widget? get currentApplication => _attachment?.currentApplication();

  void Function() attach(ApplicationHostAttachment attachment) {
    if (_attachment != null) {
      throw StateError('Application host already attached.');
    }
    _attachment = attachment;
    return () {
      if (identical(_attachment, attachment)) _attachment = null;
    };
  }

  ApplicationHostAttachment get _host =>
      _attachment ?? (throw StateError('Application host is not attached.'));

  void blockEntryPoints(bool blocked) => _host.blockEntryPoints(blocked);
  Future<void> settleView() => _host.settleView();
  Future<void> presentApplication(Widget? application) =>
      _host.presentApplication(application);
}

class ApplicationHostAttachment {
  const ApplicationHostAttachment({
    required this.currentApplication,
    required this.blockEntryPoints,
    required this.settleView,
    required this.presentApplication,
  });
  final Widget? Function() currentApplication;
  final void Function(bool) blockEntryPoints;
  final Future<void> Function() settleView;
  final Future<void> Function(Widget?) presentApplication;
}

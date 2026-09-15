import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

enum FirebaseConnectionState { notStarted, unavailable, ready, failed }

/// Initializes the SDK only. This does not authorize users, upload local records,
/// enable analytics, or substitute for company membership and server rules.
class FirebaseConnection {
  FirebaseConnection({Future<void> Function(FirebaseOptions)? initialize})
    : _initialize = initialize ?? _initializeSdk;

  final Future<void> Function(FirebaseOptions) _initialize;
  final state = ValueNotifier(FirebaseConnectionState.notStarted);
  Object? failure;
  Future<void>? _pending;

  Future<void> open({
    TargetPlatform? platform,
    bool? web,
    bool storageQa = const bool.fromEnvironment('STORAGE_QA'),
  }) {
    if (state.value == FirebaseConnectionState.failed) {
      _pending = null;
      failure = null;
      state.value = FirebaseConnectionState.notStarted;
    }
    return _pending ??= _open(
      platform ?? defaultTargetPlatform,
      web ?? kIsWeb,
      storageQa,
    );
  }

  Future<void> _open(TargetPlatform platform, bool web, bool storageQa) async {
    if (web || storageQa) {
      state.value = FirebaseConnectionState.unavailable;
      return;
    }
    final options = switch (platform) {
      TargetPlatform.android => AppFirebaseOptions.android,
      TargetPlatform.iOS => AppFirebaseOptions.ios,
      _ => null,
    };
    if (options == null) {
      state.value = FirebaseConnectionState.unavailable;
      return;
    }
    try {
      await _initialize(options);
      state.value = FirebaseConnectionState.ready;
    } catch (error) {
      // Preserve the diagnostic for the account connection flow without making
      // local business records inaccessible or exposing credentials in logs.
      failure = error;
      state.value = FirebaseConnectionState.failed;
    }
  }

  static Future<void> _initializeSdk(FirebaseOptions options) async {
    await Firebase.initializeApp(options: options);
  }
}

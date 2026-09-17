import 'package:flutter/material.dart';

/// Keeps Flutter's platform transition and iOS edge-back gesture. Reduced
/// motion removes the transition rather than substituting a custom animation.
class MaterialsCatalogRoute<T> extends MaterialPageRoute<T> {
  MaterialsCatalogRoute({required BuildContext context, required super.builder})
    : _reducedMotion = MediaQuery.disableAnimationsOf(context);
  final bool _reducedMotion;

  @override
  Duration get transitionDuration =>
      _reducedMotion ? Duration.zero : super.transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      _reducedMotion ? Duration.zero : super.reverseTransitionDuration;
}

import 'package:flutter/material.dart';

/// App-wide state colors. These tokens keep the same meaning in every module;
/// module identity colors remain a separate concern.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.current,
    required this.currentSurface,
    required this.planned,
    required this.plannedSurface,
    required this.success,
    required this.successSurface,
    required this.attention,
    required this.attentionSurface,
    required this.danger,
    required this.dangerSurface,
    required this.draft,
    required this.draftSurface,
  });

  final Color current;
  final Color currentSurface;
  final Color planned;
  final Color plannedSurface;
  final Color success;
  final Color successSurface;
  final Color attention;
  final Color attentionSurface;
  final Color danger;
  final Color dangerSurface;
  final Color draft;
  final Color draftSurface;

  static const light = AppSemanticColors(
    current: Color(0xFF1E607C),
    currentSurface: Color(0xFFCFE5EF),
    planned: Color(0xFF5D4B83),
    plannedSurface: Color(0xFFE1D9EF),
    success: Color(0xFF126A4B),
    successSurface: Color(0xFFD3E9DE),
    attention: Color(0xFF944509),
    attentionSurface: Color(0xFFF3D8C2),
    danger: Color(0xFFA62F38),
    dangerSurface: Color(0xFFF1D0D3),
    draft: Color(0xFF526771),
    draftSurface: Color(0xFFD6E1E6),
  );

  static const dark = AppSemanticColors(
    current: Color(0xFF65B8FF),
    currentSurface: Color(0xFF173C5D),
    planned: Color(0xFF4FE8FF),
    plannedSurface: Color(0xFF234850),
    success: Color(0xFF20F060),
    successSurface: Color(0xFF1D4A2A),
    attention: Color(0xFFFFD166),
    attentionSurface: Color(0xFF51451F),
    danger: Color(0xFFFF766F),
    dangerSurface: Color(0xFF562622),
    draft: Color(0xFFAAB4B9),
    draftSurface: Color(0xFF3A4240),
  );

  @override
  AppSemanticColors copyWith({
    Color? current,
    Color? currentSurface,
    Color? planned,
    Color? plannedSurface,
    Color? success,
    Color? successSurface,
    Color? attention,
    Color? attentionSurface,
    Color? danger,
    Color? dangerSurface,
    Color? draft,
    Color? draftSurface,
  }) => AppSemanticColors(
    current: current ?? this.current,
    currentSurface: currentSurface ?? this.currentSurface,
    planned: planned ?? this.planned,
    plannedSurface: plannedSurface ?? this.plannedSurface,
    success: success ?? this.success,
    successSurface: successSurface ?? this.successSurface,
    attention: attention ?? this.attention,
    attentionSurface: attentionSurface ?? this.attentionSurface,
    danger: danger ?? this.danger,
    dangerSurface: dangerSurface ?? this.dangerSurface,
    draft: draft ?? this.draft,
    draftSurface: draftSurface ?? this.draftSurface,
  );

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      current: Color.lerp(current, other.current, t)!,
      currentSurface: Color.lerp(currentSurface, other.currentSurface, t)!,
      planned: Color.lerp(planned, other.planned, t)!,
      plannedSurface: Color.lerp(plannedSurface, other.plannedSurface, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      attention: Color.lerp(attention, other.attention, t)!,
      attentionSurface: Color.lerp(
        attentionSurface,
        other.attentionSurface,
        t,
      )!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSurface: Color.lerp(dangerSurface, other.dangerSurface, t)!,
      draft: Color.lerp(draft, other.draft, t)!,
      draftSurface: Color.lerp(draftSurface, other.draftSurface, t)!,
    );
  }
}

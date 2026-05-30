import 'package:flutter/material.dart';

/// Represents a single step in the in-app guided tour.
class OnboardingStep {
  final String id;
  final GlobalKey targetKey;
  final String titleKey;
  final String descriptionKey;
  final int stepIndex;
  final int totalSteps;

  /// If non-null, the step is only shown when the condition returns `true`.
  final bool Function()? visibilityCondition;

  const OnboardingStep({
    required this.id,
    required this.targetKey,
    required this.titleKey,
    required this.descriptionKey,
    required this.stepIndex,
    required this.totalSteps,
    this.visibilityCondition,
  });

  bool get isVisible {
    if (visibilityCondition != null) return visibilityCondition!();
    return true;
  }

  /// Returns `true` if the target widget is currently mounted in the tree.
  bool get isTargetMounted => targetKey.currentContext != null;
}

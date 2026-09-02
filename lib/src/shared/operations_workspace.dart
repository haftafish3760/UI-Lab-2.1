import 'package:flutter/material.dart';

import '../layout/app_layout_engine.dart';

/// Enforces one centered width contract for every part of an operations page.
///
/// Headers, record lanes, summaries, and calendars all live inside the same
/// workspace. A caller cannot bypass the shared maximum width for a trailing
/// section.
class OperationsWorkspaceFrame extends StatelessWidget {
  const OperationsWorkspaceFrame({
    super.key,
    required this.layout,
    required this.primaryContent,
    this.followingContent,
  });

  final OperationsWorkspaceLayout layout;
  final Widget primaryContent;
  final Widget? followingContent;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      key: const ValueKey('operations-workspace-frame'),
      width: layout.workspaceWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primaryContent,
          if (followingContent case final content?) ...[
            SizedBox(height: layout.gap),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(
                key: const ValueKey('operations-following-lane'),
                width: layout.laneWidth,
                child: content,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// The only lane assembler used by top-level operations modules.
class OperationsLaneGrid extends StatelessWidget {
  const OperationsLaneGrid({
    super.key,
    required this.layout,
    required this.children,
  });

  final OperationsWorkspaceLayout layout;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    if (layout.columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1) SizedBox(height: layout.gap),
          ],
        ],
      );
    }
    return Wrap(
      key: ValueKey('operations-${layout.columns}-lane-grid'),
      spacing: layout.gap,
      runSpacing: layout.gap,
      children: [
        for (final child in children)
          SizedBox(width: layout.laneWidth, child: child),
      ],
    );
  }
}

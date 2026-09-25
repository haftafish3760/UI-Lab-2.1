import 'package:flutter/material.dart';
import '../layout/app_layout_engine.dart';

/// Independent columns prevent a tall widget from opening gaps in other lanes.
/// Geometry always comes from the shared local-width layout engine.
class ScreenWidgetBoard extends StatelessWidget {
  const ScreenWidgetBoard({
    required this.layout,
    required this.children,
    super.key,
  });
  final OperationsWorkspaceLayout layout;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    Widget lane(int column) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (
          var index = column;
          index < children.length;
          index += layout.columns
        ) ...[
          if (index != column) SizedBox(height: layout.gap),
          children[index],
        ],
      ],
    );
    if (layout.columns == 1) return lane(0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var column = 0; column < layout.columns; column++) ...[
          if (column > 0) SizedBox(width: layout.gap),
          Expanded(child: lane(column)),
        ],
      ],
    );
  }
}

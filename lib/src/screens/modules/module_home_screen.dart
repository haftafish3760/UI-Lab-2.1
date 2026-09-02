import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/operations_workspace.dart';
import '../../shell/app_navigation.dart';

class ModuleHomeScreen extends StatelessWidget {
  const ModuleHomeScreen.expenses({super.key})
    : module = AppModule.expenses,
      title = 'Expenses',
      description =
          'Capture costs, review receipts, and keep job spending traceable.',
      primaryLabel = 'Record expense',
      primaryIcon = Icons.add_card_outlined,
      queueTitle = 'Receipt review',
      queueDetail = '3 items need confirmation';

  const ModuleHomeScreen.inventory({super.key})
    : module = AppModule.inventory,
      title = 'Materials',
      description =
          'Track truck stock and reuse verified material costs in estimates.',
      primaryLabel = 'Add material',
      primaryIcon = Icons.playlist_add_rounded,
      queueTitle = 'Truck stock',
      queueDetail = '4 items are running low';

  const ModuleHomeScreen.maintenance({super.key})
    : module = AppModule.maintenance,
      title = 'Maintenance',
      description =
          'Keep vehicles and equipment dependable with service history and due dates.',
      primaryLabel = 'Add service record',
      primaryIcon = Icons.build_circle_outlined,
      queueTitle = 'Due soon',
      queueDetail = '2 services in the next 30 days';

  final AppModule module;
  final String title;
  final String description;
  final String primaryLabel;
  final IconData primaryIcon;
  final String queueTitle;
  final String queueDetail;

  @override
  Widget build(BuildContext context) {
    final destination = appDestinations[module.index];
    final tone = destination.color(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      key: ValueKey('${module.name}-module-screen'),
      appBar: AppBar(title: Text(title)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          final layout = AppLayoutEngine.operationsFor(
            constraints.maxWidth - insets.horizontal,
            textScaler: MediaQuery.textScalerOf(context),
          );
          return ListView(
            padding: EdgeInsets.fromLTRB(insets.left, 16, insets.right, 32),
            children: [
              OperationsWorkspaceFrame(
                layout: layout,
                primaryContent: Column(
                  key: ValueKey(
                    '${module.name}-${layout.columns}-column-layout',
                  ),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(
                        width: layout.laneWidth,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: tone.withValues(alpha: .14),
                                border: Border.all(color: tone),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                destination.selectedIcon,
                                color: tone,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OperationsLaneGrid(
                      layout: layout,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _showPrototypeNotice(
                            context,
                            '$primaryLabel workflow',
                          ),
                          icon: Icon(primaryIcon),
                          label: Text(primaryLabel),
                          style: FilledButton.styleFrom(
                            alignment: AlignmentDirectional.centerStart,
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                        Material(
                          color: colors.surface,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: colors.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            minTileHeight: 64,
                            leading: Icon(Icons.inbox_outlined, color: tone),
                            title: Text(
                              queueTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(queueDetail),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showPrototypeNotice(
                              context,
                              '$queueTitle queue',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPrototypeNotice(BuildContext context, String workflow) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$workflow is the next module workflow to blueprint.'),
        ),
      );
  }
}

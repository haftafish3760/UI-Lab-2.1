import 'package:flutter/material.dart';

import '../../data/operational_attention.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/operational_attention_panel.dart';
import '../work/work_detail_header.dart';

class DashboardAttentionScreen extends StatelessWidget {
  const DashboardAttentionScreen({
    required this.query,
    required this.onOpen,
    super.key,
  });

  final OperationalAttentionQuery query;
  final ValueChanged<OperationalAttentionItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final items = store.attentionCenter.itemsFor(query);
    return Scaffold(
      key: const ValueKey('dashboard-attention-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: 'Needs attention',
                          selectedDay: DateUtils.dateOnly(DateTime.now()),
                          onBack: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Needs attention',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Only records that need a permitted decision or follow-up appear here.',
                        ),
                        const SizedBox(height: 12),
                        OperationalAttentionList(
                          items: items,
                          rowKeyFor: (item) => ValueKey(
                            'dashboard-attention-list-${item.sourceId}',
                          ),
                          onOpen: onOpen,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../l10n/app_localizations_extension.dart';
import '../data/operational_attention.dart';
import '../layout/app_layout_engine.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_theme.dart';
import 'section_card.dart';

class OperationalAttentionPanel extends StatelessWidget {
  const OperationalAttentionPanel({
    required this.items,
    required this.onOpen,
    required this.onOpenAll,
    required this.onDismiss,
    this.rowKeyFor,
    super.key,
  });

  final List<OperationalAttentionItem> items;
  final ValueChanged<OperationalAttentionItem> onOpen;
  final VoidCallback onOpenAll;
  final VoidCallback onDismiss;
  final Key Function(OperationalAttentionItem item)? rowKeyFor;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final semantic = _attentionColors(context);
    final colors = Theme.of(context).colorScheme;
    final visible = items.take(3).toList();
    return SectionCard(
      padding: EdgeInsets.zero,
      backgroundColor: Color.alphaBlend(
        semantic.danger.withValues(alpha: .055),
        colors.surface,
      ),
      borderColor: semantic.danger.withValues(alpha: .82),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AttentionHeading(
            count: items.length,
            onOpenAll: onOpenAll,
            onDismiss: onDismiss,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              children: [
                for (var index = 0; index < visible.length; index++) ...[
                  OperationalAttentionRow(
                    key:
                        rowKeyFor?.call(visible[index]) ??
                        ValueKey('attention-row-${visible[index].id}'),
                    item: visible[index],
                    onOpen: () => onOpen(visible[index]),
                  ),
                  if (index != visible.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OperationalAttentionList extends StatelessWidget {
  const OperationalAttentionList({
    required this.items,
    required this.onOpen,
    this.rowKeyFor,
    super.key,
  });

  final List<OperationalAttentionItem> items;
  final ValueChanged<OperationalAttentionItem> onOpen;
  final Key Function(OperationalAttentionItem item)? rowKeyFor;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SectionCard(child: Text(context.l10n.attentionNothing));
    }
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          OperationalAttentionRow(
            key:
                rowKeyFor?.call(items[index]) ??
                ValueKey('attention-list-${items[index].id}'),
            item: items[index],
            onOpen: () => onOpen(items[index]),
          ),
          if (index != items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class OperationalAttentionRow extends StatelessWidget {
  const OperationalAttentionRow({
    required this.item,
    required this.onOpen,
    super.key,
  });

  final OperationalAttentionItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final semantic = _attentionColors(context);
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final type = AppLayoutEngine.typographyFor(constraints.maxWidth);
        return SectionCard(
          padding: EdgeInsets.zero,
          backgroundColor: colors.surface,
          borderColor: item.isUrgent
              ? semantic.danger.withValues(alpha: .64)
              : colors.outline,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: type.operationRowHeight),
            child: InkWell(
              onTap: onOpen,
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(AppRadii.surface),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color:
                            (item.isUrgent ? semantic.danger : colors.primary)
                                .withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(AppRadii.control),
                      ),
                      child: Icon(
                        operationalAttentionIcon(item.resourceKind),
                        size: 20,
                        color: item.isUrgent ? semantic.danger : colors.primary,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: type.rowTitle,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.reason,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AttentionHeading extends StatelessWidget {
  const _AttentionHeading({
    required this.count,
    required this.onOpenAll,
    required this.onDismiss,
  });

  final int count;
  final VoidCallback onOpenAll;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final semantic = _attentionColors(context);
      final localizations = context.l10n;
      final type = AppLayoutEngine.typographyFor(constraints.maxWidth);
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final action = TextButton.icon(
        onPressed: onOpenAll,
        style: TextButton.styleFrom(
          foregroundColor: semantic.danger,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.chevron_right_rounded, size: 20),
        label: Text(localizations.attentionShowAll(count)),
      );
      final dismiss = IconButton(
        onPressed: onDismiss,
        tooltip: localizations.attentionDismiss,
        color: semantic.danger,
        icon: const Icon(Icons.close_rounded, size: 20),
      );
      final title = Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: semantic.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              localizations.attentionTitle,
              style: TextStyle(
                fontSize: type.sectionTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
      return Container(
        key: const ValueKey('operational-attention-heading'),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 4, 6),
        decoration: BoxDecoration(
          color: semantic.dangerSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.surface - 1),
          ),
        ),
        child: textScale >= 1.5
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [action, dismiss],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: title),
                  action,
                  dismiss,
                ],
              ),
      );
    },
  );
}

AppSemanticColors _attentionColors(BuildContext context) =>
    Theme.of(context).extension<AppSemanticColors>() ??
    (Theme.of(context).brightness == Brightness.dark
        ? AppSemanticColors.dark
        : AppSemanticColors.light);

IconData operationalAttentionIcon(
  OperationalAttentionResourceKind resourceKind,
) => switch (resourceKind) {
  OperationalAttentionResourceKind.quote => Icons.request_quote_outlined,
  OperationalAttentionResourceKind.estimate => Icons.request_quote_outlined,
  OperationalAttentionResourceKind.job => Icons.home_repair_service_outlined,
  OperationalAttentionResourceKind.invoice => Icons.receipt_long_outlined,
  OperationalAttentionResourceKind.expense => Icons.payments_outlined,
  OperationalAttentionResourceKind.inventoryStock => Icons.inventory_2_outlined,
};

part of 'work_screen.dart';

class _WorkSectionHeading extends StatelessWidget {
  const _WorkSectionHeading({
    required this.icon,
    required this.title,
    required this.count,
    required this.accent,
    required this.background,
    this.onOpenAll,
    this.onCreate,
    this.createLabel,
  });

  final IconData icon;
  final String title;
  final int count;
  final Color accent;
  final Color background;
  final VoidCallback? onOpenAll;
  final VoidCallback? onCreate;
  final String? createLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final type = AppLayoutEngine.typographyFor(constraints.maxWidth);
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final stackAction =
          (onCreate != null && constraints.maxWidth < 500) ||
          (textScale >= 1.5 && constraints.maxWidth < 430);
      final titleWidget = Row(
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: type.sectionTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
      final openAction = onOpenAll == null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$count',
                style: TextStyle(color: accent, fontWeight: FontWeight.w700),
              ),
            )
          : TextButton(
              key: ValueKey('open-${title.toLowerCase().replaceAll(' ', '-')}'),
              onPressed: onOpenAll,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: stackAction
                  ? Text(count == 0 ? 'Open' : 'Show all $count')
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(count == 0 ? 'Open' : 'Show all $count'),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, size: 20),
                      ],
                    ),
            );
      final createAction = onCreate == null
          ? null
          : TextButton.icon(
              key: ValueKey(
                'create-${title.toLowerCase().replaceAll(' ', '-')}',
              ),
              onPressed: onCreate,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(createLabel ?? 'New'),
            );
      final actions = Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        children: [?createAction, openAction],
      );
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.surface - 1),
          ),
        ),
        child: stackAction
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleWidget,
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              )
            : Row(
                children: [
                  Expanded(child: titleWidget),
                  actions,
                ],
              ),
      );
    },
  );
}

class _DraftHeading extends StatelessWidget {
  const _DraftHeading({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Container(
      key: const ValueKey('work-estimate-drafts-heading'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: semantic.draftSurface,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: semantic.draft.withValues(alpha: .7)),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note_rounded, size: 19, color: semantic.draft),
          const SizedBox(width: 7),
          const Expanded(
            child: Text(
              'Unfinished drafts',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

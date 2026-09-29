part of 'work_screen.dart';

/// The wider record lane separates identity from operational context, while
/// phone rows retain the same reading order in a vertical arrangement.
class _WorkRowDetails extends StatelessWidget {
  const _WorkRowDetails({
    required this.record,
    required this.plan,
    required this.time,
  });
  final WorkRecord record;
  final bool plan;
  final String time;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final identity = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.client,
            style: const TextStyle(
              color: OperationalCardTone.darkInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            record.title,
            style: const TextStyle(color: OperationalCardTone.darkInk),
          ),
        ],
      );
      final metadata = Text(
        '${record.number} · ${record.status.label} · $time${plan ? ' · ${record.assignee ?? 'Unassigned'}' : ''}',
        style: const TextStyle(
          color: OperationalCardTone.darkInk,
          fontSize: 13,
        ),
      );
      if (AppLayoutEngine.stackFormFieldsFor(
        constraints.maxWidth,
        textScaler: MediaQuery.textScalerOf(context),
      )) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [identity, metadata],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: identity),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: metadata),
        ],
      );
    },
  );
}

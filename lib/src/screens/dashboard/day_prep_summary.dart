import 'package:flutter/material.dart';

import '../../shared/section_card.dart';
import '../../theme/app_theme.dart';

class DayPrepSummary extends StatelessWidget {
  const DayPrepSummary({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: EdgeInsets.zero,
      borderColor: const Color(0xFFAD8C45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF755617),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Day Prep',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _ReadinessBadge(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '3 scheduled jobs · 2 items need attention',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                const _PrepStatusRow(
                  icon: Icons.local_shipping_outlined,
                  title: 'Truck ready',
                  detail: '8 of 8 confirmed',
                  color: AppColors.green,
                  statusIcon: Icons.check_circle_rounded,
                ),
                const Divider(height: 21, color: AppColors.border),
                const _PrepStatusRow(
                  icon: Icons.inventory_2_outlined,
                  title: 'Job materials',
                  detail: '2 quantities unresolved',
                  color: Color(0xFFA55B00),
                  statusIcon: Icons.warning_amber_rounded,
                ),
                if (!compact) ...[
                  const Divider(height: 21, color: AppColors.border),
                  const _PrepStatusRow(
                    icon: Icons.verified_user_outlined,
                    title: 'Access & documents',
                    detail: 'All clear',
                    color: AppColors.green,
                    statusIcon: Icons.check_circle_rounded,
                  ),
                  const SizedBox(height: 14),
                  const _MissingItem(
                    title: '3/4 in. copper fittings',
                    detail: '12 required · 8 confirmed · 4 needed',
                  ),
                  const SizedBox(height: 8),
                  const _MissingItem(
                    title: 'MAP gas',
                    detail: 'Confirm enough for today',
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _openPrep(context),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Open day prep'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF755617),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPrep(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const _DayPrepScreen()),
    );
  }
}

class _ReadinessBadge extends StatelessWidget {
  const _ReadinessBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE2A6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '14 of 16 ready',
        style: TextStyle(
          color: Color(0xFF4A3509),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PrepStatusRow extends StatelessWidget {
  const _PrepStatusRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
    required this.statusIcon,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;
  final IconData statusIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(detail, style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
        Icon(statusIcon, color: color),
      ],
    );
  }
}

class _MissingItem extends StatelessWidget {
  const _MissingItem({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3DB),
        border: Border.all(color: const Color(0xFFD6A54D)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(detail, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _DayPrepScreen extends StatelessWidget {
  const _DayPrepScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Day Prep · August 25')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Truck Ready',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text('Company-configured items normally carried on this vehicle.'),
          SizedBox(height: 12),
          _ChecklistTile('Safety equipment', 'Confirmed', true),
          _ChecklistTile('Common tools', 'Confirmed', true),
          _ChecklistTile('MAP gas', 'Confirm enough for today', false),
          SizedBox(height: 24),
          Text(
            "Today's Job Prep",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text('Generated from the materials and equipment on today’s jobs.'),
          SizedBox(height: 12),
          _ChecklistTile('3/4 in. copper fittings', '4 still needed', false),
          _ChecklistTile('Kitchen faucet', 'Loaded', true),
          _ChecklistTile('Inspection equipment', 'Loaded', true),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile(this.title, this.status, this.ready);

  final String title;
  final String status;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          ready ? Icons.check_circle : Icons.warning_amber_rounded,
          color: ready ? AppColors.green : const Color(0xFFA55B00),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(status),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

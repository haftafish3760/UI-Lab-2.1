import 'package:flutter/material.dart';

import '../../shared/section_card.dart';
import '../../theme/app_theme.dart';

class TodayEntries extends StatelessWidget {
  const TodayEntries({super.key, this.title = "Today's Entries"});

  final String title;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 17 : 19,
                      fontWeight: compact ? FontWeight.w700 : FontWeight.w900,
                    ),
                  ),
                ),
                const Text(
                  '5 records',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const _EntryRow(
            Icons.login,
            '7:42 AM',
            'Workday started',
            'Odometer · 34,102 mi',
            AppColors.green,
          ),
          const Divider(height: 1, thickness: 1.2, color: AppColors.border),
          const _EntryRow(
            Icons.route_outlined,
            '8:00 AM',
            'Trip to Stone family',
            '12.4 business miles',
            AppColors.blue,
          ),
          const Divider(height: 1, thickness: 1.2, color: AppColors.border),
          const _EntryRow(
            Icons.receipt_long_outlined,
            '10:44 AM',
            'Central Supply receipt',
            r'$48.72 · Job materials',
            Color(0xFFA55B00),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: _noop,
              icon: const Icon(Icons.add),
              label: const Text('Add missed entry'),
            ),
          ),
        ],
      ),
    );
  }

  static void _noop() {}
}

class _EntryRow extends StatelessWidget {
  const _EntryRow(this.icon, this.time, this.title, this.detail, this.color);

  final IconData icon;
  final String time;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        mouseCursor: SystemMouseCursors.click,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xFFBCD4CD);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return const Color(0xFFD2E2DD);
          }
          return null;
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                foregroundColor: color,
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 76,
                child: Text(
                  time,
                  style: TextStyle(
                    fontWeight: compact ? FontWeight.w600 : FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: compact ? FontWeight.w700 : FontWeight.w800,
                      ),
                    ),
                    Text(
                      detail,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

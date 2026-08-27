import 'package:flutter/material.dart';

class PlanItem {
  const PlanItem(this.time, this.title, this.detail, this.icon, this.color);

  final String time;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
}

const demoPlan = <PlanItem>[
  PlanItem(
    '8:00 AM',
    'Replace kitchen faucet',
    'Stone family · 212 Oak Street',
    Icons.plumbing,
    Color(0xFF2D6680),
  ),
  PlanItem(
    '10:30 AM',
    'Pick up copper and fittings',
    'Central Supply · order 1842',
    Icons.inventory_2_outlined,
    Color(0xFFA55B00),
  ),
  PlanItem(
    '1:15 PM',
    'Water-heater inspection',
    'Miller property · 48 River Road',
    Icons.home_repair_service_outlined,
    Color(0xFF087A4A),
  ),
];

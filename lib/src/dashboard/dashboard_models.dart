import 'package:flutter/material.dart';

enum DashboardRecordState { planned, active, completed, review }

class DashboardRecord {
  const DashboardRecord({
    required this.time,
    required this.title,
    required this.detail,
    required this.icon,
    required this.state,
  });

  final String time;
  final String title;
  final String detail;
  final IconData icon;
  final DashboardRecordState state;
}

const attentionRecords = [
  DashboardRecord(
    time: '9:59 AM',
    title: 'Central Supply receipt',
    detail: 'Receipt needs your correction',
    icon: Icons.receipt_long_outlined,
    state: DashboardRecordState.review,
  ),
  DashboardRecord(
    time: '11:30 AM',
    title: 'Miller estimate',
    detail: 'Customer requested a change',
    icon: Icons.request_quote_outlined,
    state: DashboardRecordState.review,
  ),
];

const planRecords = [
  DashboardRecord(
    time: '8:00 AM',
    title: 'Replace kitchen faucet',
    detail: 'Maya Thompson',
    icon: Icons.plumbing_outlined,
    state: DashboardRecordState.planned,
  ),
  DashboardRecord(
    time: '10:30 AM',
    title: 'Pick up copper fittings',
    detail: 'Central Supply',
    icon: Icons.inventory_2_outlined,
    state: DashboardRecordState.planned,
  ),
  DashboardRecord(
    time: '1:15 PM',
    title: 'Water-heater inspection',
    detail: 'Jordan Miller',
    icon: Icons.home_repair_service_outlined,
    state: DashboardRecordState.planned,
  ),
  DashboardRecord(
    time: '3:30 PM',
    title: 'Office lighting diagnosis',
    detail: 'Elena Garcia',
    icon: Icons.electrical_services_outlined,
    state: DashboardRecordState.planned,
  ),
];

const entryRecords = [
  DashboardRecord(
    time: '7:42 AM',
    title: 'Workday started',
    detail: 'Transit 12',
    icon: Icons.badge_outlined,
    state: DashboardRecordState.completed,
  ),
  DashboardRecord(
    time: '8:00 AM',
    title: 'Trip to Thompson home',
    detail: '12.4 business miles',
    icon: Icons.route_outlined,
    state: DashboardRecordState.completed,
  ),
  DashboardRecord(
    time: '9:59 AM',
    title: 'Central Supply',
    detail: r'$48.72 · Materials',
    icon: Icons.receipt_long_outlined,
    state: DashboardRecordState.review,
  ),
  DashboardRecord(
    time: '12:10 PM',
    title: 'Faucet job completed',
    detail: 'Maya Thompson',
    icon: Icons.task_alt_outlined,
    state: DashboardRecordState.completed,
  ),
  DashboardRecord(
    time: '12:18 PM',
    title: 'Invoice sent',
    detail: r'INV-2088 · $486.00',
    icon: Icons.description_outlined,
    state: DashboardRecordState.completed,
  ),
];

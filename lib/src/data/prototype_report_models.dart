import 'package:flutter/foundation.dart';

import 'prototype_financial_models.dart';

enum PrototypeReportSourceKind { expense, workRecord, invoiceEntry, payment }

@immutable
class PrototypeReportSource {
  const PrototypeReportSource({
    required this.kind,
    required this.id,
    required this.title,
    required this.detail,
    this.amountCents,
    this.linkedWorkNumber,
  });

  final PrototypeReportSourceKind kind;
  final String id;
  final String title;
  final String detail;
  final int? amountCents;
  final String? linkedWorkNumber;
}

@immutable
class PrototypeReportSummary {
  PrototypeReportSummary({
    required this.financial,
    required List<PrototypeReportSource> invoicesIssued,
    required List<PrototypeReportSource> paymentsReceived,
    required List<PrototypeReportSource> expenses,
    required List<PrototypeReportSource> recordedExpenses,
    required List<PrototypeReportSource> completedJobs,
    required List<PrototypeReportSource> activeJobs,
    required List<PrototypeReportSource> draftEstimates,
    required List<PrototypeReportSource> outstandingInvoices,
    required List<PrototypeReportSource> overdueInvoices,
    required List<PrototypeReportSource> materialExpenses,
    required List<PrototypeReportSource> fuelAndVehicleExpenses,
    required List<PrototypeReportSource> otherExpenses,
    required List<PrototypeReportSource> pendingAdminReview,
    required List<PrototypeReportSource> recordsToFinish,
    required List<PrototypeReportSource> waitingForApproval,
    required List<PrototypeReportSource> fuelExpenses,
    required List<PrototypeReportSource> vehicleRepairExpenses,
    required List<PrototypeReportSource> vehicleMaintenanceExpenses,
  }) : invoicesIssued = List.unmodifiable(invoicesIssued),
       paymentsReceived = List.unmodifiable(paymentsReceived),
       expenses = List.unmodifiable(expenses),
       recordedExpenses = List.unmodifiable(recordedExpenses),
       completedJobs = List.unmodifiable(completedJobs),
       activeJobs = List.unmodifiable(activeJobs),
       draftEstimates = List.unmodifiable(draftEstimates),
       outstandingInvoices = List.unmodifiable(outstandingInvoices),
       overdueInvoices = List.unmodifiable(overdueInvoices),
       materialExpenses = List.unmodifiable(materialExpenses),
       fuelAndVehicleExpenses = List.unmodifiable(fuelAndVehicleExpenses),
       otherExpenses = List.unmodifiable(otherExpenses),
       pendingAdminReview = List.unmodifiable(pendingAdminReview),
       recordsToFinish = List.unmodifiable(recordsToFinish),
       waitingForApproval = List.unmodifiable(waitingForApproval),
       fuelExpenses = List.unmodifiable(fuelExpenses),
       vehicleRepairExpenses = List.unmodifiable(vehicleRepairExpenses),
       vehicleMaintenanceExpenses = List.unmodifiable(
         vehicleMaintenanceExpenses,
       );

  final PrototypeFinancialSummary financial;
  final List<PrototypeReportSource> invoicesIssued;
  final List<PrototypeReportSource> paymentsReceived;
  final List<PrototypeReportSource> expenses;
  final List<PrototypeReportSource> recordedExpenses;
  final List<PrototypeReportSource> completedJobs;
  final List<PrototypeReportSource> activeJobs;
  final List<PrototypeReportSource> draftEstimates;
  final List<PrototypeReportSource> outstandingInvoices;
  final List<PrototypeReportSource> overdueInvoices;
  final List<PrototypeReportSource> materialExpenses;
  final List<PrototypeReportSource> fuelAndVehicleExpenses;
  final List<PrototypeReportSource> otherExpenses;
  final List<PrototypeReportSource> pendingAdminReview;
  final List<PrototypeReportSource> recordsToFinish;
  final List<PrototypeReportSource> waitingForApproval;
  final List<PrototypeReportSource> fuelExpenses;
  final List<PrototypeReportSource> vehicleRepairExpenses;
  final List<PrototypeReportSource> vehicleMaintenanceExpenses;

  int get outstandingInvoiceCents => _sum(outstandingInvoices);
  int get overdueInvoiceCents => _sum(overdueInvoices);
  int get materialExpenseCents => _sum(materialExpenses);
  int get fuelAndVehicleExpenseCents => _sum(fuelAndVehicleExpenses);
  int get otherExpenseCents => _sum(otherExpenses);
  int get scopedExpenseCents => _sum(expenses);
  int get fuelExpenseCents => _sum(fuelExpenses);
  int get vehicleRepairExpenseCents => _sum(vehicleRepairExpenses);
  int get vehicleMaintenanceExpenseCents => _sum(vehicleMaintenanceExpenses);
}

int _sum(List<PrototypeReportSource> sources) =>
    sources.fold(0, (total, source) => total + (source.amountCents ?? 0));

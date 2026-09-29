part of 'work_persistence_session.dart';

/// Financial command rules share the Work transaction and revision cache.
extension _WorkFinancialValidation on WorkPersistenceSession {
  void _validateAppliedPayment(
    PrototypeFinancialEntry application,
    Map<String, WorkRecord> available,
    List<PrototypeFinancialEntry> accepted,
  ) {
    final invoice = available[application.sourceId];
    final source = _entries[application.sourcePaymentId];
    if (application.paymentLinkKind != PaymentLinkKind.invoice ||
        application.amountCents <= 0 ||
        application.sourcePaymentId.isEmpty ||
        invoice == null ||
        invoice.kind != WorkRecordKind.invoice ||
        invoice.status == WorkRecordStatus.draft ||
        !permissions.visibleCreatorIds.contains(invoice.createdByEmployeeId) ||
        source == null ||
        !paymentMayFundInvoice(source, invoice, available.values) ||
        application.occurredOn.isBefore(source.occurredOn)) {
      throw StateError('This prior payment cannot be applied to this invoice.');
    }
    final ledger = [..._entries.values, ...accepted];
    if (application.amountCents > unappliedPaymentCents(source, ledger)) {
      throw StateError('That payment has already been applied.');
    }
    final paid = ledger
        .where(
          (entry) =>
              entry.paymentLinkKind == PaymentLinkKind.invoice &&
              (entry.kind == PrototypeFinancialKind.paymentReceived ||
                  entry.kind == PrototypeFinancialKind.paymentApplied) &&
              (entry.sourceId == invoice.id ||
                  entry.sourceId == invoice.number),
        )
        .fold(0, (sum, entry) => sum + entry.amountCents);
    if (application.amountCents > (invoice.total * 100).round() - paid) {
      throw StateError('The amount exceeds the current invoice balance.');
    }
  }

  Future<void> _validatePaymentAllocationsBeforeCommit(
    List<PrototypeFinancialEntry> entries,
  ) async {
    final applications = entries
        .where((entry) => entry.kind == PrototypeFinancialKind.paymentApplied)
        .toList();
    if (applications.isEmpty) return;
    final saved = await repository.ledgerForAllocationValidation(
      permissions.organizationId,
    );
    for (final application in applications) {
      final source = saved
          .where((entry) => entry.id == application.sourcePaymentId)
          .firstOrNull;
      if (source == null ||
          source.kind != PrototypeFinancialKind.paymentReceived ||
          !_entries.containsKey(source.id)) {
        throw StateError('The prior payment is no longer available.');
      }
      final combined = [
        ...saved,
        ...applications.where((entry) => entry.id != application.id),
      ];
      if (application.amountCents > unappliedPaymentCents(source, combined)) {
        throw const LocalRecordConflict(
          'That payment was applied elsewhere. Reopen the invoice before retrying.',
        );
      }
    }
  }

  List<PrototypeFinancialEntry> _validateFinancial(
    List<PrototypeFinancialEntry> requested,
    List<WorkRecord> proposed,
  ) {
    final available = {
      ..._records,
      for (final record in proposed) record.id: record,
    };
    final accepted = <PrototypeFinancialEntry>[];
    final seen = <String>{};
    for (final entry in requested) {
      if (!seen.add(entry.id)) {
        throw StateError(
          'A financial entry cannot be submitted twice in one command.',
        );
      }
      final existing = _entries[entry.id];
      if (existing != null) {
        if (canonicalJson(encodeFinancialEntry(existing)) !=
            canonicalJson(encodeFinancialEntry(entry))) {
          throw const LocalRecordConflict(
            'This financial entry was already saved with different values.',
          );
        }
        continue;
      }
      final permitted = entry.kind == PrototypeFinancialKind.invoiceIssued
          ? permissions.canIssueInvoices
          : permissions.canRecordPayments;
      if (!permitted) {
        throw StateError(
          'You do not have permission to record this financial action.',
        );
      }
      if (entry.kind == PrototypeFinancialKind.paymentApplied) {
        _validateAppliedPayment(entry, available, accepted);
        accepted.add(entry);
        continue;
      }
      if (entry.kind == PrototypeFinancialKind.paymentReceived &&
          entry.paymentLinkKind != PaymentLinkKind.invoice) {
        if (entry.amountCents <= 0) {
          throw StateError('Enter the amount actually received.');
        }
        if (entry.paymentLinkKind == PaymentLinkKind.none) {
          if (entry.sourceId.isNotEmpty || entry.description.trim().isEmpty) {
            throw StateError('Describe a payment without a linked record.');
          }
        } else {
          final expectedKind = switch (entry.paymentLinkKind) {
            PaymentLinkKind.job => WorkRecordKind.job,
            PaymentLinkKind.estimate => WorkRecordKind.estimate,
            PaymentLinkKind.quote => throw StateError(
              'Quote payments are unavailable until Quotes can be saved.',
            ),
            _ => throw StateError('This payment link is unavailable.'),
          };
          final related = available[entry.sourceId];
          if (related == null ||
              related.kind != expectedKind ||
              !permissions.visibleCreatorIds.contains(
                related.createdByEmployeeId,
              )) {
            throw StateError('Choose a Work record you can access.');
          }
        }
        accepted.add(entry);
        continue;
      }
      final invoices = available.values
          .where(
            (record) =>
                record.kind == WorkRecordKind.invoice &&
                (record.id == entry.sourceId ||
                    record.number == entry.sourceId),
          )
          .toList();
      if (invoices.length != 1 || entry.amountCents <= 0) {
        throw StateError(
          'The financial entry needs one valid invoice and a positive amount.',
        );
      }
      final invoice = invoices.single;
      if (!permissions.visibleCreatorIds.contains(
            invoice.createdByEmployeeId,
          ) ||
          invoice.status == WorkRecordStatus.draft) {
        throw StateError('That invoice cannot receive this financial entry.');
      }
      final related = [..._entries.values, ...accepted].where(
        (item) =>
            item.paymentLinkKind == PaymentLinkKind.invoice &&
            (item.sourceId == invoice.id || item.sourceId == invoice.number),
      );
      final totalCents = (invoice.total * 100).round();
      if (entry.kind == PrototypeFinancialKind.invoiceIssued) {
        if ((invoice.requiresInvoiceApproval ||
                permissions.requiresInvoiceApproval) &&
            !invoiceHasCurrentApproval(invoice)) {
          throw StateError(
            'This invoice needs approval before it can be issued.',
          );
        }

        if (entry.amountCents != totalCents ||
            related.any(
              (item) => item.kind == PrototypeFinancialKind.invoiceIssued,
            )) {
          throw StateError(
            'The invoice has already been issued or its amount changed.',
          );
        }
      } else {
        final paid = related
            .where(
              (item) =>
                  item.kind == PrototypeFinancialKind.paymentReceived ||
                  item.kind == PrototypeFinancialKind.paymentApplied,
            )
            .fold(0, (sum, item) => sum + item.amountCents);
        if (entry.amountCents > totalCents - paid) {
          throw StateError('The payment exceeds the current invoice balance.');
        }
      }
      accepted.add(entry);
    }
    return accepted;
  }

  void _validateInvoiceTransitions(
    List<WorkRecord> proposed,
    List<PrototypeFinancialEntry> entries,
  ) {
    for (final next in proposed) {
      final previous = _records[next.id];
      if (previous != null && previous.kind != next.kind) {
        throw StateError('A Work record cannot change its record type.');
      }
      if (next.kind != WorkRecordKind.invoice) continue;
      if (next.status != WorkRecordStatus.draft &&
          (previous == null || previous.status == WorkRecordStatus.draft) &&
          (next.requiresInvoiceApproval ||
              permissions.requiresInvoiceApproval) &&
          !invoiceHasCurrentApproval(next)) {
        throw StateError(
          'This invoice needs approval before it can be issued.',
        );
      }

      final related = entries.where(
        (entry) =>
            entry.paymentLinkKind == PaymentLinkKind.invoice &&
            (entry.sourceId == next.id || entry.sourceId == next.number),
      );
      if (previous == null &&
          next.status != WorkRecordStatus.draft &&
          (next.status != WorkRecordStatus.due ||
              !permissions.canIssueInvoices ||
              !related.any(
                (entry) => entry.kind == PrototypeFinancialKind.invoiceIssued,
              ))) {
        throw StateError(
          'Issue the invoice through its authorized financial command.',
        );
      }
      if (previous?.status == WorkRecordStatus.draft &&
          next.status != WorkRecordStatus.draft) {
        if (!permissions.canIssueInvoices ||
            next.status != WorkRecordStatus.due ||
            !related.any(
              (entry) => entry.kind == PrototypeFinancialKind.invoiceIssued,
            )) {
          throw StateError(
            'Issue the invoice through its authorized financial command.',
          );
        }
      }
      if (previous != null && previous.status != WorkRecordStatus.draft) {
        final before = encodeWorkRecord(previous)..remove('status');
        final after = encodeWorkRecord(next)..remove('status');
        if (canonicalJson(before) != canonicalJson(after)) {
          throw StateError('An issued invoice cannot be silently rewritten.');
        }
        if (next.status != previous.status &&
            next.status != WorkRecordStatus.paid) {
          throw StateError('Use an explicit invoice correction workflow.');
        }
      }
      if (next.status == WorkRecordStatus.paid &&
          previous?.status != WorkRecordStatus.paid) {
        final paid = [..._entries.values, ...entries]
            .where(
              (entry) =>
                  (entry.kind == PrototypeFinancialKind.paymentReceived ||
                      entry.kind == PrototypeFinancialKind.paymentApplied) &&
                  entry.paymentLinkKind == PaymentLinkKind.invoice &&
                  (entry.sourceId == next.id || entry.sourceId == next.number),
            )
            .fold(0, (sum, entry) => sum + entry.amountCents);
        if (!permissions.canRecordPayments ||
            paid != (next.total * 100).round()) {
          throw StateError(
            'Only confirmed payments can mark this invoice paid.',
          );
        }
      }
    }
  }

  void _appendInvoicePaymentRevisions(
    List<WorkRecordMutation> changes,
    List<PrototypeFinancialEntry> entries,
  ) {
    for (final entry in entries.where(
      (entry) =>
          (entry.kind == PrototypeFinancialKind.paymentReceived ||
              entry.kind == PrototypeFinancialKind.paymentApplied) &&
          entry.paymentLinkKind == PaymentLinkKind.invoice,
    )) {
      final invoice = _records.values.singleWhere(
        (record) =>
            record.kind == WorkRecordKind.invoice &&
            (record.id == entry.sourceId || record.number == entry.sourceId),
      );
      final paid = [..._entries.values, ...entries]
          .where(
            (item) =>
                (item.kind == PrototypeFinancialKind.paymentReceived ||
                    item.kind == PrototypeFinancialKind.paymentApplied) &&
                item.paymentLinkKind == PaymentLinkKind.invoice &&
                (item.sourceId == invoice.id ||
                    item.sourceId == invoice.number),
          )
          .fold(0, (sum, item) => sum + item.amountCents);
      // Even a partial payment advances this shared invoice revision. Separate
      // sessions must not both post against the same stale balance snapshot.
      if (!changes.any((change) => change.record.id == invoice.id)) {
        changes.add(
          WorkRecordMutation(
            record: paid == (invoice.total * 100).round()
                ? invoice.copyWith(status: WorkRecordStatus.paid)
                : invoice,
            expectedStorageRevision: _versions[invoice.id]!,
          ),
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/direct_payment_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_payment_draft_workflow.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_payment_entry_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';

void main() {
  final futureDay = DateTime(2100, 1, 1);

  test('a future calendar selection starts a direct payment on today', () {
    final input = DirectPaymentInput.initial(day: futureDay);
    final today = DateTime.now();
    expect(input.receivedOn.year, today.year);
    expect(input.receivedOn.month, today.month);
    expect(input.receivedOn.day, today.day);
  });

  test('direct payment rejects a future date received', () {
    final input = DirectPaymentInput.initial(day: DateTime.now()).copyWith(
      amount: '12.00',
      description: 'Service call',
      receivedOn: futureDay,
    );
    expect(
      input.confirmedPayment,
      throwsA(
        isA<DirectPaymentInputValidation>().having(
          (error) => error.message,
          'message',
          contains('today or an earlier date'),
        ),
      ),
    );
  });

  test('a future calendar selection starts an invoice payment on today', () {
    final input = InvoicePaymentInput.initial(
      invoiceId: 'invoice-1',
      balanceCents: 1200,
      day: futureDay,
    );
    final today = DateTime.now();
    expect(input.receivedOn.year, today.year);
    expect(input.receivedOn.month, today.month);
    expect(input.receivedOn.day, today.day);
  });

  test('invoice payment rejects a future date received', () {
    final input =
        InvoicePaymentInput.initial(
          invoiceId: 'invoice-1',
          balanceCents: 1200,
          day: DateTime.now(),
        ).withValues(
          amount: '12.00',
          note: '',
          method: 'Cash',
          receivedOn: futureDay,
        );
    const invoice = WorkRecord(
      id: 'invoice-1',
      kind: WorkRecordKind.invoice,
      number: 'Invoice 1',
      title: 'Service call',
      client: 'Customer',
      detail: 'Service call',
      pricing: WorkPricingModel.flatRate,
    );
    expect(
      () => input.confirmedPayment(invoice: invoice, balanceCents: 1200),
      throwsA(
        isA<InvoicePaymentInputValidation>().having(
          (error) => error.message,
          'message',
          contains('today or an earlier date'),
        ),
      ),
    );
  });

  testWidgets('invoice form displays today from a future calendar day', (
    tester,
  ) async {
    final scope = OperationalScopeController();
    addTearDown(scope.dispose);
    const invoice = WorkRecord(
      id: 'invoice-1',
      kind: WorkRecordKind.invoice,
      number: 'Invoice 1',
      title: 'Service call',
      client: 'Customer',
      detail: 'Service call',
      pricing: WorkPricingModel.flatRate,
    );
    await tester.pumpWidget(
      OperationalScope(
        controller: scope,
        child: MaterialApp(
          home: InvoicePaymentEntryScreen(
            invoice: invoice,
            balanceCents: 1200,
            initialDay: futureDay,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final dateRow = tester.widget<ListTile>(
      find.byKey(const ValueKey('invoice-payment-date')),
    );
    final dateLabel = (dateRow.subtitle! as Text).data;
    final context = tester.element(
      find.byKey(const ValueKey('invoice-payment-date')),
    );
    expect(
      dateLabel,
      MaterialLocalizations.of(context).formatMediumDate(DateTime.now()),
    );
    expect(dateLabel, isNot(contains('2100')));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/payment_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/payment_receipt_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/seeded_directory_fixture.dart';
import 'support/storage/seeded_work_fixture.dart';

void main() {
  testWidgets('saved owner payment opens PDF preview before any export', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final database = (await tester.runAsync(harness.open))!;
    final directory = (await tester.runAsync(
      () => openSeededTestDirectory(database),
    ))!;
    final work = (await tester.runAsync(
      () => openSeededTestWorkSession(database),
    ))!;
    final payment = work.financialEntries.firstWhere(
      (entry) => entry.kind == PrototypeFinancialKind.paymentReceived,
    );
    final store = PrototypeOperationsStore(
      directorySession: directory,
      workSession: work,
    );
    final scope = OperationalScopeController();
    addTearDown(() async {
      store.dispose();
      directory.dispose();
      work.dispose();
      scope.dispose();
      await harness.dispose();
    });
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: PaymentDetailScreen(payment: payment),
          ),
        ),
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('preview-payment-receipt')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preview-payment-receipt')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const ValueKey('payment-receipt-screen')),
      findsOneWidget,
    );
    await tester.drag(
      find
          .descendant(
            of: find.byType(PaymentReceiptScreen),
            matching: find.byType(ListView),
          )
          .first,
      const Offset(0, -400),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('save-payment-receipt')), findsOneWidget);
    expect(find.byKey(const ValueKey('share-payment-receipt')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unsaved payment cannot open a customer receipt', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final database = (await tester.runAsync(harness.open))!;
    final directory = (await tester.runAsync(
      () => openSeededTestDirectory(database),
    ))!;
    final work = (await tester.runAsync(
      () => openSeededTestWorkSession(database),
    ))!;
    final saved = work.financialEntries.firstWhere(
      (entry) => entry.kind == PrototypeFinancialKind.paymentReceived,
    );
    final unrecorded = PrototypeFinancialEntry(
      id: 'never-saved',
      kind: PrototypeFinancialKind.paymentReceived,
      occurredOn: saved.occurredOn,
      amountCents: saved.amountCents,
      sourceId: saved.sourceId,
      paymentMethod: saved.paymentMethod,
    );
    final store = PrototypeOperationsStore(
      directorySession: directory,
      workSession: work,
    );
    addTearDown(() async {
      store.dispose();
      directory.dispose();
      work.dispose();
      await harness.dispose();
    });
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          home: PaymentReceiptScreen(payment: unrecorded),
        ),
      ),
    );
    expect(find.text('This payment receipt is unavailable.'), findsOneWidget);
    expect(find.byKey(const ValueKey('save-payment-receipt')), findsNothing);
    expect(find.byKey(const ValueKey('share-payment-receipt')), findsNothing);
  });

  testWidgets('a demo company fallback cannot appear on a customer receipt', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final database = (await tester.runAsync(harness.open))!;
    final work = (await tester.runAsync(
      () => openSeededTestWorkSession(database),
    ))!;
    final payment = work.financialEntries.firstWhere(
      (entry) => entry.kind == PrototypeFinancialKind.paymentReceived,
    );
    final store = PrototypeOperationsStore(workSession: work);
    addTearDown(() async {
      store.dispose();
      work.dispose();
      await harness.dispose();
    });
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          home: PaymentReceiptScreen(payment: payment),
        ),
      ),
    );
    expect(find.text('This payment receipt is unavailable.'), findsOneWidget);
    expect(find.byKey(const ValueKey('save-payment-receipt')), findsNothing);
  });
}

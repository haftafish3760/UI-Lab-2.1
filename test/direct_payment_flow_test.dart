import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/direct_payment_draft_recovery.dart';
import 'package:ui_lab_2_1/src/screens/work/direct_payment_entry_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/payments_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';
import 'support/storage/seeded_work_fixture.dart';

void main() {
  testWidgets('record a payment without an invoice from Payments', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final database = (await tester.runAsync(harness.open))!;
    final work = (await tester.runAsync(
      () => openSeededTestWorkSession(database),
    ))!;
    final store = PrototypeOperationsStore(workSession: work);
    final scope = OperationalScopeController();
    addTearDown(() async {
      store.dispose();
      work.dispose();
      scope.dispose();
      await harness.dispose();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: PaymentsScreen(initialDay: DateTime(2026, 9, 26)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = work.financialEntries.length;
    await tester.tap(find.byKey(const ValueKey('record-payment-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payment without an invoice'));
    await waitForNativeSave(
      tester,
      () => find
          .byKey(const ValueKey('direct-payment-amount'))
          .evaluate()
          .isNotEmpty,
    );
    final amountField = tester.widget<TextField>(
      find.byKey(const ValueKey('direct-payment-amount')),
    );
    expect(
      amountField.keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    expect(amountField.textInputAction, TextInputAction.next);
    expect(amountField.decoration?.border, isA<UnderlineInputBorder>());
    expect(find.byType(Form), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('Amount received')), findsOneWidget);
    semantics.dispose();
    await tester.tap(find.byKey(const ValueKey('direct-payment-amount')));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('direct-payment-payer')))
          .focusNode
          ?.hasFocus,
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('save-direct-payment')));
    await tester.pumpAndSettle();
    expect(work.financialEntries.length, before);
    expect(find.text('Enter the amount actually received.'), findsWidgets);
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('direct-payment-amount')),
      '45.00',
    );
    await tester.enterText(
      find.byKey(const ValueKey('direct-payment-description')),
      'Lawn service',
    );
    await tester.tap(find.byKey(const ValueKey('save-direct-payment')));
    await waitForNativeSave(
      tester,
      () => work.financialEntries.length == before + 1,
    );
    final payment = work.financialEntries.singleWhere(
      (entry) => entry.description == 'Lawn service',
    );
    expect(payment.amountCents, 4500);
    expect(payment.paymentLinkKind, PaymentLinkKind.none);
    expect(payment.description, 'Lawn service');
    await tester.pumpAndSettle();
    final paymentRow = find.byKey(ValueKey('payment-entry-${payment.id}'));
    expect(paymentRow, findsOneWidget);
    await tester.tap(paymentRow);
    await tester.pumpAndSettle();
    expect(find.text('Lawn service'), findsWidgets);
    expect(
      await tester.runAsync(() => DirectPaymentDraftRecovery(work).list()),
      isEmpty,
    );
  });

  testWidgets(
    'payment form remains usable in wide dark layout with large text',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final database = (await tester.runAsync(harness.open))!;
      final work = (await tester.runAsync(
        () => openSeededTestWorkSession(database),
      ))!;
      final store = PrototypeOperationsStore(workSession: work);
      final scope = OperationalScopeController();
      addTearDown(() async {
        store.dispose();
        work.dispose();
        scope.dispose();
        await harness.dispose();
      });
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.8)),
                child: child!,
              ),
              home: PaymentsScreen(initialDay: DateTime(2026, 9, 26)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('record-payment-inline')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Payment without an invoice'));
      await waitForNativeSave(
        tester,
        () => find
            .byKey(const ValueKey('direct-payment-amount'))
            .evaluate()
            .isNotEmpty,
      );
      expect(find.text('Amount received'), findsOneWidget);
      expect(find.text('Save payment'), findsOneWidget);
      final before = work.financialEntries.length;
      await tester.enterText(
        find.byKey(const ValueKey('direct-payment-amount')),
        '32.10',
      );
      await tester.enterText(
        find.byKey(const ValueKey('direct-payment-description')),
        'Wide screen service',
      );
      await tester.tap(find.byKey(const ValueKey('save-direct-payment')));
      await waitForNativeSave(
        tester,
        () => work.financialEntries.length == before + 1,
      );
      final payment = work.financialEntries.singleWhere(
        (entry) => entry.description == 'Wide screen service',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('payment-entry-${payment.id}')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('payment-detail-screen')),
        findsOneWidget,
      );
      expect(find.text(r'$32.10'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving payment form keeps entered input for recovery', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final database = (await tester.runAsync(harness.open))!;
    final work = (await tester.runAsync(
      () => openSeededTestWorkSession(database),
    ))!;
    final store = PrototypeOperationsStore(workSession: work);
    final scope = OperationalScopeController();
    addTearDown(() async {
      store.dispose();
      work.dispose();
      scope.dispose();
      await harness.dispose();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: PaymentsScreen(initialDay: DateTime(2026, 9, 26)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('record-payment-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payment without an invoice'));
    await waitForNativeSave(
      tester,
      () => find
          .byKey(const ValueKey('direct-payment-amount'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.enterText(
      find.byKey(const ValueKey('direct-payment-amount')),
      '18.25',
    );
    await tester.enterText(
      find.byKey(const ValueKey('direct-payment-description')),
      'Emergency visit',
    );
    await tester.tap(find.byTooltip('Back to Work'));
    await waitForNativeSave(
      tester,
      () => find.byKey(const ValueKey('payments-screen')).evaluate().isNotEmpty,
    );
    final recovery = DirectPaymentDraftRecovery(work);
    final drafts = (await tester.runAsync(recovery.list))!;
    expect(drafts, hasLength(1));
    final recovered = (await tester.runAsync(
      () => recovery.resume(drafts.single),
    ))!;
    expect(recovered.input.amount, '18.25');
    expect(recovered.input.description, 'Emergency visit');
    final route =
        Navigator.of(
          tester.element(find.byKey(const ValueKey('payments-screen'))),
        ).push<void>(
          MaterialPageRoute(
            builder: (_) => DirectPaymentEntryScreen(
              initialDay: DateTime(2026, 9, 26),
              recoveredWorkflow: recovered,
            ),
          ),
        );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Discard unfinished payment'));
    await tester.tap(find.text('Discard unfinished payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard input'));
    await waitForNativeSave(
      tester,
      () => find
          .byKey(const ValueKey('direct-payment-entry-screen'))
          .evaluate()
          .isEmpty,
    );
    await route;
    expect(await tester.runAsync(recovery.list), isEmpty);
    expect(
      work.financialEntries.where(
        (entry) => entry.description == 'Emergency visit',
      ),
      isEmpty,
    );
  });

  testWidgets('failed local draft save does not record payment and can retry', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final database = (await tester.runAsync(harness.open))!;
    final work = (await tester.runAsync(
      () => openSeededTestWorkSession(database),
    ))!;
    final store = PrototypeOperationsStore(workSession: work);
    final scope = OperationalScopeController();
    addTearDown(() async {
      store.dispose();
      work.dispose();
      scope.dispose();
      await harness.dispose();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: PaymentsScreen(initialDay: DateTime(2026, 9, 26)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = work.financialEntries.length;
    await tester.tap(find.byKey(const ValueKey('record-payment-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payment without an invoice'));
    await waitForNativeSave(
      tester,
      () => find
          .byKey(const ValueKey('direct-payment-amount'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.runAsync(
      () => database.customStatement('''
        CREATE TRIGGER fail_payment_draft BEFORE INSERT ON local_drafts
        WHEN NEW.domain = 'work/direct-payment-editor'
        BEGIN SELECT RAISE(ABORT, 'injected write failure'); END
      '''),
    );
    await tester.enterText(
      find.byKey(const ValueKey('direct-payment-amount')),
      '7.50',
    );
    await tester.enterText(
      find.byKey(const ValueKey('direct-payment-description')),
      'Drain visit',
    );
    await waitForNativeSave(
      tester,
      () => find
          .text('Latest changes have not been saved.')
          .evaluate()
          .isNotEmpty,
    );
    await tester.tap(find.byKey(const ValueKey('save-direct-payment')));
    await waitForNativeSave(
      tester,
      () => find
          .textContaining('Retry saving it before recording the payment.')
          .evaluate()
          .isNotEmpty,
    );
    expect(work.financialEntries.length, before);
    expect(
      find.textContaining('Retry saving it before recording the payment.'),
      findsWidgets,
    );
    await tester.runAsync(
      () => database.customStatement('DROP TRIGGER fail_payment_draft'),
    );
    await tester.tap(find.text('Retry save'));
    await waitForNativeSave(
      tester,
      () => find.text('Latest changes have not been saved.').evaluate().isEmpty,
    );
    await tester.tap(find.byKey(const ValueKey('save-direct-payment')));
    await waitForNativeSave(
      tester,
      () => work.financialEntries.length == before + 1,
    );
    expect(
      work.financialEntries
          .singleWhere((entry) => entry.description == 'Drain visit')
          .amountCents,
      750,
    );
  });
}

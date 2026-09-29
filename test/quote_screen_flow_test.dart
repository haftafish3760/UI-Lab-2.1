import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/quote_approval_content.dart';
import 'package:ui_lab_2_1/src/screens/work/quote_workspace_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final size in [
    const Size(320, 850),
    const Size(360, 850),
    const Size(1200, 900),
  ]) {
    testWidgets('create save reopen edit quote at ${size.width}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final db = (await tester.runAsync(harness.open))!;
      final bootstrap = (await tester.runAsync(
        () => openUiLabWorkSession(db),
      ))!;
      final grants = bootstrap.permissions;
      final work = (await tester.runAsync(
        () => WorkPersistenceSession.open(
          bootstrap.repository,
          WorkSessionPermissions(
            organizationId: grants.organizationId,
            actorEmployeeId: grants.actorEmployeeId,
            permissionRevision: 'quote-ui-approval',
            visibleCreatorIds: grants.visibleCreatorIds,
            editableKinds: {WorkRecordKind.quote},
            requiresQuoteApproval: true,
            canApproveQuotes: true,
          ),
        ),
      ))!;
      bootstrap.dispose();
      final store = PrototypeOperationsStore(
        workSession: work,
        customers: const [
          WorkCustomerProfile(
            id: 'jamie',
            name: 'Jamie Morgan',
            companyName: '',
            phone: '2025550119',
            email: '',
            preferredContact: '',
            billingAddress: '',
            notes: '',
            linkedRecordCount: 0,
            locations: [],
          ),
        ],
      );
      final scope = OperationalScopeController();
      addTearDown(() async {
        store.dispose();
        scope.dispose();
        work.dispose();
        await finishNativeOperation(tester, harness.dispose);
      });
      Future<void> until(Finder finder) async {
        await waitForNativeSave(tester, () => finder.evaluate().isNotEmpty);
        expect(finder, findsOneWidget);
      }

      Future<void> tap(Finder finder) async {
        if (finder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            finder,
            250,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pump(const Duration(milliseconds: 300));
      }

      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(size.width == 320 ? 2 : 1),
                ),
                child: child!,
              ),
              home: QuoteWorkspaceScreen(initialDay: DateTime(2026, 9, 28)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('quote-drafts')), findsNothing);
      await tap(find.byKey(const ValueKey('new-quote')));
      final title = find.byKey(const ValueKey('quote-title'));
      await until(title);
      // Incomplete input must survive leaving and reopen as a Quote, even
      // before there is a confirmed business record or a selected customer.
      await tester.enterText(title, 'Kitchen mixer tap replacement');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(find.text('Save draft'));
      await until(find.byKey(const ValueKey('quote-drafts')));
      expect(work.records, isEmpty);
      await tap(find.byKey(const ValueKey('quote-drafts')));
      final draft = find.textContaining(
        'draft · Kitchen mixer tap replacement',
      );
      await until(draft);
      await tap(draft);
      await until(title);
      expect(
        tester.widget<TextField>(title).controller!.text,
        'Kitchen mixer tap replacement',
      );
      await tap(find.text('Client information'));
      await until(find.byKey(const ValueKey('saved-client-jamie')));
      await tap(find.byKey(const ValueKey('saved-client-jamie')));
      await until(find.byKey(const ValueKey('select-client-for-document')));
      await tap(find.byKey(const ValueKey('select-client-for-document')));
      await until(title);
      await tester.enterText(title, 'Kitchen mixer tap replacement');
      await tester.enterText(
        find.byKey(const ValueKey('quote-description')),
        'Supply and install a kitchen mixer tap.',
      );
      final price = find.descendant(
        of: find.byKey(const ValueKey('quote-price')),
        matching: find.byType(TextField),
      );
      await tester.enterText(price, '245.00');
      await tap(find.byKey(const ValueKey('save-quote')));
      await until(find.byKey(const ValueKey('quote-review')));
      expect(work.records.single.kind, WorkRecordKind.quote);
      expect(work.records.single.customerSnapshot!.id, 'jamie');
      expect(work.records.single.total, 245);
      expect(work.records.single.estimateDates!.expiresOn, isNull);
      await tap(find.byKey(const ValueKey('submit-quote-approval')));
      await until(find.byKey(const ValueKey('approve-quote-for-sending')));
      await tap(find.byKey(const ValueKey('approve-quote-for-sending')));
      await tap(find.byKey(const ValueKey('confirm-quote-company-approval')));
      await waitForNativeSave(
        tester,
        () => quoteHasCurrentCompanyApproval(work.records.single),
      );
      expect(work.records.single.customerApprovals, isEmpty);
      expect(work.records.single.customerSignature, isNull);
      await tap(find.byKey(const ValueKey('edit-quote')));
      await until(title);
      expect(
        tester.widget<TextField>(title).controller!.text,
        'Kitchen mixer tap replacement',
      );
      await tester.enterText(
        title,
        'Kitchen tap and isolation valve replacement',
      );
      await tap(find.byKey(const ValueKey('save-quote')));
      await until(find.byKey(const ValueKey('quote-review')));
      await waitForNativeSave(tester, () => work.records.single.revision == 2);
      expect(
        work.records.single.title,
        'Kitchen tap and isolation valve replacement',
      );
      expect(quoteHasCurrentCompanyApproval(work.records.single), isFalse);
      expect(work.records.single.total, 245);
      expect(work.records.single.customerSnapshot!.id, 'jamie');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      // Saving recovered input returns through the document drafts route.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final row = find.byKey(ValueKey('quote-row-${work.records.single.id}'));
      await until(row);
      await tap(row);
      await until(find.byKey(const ValueKey('quote-review')));
      expect(
        find.text('Kitchen tap and isolation valve replacement'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}

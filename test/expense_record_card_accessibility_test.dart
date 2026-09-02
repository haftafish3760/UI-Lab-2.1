import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_record_card.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets('long expense names reflow instead of clipping', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const vendor =
        'Central Supply Commercial Plumbing and Electrical Warehouse';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: ExpenseRecordCard(
              expense: ExpenseRecord(
                id: 'long-name',
                vendor: vendor,
                category: ExpenseCategory.materials,
                amount: 231.50,
                date: DateTime(2026, 8, 30),
                owner: 'Alex Morgan',
              ),
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(vendor, findRichText: true), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('expense-record-long-name')))
          .height,
      greaterThan(65),
    );
    expect(tester.takeException(), isNull);
  });
}

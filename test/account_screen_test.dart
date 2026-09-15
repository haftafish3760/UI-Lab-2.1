import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/account/account_gateway.dart';
import 'package:ui_lab_2_1/src/screens/account/account_screen.dart';

class FakeAccountGateway implements AccountGateway {
  int registrations = 0;
  int resets = 0;
  AccountIdentity? identity;
  Completer<void>? pending;
  @override
  Future<AccountIdentity?> current({bool reload = false}) async => identity;
  @override
  Future<void> register(String email, String password) async {
    registrations++;
    await pending?.future;
    identity = AccountIdentity(email: email, verified: false);
  }

  @override
  Future<void> signIn(String email, String password) async {
    identity = AccountIdentity(email: email, verified: true);
  }

  @override
  Future<void> resetPassword(String email) async {
    resets++;
  }

  @override
  Future<void> sendVerification() async {}
  @override
  Future<void> signOut() async {
    identity = null;
  }

  @override
  Future<void> deleteAccount() async {
    identity = null;
  }
}

void main() {
  testWidgets(
    'create validates matching passwords and prevents duplicate requests',
    (tester) async {
      final gateway = FakeAccountGateway();
      await tester.pumpWidget(
        MaterialApp(home: AccountScreen(gateway: gateway)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'tester@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'correct-horse-battery',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'different');
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pump();
      expect(gateway.registrations, 0);
      expect(find.text('Passwords must match.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'correct-horse-battery',
      );
      gateway.pending = Completer<void>();
      await tester.tap(find.text('Create account'));
      await tester.pump();
      await tester.tap(find.text('Create account'));
      expect(gateway.registrations, 1);
      gateway.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Email not verified'), findsOneWidget);
    },
  );

  testWidgets('narrow large text layout and reset address validation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = FakeAccountGateway();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: AccountScreen(gateway: gateway),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(gateway.resets, 0);
    expect(find.text('Enter your email address first.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

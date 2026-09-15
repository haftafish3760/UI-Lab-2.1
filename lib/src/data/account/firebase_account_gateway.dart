import 'package:firebase_auth/firebase_auth.dart';

import '../../startup/firebase_connection.dart';
import 'account_gateway.dart';

/// Authentication proves identity only; membership/record permissions are a
/// separate authority. No local record upload or ownership changes occur here.
class FirebaseAccountGateway implements AccountGateway {
  FirebaseAccountGateway(this.connection);
  final FirebaseConnection connection;

  Future<FirebaseAuth> _auth() async {
    await connection.open();
    if (connection.state.value != FirebaseConnectionState.ready) {
      throw StateError('Account connection is unavailable on this device.');
    }
    return FirebaseAuth.instance;
  }

  @override
  Future<AccountIdentity?> current({bool reload = false}) async {
    final auth = await _auth();
    if (reload) {
      await auth.currentUser?.reload();
    }
    final user = auth.currentUser;
    return user == null
        ? null
        : AccountIdentity(
            email: user.email ?? '',
            verified: user.emailVerified,
          );
  }

  @override
  Future<void> signIn(String email, String password) async {
    await (await _auth()).signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> register(String email, String password) async {
    await (await _auth()).createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> resetPassword(String email) async {
    await (await _auth()).sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendVerification() async {
    final user = (await _auth()).currentUser;
    if (user == null) {
      throw StateError('Sign in before verifying your email.');
    }
    await user.sendEmailVerification();
  }

  @override
  Future<void> signOut() async => (await _auth()).signOut();

  @override
  Future<void> deleteAccount() async {
    final user = (await _auth()).currentUser;
    if (user == null) {
      throw StateError('Sign in before deleting your account.');
    }
    // Account-only slice: no cloud company records exist through this gateway.
    // A future company deletion workflow must not reuse this in isolation.
    await user.delete();
  }
}

import 'package:firebase_auth/firebase_auth.dart';

String accountErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' =>
        'Choose a stronger password that meets the account password requirements.',
      'email-already-in-use' =>
        'Unable to create this account. Try signing in or resetting your password.',
      'invalid-credential' || 'wrong-password' || 'user-not-found' =>
        'Unable to sign in. Check your email and password, or reset your password.',
      'network-request-failed' =>
        'Could not connect. Check your connection and try again.',
      'too-many-requests' =>
        'Too many attempts. Please wait before trying again.',
      'requires-recent-login' =>
        'Sign out and sign in again before deleting this account.',
      'user-disabled' => 'This account is unavailable. Contact support.',
      _ =>
        'The account request could not be completed. Please try again later.',
    };
  }
  return 'Account connection is unavailable. Your local records remain on this device.';
}

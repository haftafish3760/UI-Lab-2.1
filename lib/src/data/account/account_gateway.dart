class AccountIdentity {
  const AccountIdentity({required this.email, required this.verified});
  final String email;
  final bool verified;
}

abstract interface class AccountGateway {
  Future<AccountIdentity?> current({bool reload = false});
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> resetPassword(String email);
  Future<void> sendVerification();
  Future<void> signOut();
  Future<void> deleteAccount();
}

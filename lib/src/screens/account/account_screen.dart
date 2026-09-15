import 'package:flutter/material.dart';
import '../../data/account/account_gateway.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'account_error_message.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({required this.gateway, super.key});
  final AccountGateway gateway;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _form = GlobalKey<FormState>();
  AccountIdentity? _account;
  bool _busy = false;
  bool _create = false;
  bool _showPassword = false;
  String? _message;
  DateTime? _lastVerification;

  @override
  void initState() {
    super.initState();
    _run(() async {
      _account = await widget.gateway.current();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        _message = accountErrorMessage(error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    final email = _email.text.trim();
    final password = _password.text;
    await _run(() async {
      if (_create) {
        await widget.gateway.register(email, password);
      } else {
        await widget.gateway.signIn(email, password);
      }
      if (!mounted) {
        return;
      }
      _password.clear();
      _confirm.clear();
      _account = await widget.gateway.current();
      _message = _create
          ? 'Account created. Verify your email below.'
          : 'Signed in.';
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your sign-in account?'),
        content: const Text(
          'This removes your online sign-in account. Local records on this device remain. Company backup is not enabled in this build.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep account'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _run(() async {
      await widget.gateway.deleteAccount();
      _account = null;
      _message = 'Account deleted. Local records remain on this device.';
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Your account')),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: AppLayoutEngine.pageInsetsFor(constraints.maxWidth),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Tame Your Biz',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'An account is optional. Your existing records stay on this device. Company sharing and backup are not enabled yet.',
                  ),
                  const SizedBox(height: 16),
                  if (_busy) const LinearProgressIndicator(),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(_message!),
                      ),
                    ),
                  if (_account case final account?)
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            account.email,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            account.verified
                                ? 'Email verified'
                                : 'Email not verified',
                          ),
                          if (!account.verified)
                            FilledButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(() async {
                                      if (_lastVerification != null &&
                                          DateTime.now().difference(
                                                _lastVerification!,
                                              ) <
                                              const Duration(minutes: 1)) {
                                        _message =
                                            'Please wait one minute before requesting another email.';
                                        return;
                                      }
                                      await widget.gateway.sendVerification();
                                      _lastVerification = DateTime.now();
                                      _message =
                                          'Verification email sent. Check your inbox.';
                                    }),
                              child: const Text('Send verification email'),
                            ),
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _run(() async {
                                    _account = await widget.gateway.current(
                                      reload: true,
                                    );
                                  }),
                            child: const Text('Refresh account'),
                          ),
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _run(() async {
                                    await widget.gateway.signOut();
                                    _account = null;
                                    _password.clear();
                                    _confirm.clear();
                                    _message =
                                        'Signed out. Local records remain on this device.';
                                  }),
                            child: const Text('Sign out'),
                          ),
                          TextButton(
                            onPressed: _busy ? null : _delete,
                            child: const Text('Delete sign-in account'),
                          ),
                        ],
                      ),
                    )
                  else
                    Form(
                      key: _form,
                      child: SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _create ? 'Create an account' : 'Sign in',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            TextFormField(
                              controller: _email,
                              enabled: !_busy,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                              ),
                              validator: (value) =>
                                  value == null ||
                                      !RegExp(
                                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                      ).hasMatch(value.trim())
                                  ? 'Enter a valid email address.'
                                  : null,
                            ),
                            TextFormField(
                              controller: _password,
                              enabled: !_busy,
                              obscureText: !_showPassword,
                              autocorrect: false,
                              enableSuggestions: false,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                suffixIcon: IconButton(
                                  tooltip: _showPassword
                                      ? 'Hide password'
                                      : 'Show password',
                                  onPressed: () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Enter your password.'
                                  : null,
                            ),
                            if (_create)
                              TextFormField(
                                controller: _confirm,
                                enabled: !_busy,
                                obscureText: true,
                                autocorrect: false,
                                enableSuggestions: false,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm password',
                                ),
                                validator: (value) => value != _password.text
                                    ? 'Passwords must match.'
                                    : null,
                              ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _busy ? null : _submit,
                              child: Text(
                                _create ? 'Create account' : 'Sign in',
                              ),
                            ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                      _create = !_create;
                                      _message = null;
                                      _password.clear();
                                      _confirm.clear();
                                    }),
                              child: Text(
                                _create
                                    ? 'Already have an account? Sign in'
                                    : 'Create an account',
                              ),
                            ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () {
                                      final email = _email.text.trim();
                                      if (!RegExp(
                                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                      ).hasMatch(email)) {
                                        setState(
                                          () => _message =
                                              'Enter your email address first.',
                                        );
                                        return;
                                      }
                                      _run(() async {
                                        await widget.gateway.resetPassword(
                                          email,
                                        );
                                        _message =
                                            'If this email can receive a reset link, check its inbox.';
                                      });
                                    },
                              child: const Text('Forgot password?'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Return to my local records'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

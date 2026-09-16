import 'package:flutter/material.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_preferences.dart';
import '../../theme/app_theme.dart';
import 'receipt_choice_card.dart';

/// Preferences are applied together only after both setup steps are confirmed.
class ExpenseWelcomeScreen extends StatefulWidget {
  const ExpenseWelcomeScreen({required this.preferences, super.key});
  final AppPreferencesController preferences;

  @override
  State<ExpenseWelcomeScreen> createState() => _ExpenseWelcomeScreenState();
}

class _ExpenseWelcomeScreenState extends State<ExpenseWelcomeScreen> {
  late bool _detailed = widget.preferences.receiptDetailedReceipts;
  bool? _assistance;
  bool _assistanceStep = false, _saving = false;
  String? _error;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _back() {
    if (_saving) return;
    if (_assistanceStep) {
      setState(() => _assistanceStep = false);
      _scroll.jumpTo(0);
    } else {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _continue() async {
    if (_saving) return;
    if (!_assistanceStep) {
      setState(() => _assistanceStep = true);
      _scroll.jumpTo(0);
      return;
    }
    if (_assistance == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.preferences.completeExpenseSetup(
      detailed: _detailed,
      assistance: _assistance!,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = 'Your choices could not be saved. Tap Continue to try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving && !_assistanceStep,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_saving) _back();
    },
    child: Scaffold(
      key: const ValueKey('expense-welcome-screen'),
      appBar: AppBar(
        leading: IconButton(
          onPressed: _saving ? null : _back,
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Expense setup'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            return SingleChildScrollView(
              controller: _scroll,
              padding: insets.copyWith(top: 20, bottom: 28),
              child: Center(
                child: SizedBox(
                  width: AppLayoutEngine.formWorkspaceWidthFor(
                    constraints.maxWidth - insets.horizontal,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _assistanceStep
                            ? 'Help with your receipts'
                            : 'Welcome to Expenses',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _assistanceStep
                            ? 'The app can read text from your receipt photos and help fill in the details. You review them before saving.'
                            : 'Let’s get a few things set up.',
                      ),
                      const SizedBox(height: 28),
                      Text(
                        _assistanceStep
                            ? 'Would you like the app to help fill out your receipts?'
                            : 'How much detail would you like to save?',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      if (!_assistanceStep) ...[
                        ReceiptChoiceCard(
                          key: const ValueKey('expense-setup-basic'),
                          title: 'Basic receipt',
                          description:
                              'Save the receipt total and an optional category. Individual items are not recorded.',
                          icon: Icons.receipt_outlined,
                          selected: !_detailed,
                          onTap: () => setState(() => _detailed = false),
                        ),
                        const SizedBox(height: 24),
                        ReceiptChoiceCard(
                          key: const ValueKey('expense-setup-detailed'),
                          title: 'Detailed receipt',
                          description:
                              'Save the receipt total, each item, how many you bought, and its price. You can also choose a category.',
                          icon: Icons.format_list_numbered,
                          selected: _detailed,
                          onTap: () => setState(() => _detailed = true),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'You can attach a receipt image with either option.',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You can change this when adding a receipt. The app remembers your last choice.',
                        ),
                      ] else ...[
                        ReceiptChoiceCard(
                          key: const ValueKey('expense-setup-assisted'),
                          title: 'Yes, help me fill it out',
                          description:
                              'Read my receipt photos on this device. I’ll check the details before saving.',
                          icon: Icons.document_scanner_outlined,
                          selected: _assistance == true,
                          onTap: _saving
                              ? null
                              : () => setState(() => _assistance = true),
                        ),
                        const SizedBox(height: 24),
                        ReceiptChoiceCard(
                          key: const ValueKey('expense-setup-manual'),
                          title: 'No, I’ll fill it out myself',
                          description:
                              'Enter the details myself. I can still attach receipt photos.',
                          icon: Icons.edit_outlined,
                          selected: _assistance == false,
                          onTap: _saving
                              ? null
                              : () => setState(() => _assistance = false),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'You can change this anytime: open Expenses, tap the gear, then Receipt assistance.',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This does not turn on cloud backup or sync.',
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      FilledButton(
                        key: const ValueKey('expense-welcome-continue'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                        ),
                        onPressed:
                            _saving || (_assistanceStep && _assistance == null)
                            ? null
                            : _continue,
                        child: Text(_saving ? 'Saving…' : 'Continue'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

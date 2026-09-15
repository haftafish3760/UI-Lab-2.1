import 'package:flutter/material.dart';
import '../../layout/app_layout_engine.dart';
import '../../theme/app_theme.dart';

class ReceiptTextInput {
  const ReceiptTextInput(this.text);

  /// Null means the user explicitly chose to enter structured details instead.
  final String? text;
}

class ReceiptTextEntryScreen extends StatefulWidget {
  const ReceiptTextEntryScreen({required this.initial, super.key});
  final String initial;
  @override
  State<ReceiptTextEntryScreen> createState() => _ReceiptTextEntryState();
}

class _ReceiptTextEntryState extends State<ReceiptTextEntryScreen> {
  late final _text = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Paste receipt text')),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          final width = AppLayoutEngine.formWorkspaceWidthFor(
            constraints.maxWidth - insets.horizontal,
          );
          return SingleChildScrollView(
            padding: insets.copyWith(top: 12, bottom: 24),
            child: Center(
              child: SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Paste the receipt text you copied from an email or another app. Nothing is read from your clipboard until you paste it.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('receipt-pasted-text'),
                      controller: _text,
                      minLines: 8,
                      maxLines: 20,
                      maxLength: 100000,
                      decoration: const InputDecoration(
                        labelText: 'Receipt text',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const ValueKey('confirm-receipt-text'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _text.text.trim().isEmpty
                          ? null
                          : () => Navigator.pop(
                              context,
                              ReceiptTextInput(_text.text),
                            ),
                      icon: const Icon(Icons.check),
                      label: const Text('Use this text'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      key: const ValueKey('manual-receipt-entry'),
                      onPressed: () =>
                          Navigator.pop(context, const ReceiptTextInput(null)),
                      child: const Text('Enter amount and details instead'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

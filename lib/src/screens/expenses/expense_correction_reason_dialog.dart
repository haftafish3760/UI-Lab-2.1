import 'package:flutter/material.dart';

import '../../theme/app_semantic_colors.dart';

Future<String?> showExpenseCorrectionReasonDialog(
  BuildContext context, {
  required bool resetsApproval,
}) async {
  final formKey = GlobalKey<FormState>();
  var reason = '';
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final semantic = theme.extension<AppSemanticColors>()!;
      return AlertDialog(
        key: const ValueKey('expense-correction-reason-dialog'),
        title: const Text('Why are you correcting this receipt?'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'The original receipt files and earlier confirmed values '
                  'will remain in the record.',
                ),
                if (resetsApproval) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: semantic.attentionSurface,
                      border: Border.all(color: semantic.attention),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notification_important_outlined,
                          color: semantic.attention,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'This correction requires company approval before '
                            'it counts in company books.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey('expense-correction-reason-field'),
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Correction reason',
                    hintText: 'Example: Corrected the quantity and sales tax',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a reason for this correction.'
                      : null,
                  onChanged: (value) => reason = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Do not save'),
          ),
          FilledButton(
            key: const ValueKey('confirm-expense-correction-button'),
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(dialogContext, reason.trim());
            },
            child: const Text('Save correction'),
          ),
        ],
      );
    },
  );
}

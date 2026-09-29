import 'package:flutter/material.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../data/work/models/work_models.dart';
import '../../shared/utility_form_section.dart';

/// Changes public presentation only; never removes the user's line items.
class WorkDocumentPresentationControl extends StatelessWidget {
  const WorkDocumentPresentationControl({
    required this.value,
    required this.onChanged,
    super.key,
  });
  final WorkDocumentPresentation value;
  final ValueChanged<WorkDocumentPresentation> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return UtilityFormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<WorkDocumentPresentation>(
            key: ValueKey('document-presentation-${value.name}'),
            initialValue: value,
            isExpanded: true,
            itemHeight: null,
            decoration: InputDecoration(labelText: l10n.workDocumentStyle),
            items: [
              DropdownMenuItem(
                value: WorkDocumentPresentation.detailed,
                child: Text(l10n.workDocumentDetailed),
              ),
              DropdownMenuItem(
                value: WorkDocumentPresentation.summary,
                child: Text(l10n.workDocumentSummary),
              ),
            ],
            onChanged: (choice) {
              if (choice != null) onChanged(choice);
            },
          ),
          const SizedBox(height: 12),
          Text(
            value == WorkDocumentPresentation.detailed
                ? l10n.workDocumentDetailedHelp
                : l10n.workDocumentSummaryHelp,
          ),
        ],
      ),
    );
  }
}

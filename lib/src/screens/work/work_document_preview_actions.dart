part of 'work_document_preview_screen.dart';

Future<void> _showPdfDeliveryOptions(
  BuildContext context,
  WorkRecord record,
) async {
  final selected = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PDF delivery options',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Choose how the final customer copy should leave the app. Choose the customer and confirm sending in your sharing app.',
              style: TextStyle(
                color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            for (final option in const [
              (Icons.email_outlined, 'Email PDF to customer'),
              (Icons.ios_share_outlined, 'Share from this device'),
              (Icons.save_alt_outlined, 'Save PDF copy'),
              (Icons.print_outlined, 'Print customer copy'),
            ])
              ListTile(
                leading: Icon(option.$1),
                title: Text(option.$2),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(sheetContext).pop(option.$2),
              ),
          ],
        ),
      ),
    ),
  );
  if (selected == null || !context.mounted) return;
  try {
    await deliverWorkPdf(
      context,
      record,
      selected == 'Print customer copy'
          ? WorkPdfAction.print
          : selected == 'Save PDF copy'
          ? WorkPdfAction.save
          : WorkPdfAction.share,
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(pdfExportErrorMessage(error))));
    }
  }
}

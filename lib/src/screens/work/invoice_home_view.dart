part of 'invoice_workspace_screen.dart';

extension _InvoiceHomeView on _InvoiceWorkspaceScreenState {
  Widget? _buildNewInvoiceAction() => widget.permissions.canCreate
      ? FloatingActionButton.extended(
          key: const ValueKey('new-invoice'),
          onPressed: _createInvoice,
          icon: const Icon(Icons.add_rounded),
          label: Text(context.l10n.workNewInvoice),
        )
      : null;
}

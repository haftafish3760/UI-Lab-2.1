import 'package:flutter/material.dart';
import 'work_models.dart';

class EstimateCustomerApprovalDialog extends StatefulWidget {
  const EstimateCustomerApprovalDialog({
    required this.record,
    required this.actorId,
    this.summary,
    super.key,
  });
  final WorkRecord record;
  final String actorId;
  final String? summary;
  @override
  State<EstimateCustomerApprovalDialog> createState() =>
      _EstimateCustomerApprovalDialogState();
}

class _EstimateCustomerApprovalDialogState
    extends State<EstimateCustomerApprovalDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.record.client);
  final _note = TextEditingController();
  CustomerApprovalMethod? _method;
  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Record customer approval'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.summary ??
                    '${widget.record.number} · Revision ${widget.record.revision}\n\$${widget.record.total.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CustomerApprovalMethod>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Approval method'),
                items: [
                  for (final method in CustomerApprovalMethod.values)
                    DropdownMenuItem(value: method, child: Text(method.label)),
                ],
                onChanged: (value) => setState(() => _method = value),
                validator: (value) =>
                    value == null ? 'Choose how the customer approved.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Customer who approved',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the customer’s name.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Approval note or evidence reference',
                ),
                validator: (value) =>
                    _method == CustomerApprovalMethod.other &&
                        (value == null || value.trim().isEmpty)
                    ? 'Describe the approval.'
                    : null,
              ),
              const SizedBox(height: 12),
              const Text(
                'This records the approval reported by your business. It does not guarantee a legally binding contract. Requirements vary by location and type of work.',
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          Navigator.pop(
            context,
            WorkCustomerApproval(
              method: _method!,
              customerName: _name.text.trim(),
              recordedByEmployeeId: widget.actorId,
              recordedOn: DateTime.now(),
              revision: widget.record.revision,
              note: _note.text.trim(),
            ),
          );
        },
        child: const Text('Record approval'),
      ),
    ],
  );
}

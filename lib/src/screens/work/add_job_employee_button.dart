import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/employee_directory_profile.dart';
import '../../shell/employee_editor_screen.dart';

/// Keeps the job input safe before opening the shared employee editor.
class AddJobEmployeeButton extends StatefulWidget {
  const AddJobEmployeeButton({
    required this.beforeOpen,
    required this.onCreated,
    super.key,
  });
  final Future<void> Function() beforeOpen;
  final ValueChanged<EmployeeDirectoryProfile> onCreated;

  @override
  State<AddJobEmployeeButton> createState() => _AddJobEmployeeButtonState();
}

class _AddJobEmployeeButtonState extends State<AddJobEmployeeButton> {
  bool _opening = false;
  String? _error;

  Future<void> _open() async {
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      await widget.beforeOpen();
      if (!mounted) return;
      final employee = await Navigator.of(context)
          .push<EmployeeDirectoryProfile>(
            MaterialPageRoute(builder: (_) => const EmployeeEditorScreen()),
          );
      if (mounted && employee != null) widget.onCreated(employee);
    } on Object {
      if (mounted) {
        setState(
          () => _error =
              'Your job input could not be saved. Try again before adding an employee.',
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final directory = PrototypeOperationsScope.of(context).directorySession;
    if (directory?.permissions.canManageEmployees != true) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          key: const ValueKey('job-add-employee'),
          onPressed: _opening ? null : _open,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Add employee'),
        ),
        if (_error != null) Text(_error!),
      ],
    );
  }
}

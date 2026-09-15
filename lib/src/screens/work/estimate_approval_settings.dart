import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/directory_persistence_session.dart';

/// The setting belongs to the shared company profile, not local display prefs.
class EstimateApprovalSetting extends StatefulWidget {
  const EstimateApprovalSetting({super.key});
  @override
  State<EstimateApprovalSetting> createState() =>
      _EstimateApprovalSettingState();
}

class _EstimateApprovalSettingState extends State<EstimateApprovalSetting> {
  bool _saving = false;
  String? _error;
  @override
  Widget build(BuildContext context) {
    final directory = PrototypeOperationsScope.maybeOf(
      context,
    )?.directorySession;
    if (directory == null || !directory.permissions.canViewCompany) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Company approval', style: Theme.of(context).textTheme.titleLarge),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Approve estimates before sending'),
          subtitle: const Text(
            'New estimates need company approval before they can be shared with a customer. Existing estimates keep their recorded approval requirements. Changes to this switch save immediately.',
          ),
          value: directory.company.requireEstimateApproval,
          onChanged: _saving || !directory.permissions.canManageCompany
              ? null
              : (value) => _save(directory, value),
        ),
        if (_saving) const LinearProgressIndicator(),
        if (_error != null) Text(_error!),
        const Divider(height: 24),
      ],
    );
  }

  Future<void> _save(DirectoryPersistenceSession directory, bool value) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await directory.saveCompany(
      directory.company.copyWith(requireEstimateApproval: value),
      expectedRevision: directory.companyRevision,
    );
    if (mounted) {
      setState(() {
        _saving = false;
        if (!saved) _error = 'The approval setting was not saved. Try again.';
      });
    }
  }
}

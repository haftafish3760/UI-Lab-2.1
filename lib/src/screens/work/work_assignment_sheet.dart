import 'package:flutter/material.dart';

class WorkAssignmentSheet extends StatefulWidget {
  const WorkAssignmentSheet({super.key});

  @override
  State<WorkAssignmentSheet> createState() => _WorkAssignmentSheetState();
}

class _WorkAssignmentSheetState extends State<WorkAssignmentSheet> {
  var _employee = 'Alex Morgan';
  var _vehicle = 'Transit 12';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Assign this job',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose the technician and vehicle. Schedule conflicts will be checked before this is saved in the production app.',
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _employee,
              decoration: const InputDecoration(labelText: 'Technician'),
              items: const ['Alex Morgan', 'Jordan Lee', 'Sam Rivera']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _employee = value ?? _employee),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _vehicle,
              decoration: const InputDecoration(labelText: 'Vehicle'),
              items: const ['Transit 12', 'Service Van 4', 'Pickup 2']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _vehicle = value ?? _vehicle),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, (_employee, _vehicle)),
              icon: const Icon(Icons.assignment_ind_outlined),
              label: const Text('Save assignment'),
            ),
          ],
        ),
      ),
    );
  }
}

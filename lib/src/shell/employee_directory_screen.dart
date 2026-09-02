import 'package:flutter/material.dart';

import '../layout/app_layout_engine.dart';
import '../shared/section_card.dart';

class EmployeeDirectoryScreen extends StatefulWidget {
  const EmployeeDirectoryScreen({super.key});

  @override
  State<EmployeeDirectoryScreen> createState() =>
      _EmployeeDirectoryScreenState();
}

class _EmployeeDirectoryScreenState extends State<EmployeeDirectoryScreen> {
  final _employees = <_EmployeeProfile>[
    const _EmployeeProfile(
      id: 'alex',
      name: 'Alex Morgan',
      phone: '(555) 014-2904',
      emergencyContact: 'Morgan Household · (555) 014-8732',
      role: 'Technician',
      pay: r'$28.00 per hour',
      status: 'On a job',
    ),
    const _EmployeeProfile(
      id: 'jordan',
      name: 'Jordan Lee',
      phone: '(555) 014-6671',
      emergencyContact: 'Lee Household · (555) 014-1905',
      role: 'Technician',
      pay: r'$26.50 per hour',
      status: 'Available',
      canCreateEstimates: true,
    ),
    const _EmployeeProfile(
      id: 'riley',
      name: 'Riley Chen',
      phone: '(555) 014-8055',
      emergencyContact: 'Chen Household · (555) 014-2240',
      role: 'Supervisor',
      pay: r'$33.00 per hour',
      status: 'Driving',
      canCreateEstimates: true,
      canApproveEstimates: true,
      canViewCompanyReports: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final active = _employees.where((employee) => employee.active).toList();
    final former = _employees.where((employee) => !employee.active).toList();
    return Scaffold(
      key: const ValueKey('employee-directory-screen'),
      appBar: AppBar(title: const Text('Employees')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-employee-button'),
        onPressed: () => _edit(),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add employee'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          return ListView(
            padding: EdgeInsets.fromLTRB(insets.left, 14, insets.right, 96),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Employee records',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Keep active and former employees with their own access. Pay and emergency contacts remain private company records.',
                      ),
                      const SizedBox(height: 14),
                      _EmployeeSection(
                        title: 'Active employees',
                        employees: active,
                        onEdit: _edit,
                      ),
                      const SizedBox(height: 12),
                      _EmployeeSection(
                        title: 'Former employees',
                        employees: former,
                        onEdit: _edit,
                        empty: 'No former employees are retained.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit([_EmployeeProfile? profile]) async {
    final updated = await Navigator.of(context).push<_EmployeeProfile>(
      MaterialPageRoute(builder: (_) => _EmployeeEditor(initial: profile)),
    );
    if (!mounted || updated == null) return;
    setState(() {
      final index = _employees.indexWhere(
        (employee) => employee.id == updated.id,
      );
      if (index < 0) {
        _employees.add(updated);
      } else {
        _employees[index] = updated;
      }
    });
  }
}

class _EmployeeSection extends StatelessWidget {
  const _EmployeeSection({
    required this.title,
    required this.employees,
    required this.onEdit,
    this.empty = 'No employees are in this section.',
  });
  final String title;
  final List<_EmployeeProfile> employees;
  final ValueChanged<_EmployeeProfile> onEdit;
  final String empty;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        ListTile(
          tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: Text('${employees.length}'),
        ),
        if (employees.isEmpty)
          Padding(padding: const EdgeInsets.all(16), child: Text(empty))
        else
          for (final employee in employees)
            ListTile(
              key: ValueKey('employee-profile-${employee.id}'),
              leading: const Icon(Icons.badge_outlined),
              title: Text(employee.name),
              subtitle: Text(
                '${employee.role} · ${employee.status}\n${employee.phone}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onEdit(employee),
            ),
      ],
    ),
  );
}

class _EmployeeEditor extends StatefulWidget {
  const _EmployeeEditor({this.initial});
  final _EmployeeProfile? initial;

  @override
  State<_EmployeeEditor> createState() => _EmployeeEditorState();
}

class _EmployeeEditorState extends State<_EmployeeEditor> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _phone = TextEditingController(text: widget.initial?.phone ?? '');
  late final _emergency = TextEditingController(
    text: widget.initial?.emergencyContact ?? '',
  );
  late final _pay = TextEditingController(text: widget.initial?.pay ?? '');
  late var _role = widget.initial?.role ?? 'Technician';
  late var _active = widget.initial?.active ?? true;
  late var _canSeeEstimates = widget.initial?.canSeeEstimates ?? true;
  late var _canCreateEstimates = widget.initial?.canCreateEstimates ?? false;
  late var _canApproveEstimates = widget.initial?.canApproveEstimates ?? false;
  late var _canRecordExpenses = widget.initial?.canRecordExpenses ?? true;
  late var _canViewCompanyReports =
      widget.initial?.canViewCompanyReports ?? false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _emergency.dispose();
    _pay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.initial == null ? 'Add employee' : 'Edit employee'),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Employee information',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Answer ordinary questions. Access is still enforced behind the screen.',
                  ),
                  const SizedBox(height: 14),
                  SectionCard(
                    child: Column(
                      children: [
                        _field(_name, 'Employee name'),
                        _field(_phone, 'Phone number'),
                        _field(_emergency, 'Emergency contact'),
                        _field(_pay, 'Pay arrangement (private)'),
                        DropdownButtonFormField<String>(
                          initialValue: _role,
                          decoration: const InputDecoration(labelText: 'Role'),
                          items:
                              const [
                                    'Helper',
                                    'Technician',
                                    'Supervisor',
                                    'Office',
                                  ]
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) =>
                              setState(() => _role = value ?? _role),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'What may this employee do?',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _PermissionQuestion(
                          controlKey: const ValueKey(
                            'permission-view-estimates',
                          ),
                          question: 'Can this employee see estimates?',
                          value: _canSeeEstimates,
                          onChanged: (value) => setState(() {
                            _canSeeEstimates = value;
                            if (!value) {
                              _canCreateEstimates = false;
                              _canApproveEstimates = false;
                            }
                          }),
                        ),
                        _PermissionQuestion(
                          controlKey: const ValueKey(
                            'permission-create-estimates',
                          ),
                          question: 'Can this employee create estimates?',
                          value: _canCreateEstimates,
                          enabled: _canSeeEstimates,
                          onChanged: (value) =>
                              setState(() => _canCreateEstimates = value),
                        ),
                        _PermissionQuestion(
                          controlKey: const ValueKey(
                            'permission-approve-estimates',
                          ),
                          question: 'Can this employee approve estimates?',
                          value: _canApproveEstimates,
                          enabled: _canSeeEstimates,
                          onChanged: (value) =>
                              setState(() => _canApproveEstimates = value),
                        ),
                        _PermissionQuestion(
                          controlKey: const ValueKey(
                            'permission-record-expenses',
                          ),
                          question: 'Can this employee record expenses?',
                          value: _canRecordExpenses,
                          onChanged: (value) =>
                              setState(() => _canRecordExpenses = value),
                        ),
                        _PermissionQuestion(
                          controlKey: const ValueKey(
                            'permission-view-company-reports',
                          ),
                          question: 'Can this employee see company reports?',
                          value: _canViewCompanyReports,
                          onChanged: (value) =>
                              setState(() => _canViewCompanyReports = value),
                        ),
                        _PermissionQuestion(
                          controlKey: const ValueKey(
                            'permission-active-employee',
                          ),
                          question: 'Is this employee currently active?',
                          value: _active,
                          onChanged: (value) => setState(() => _active = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Save employee'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    ),
  );

  void _save() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop(
      _EmployeeProfile(
        id:
            widget.initial?.id ??
            'employee-${DateTime.now().microsecondsSinceEpoch}',
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        emergencyContact: _emergency.text.trim(),
        role: _role,
        pay: _pay.text.trim(),
        status: _active ? 'Available' : 'Former employee',
        active: _active,
        canSeeEstimates: _canSeeEstimates,
        canCreateEstimates: _canCreateEstimates,
        canApproveEstimates: _canApproveEstimates,
        canRecordExpenses: _canRecordExpenses,
        canViewCompanyReports: _canViewCompanyReports,
      ),
    );
  }
}

class _PermissionQuestion extends StatelessWidget {
  const _PermissionQuestion({
    required this.controlKey,
    required this.question,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final Key controlKey;
  final String question;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
    key: controlKey,
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final choices = SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Yes')),
            ButtonSegment(value: false, label: Text('No')),
          ],
          selected: {value},
          onSelectionChanged: enabled
              ? (selection) => onChanged(selection.first)
              : null,
        );
        if (AppLayoutEngine.stackFormFieldsFor(
          constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
        )) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(question),
              const SizedBox(height: 7),
              Align(alignment: Alignment.centerRight, child: choices),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: Text(question)),
            const SizedBox(width: 10),
            choices,
          ],
        );
      },
    ),
  );
}

class _EmployeeProfile {
  const _EmployeeProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.emergencyContact,
    required this.role,
    required this.pay,
    required this.status,
    this.active = true,
    this.canSeeEstimates = true,
    this.canCreateEstimates = false,
    this.canApproveEstimates = false,
    this.canRecordExpenses = true,
    this.canViewCompanyReports = false,
  });
  final String id;
  final String name;
  final String phone;
  final String emergencyContact;
  final String role;
  final String pay;
  final String status;
  final bool active;
  final bool canSeeEstimates;
  final bool canCreateEstimates;
  final bool canApproveEstimates;
  final bool canRecordExpenses;
  final bool canViewCompanyReports;
}

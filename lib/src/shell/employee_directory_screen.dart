import 'package:flutter/material.dart';

import '../data/prototype_operations_store.dart';
import '../data/work/directory_persistence_session.dart';
import '../data/work/employee_directory_demo.dart';
import '../data/work/employee_directory_profile.dart';
import 'employee_editor_screen.dart';

import '../layout/app_layout_engine.dart';
import '../shared/section_card.dart';

class EmployeeDirectoryScreen extends StatefulWidget {
  const EmployeeDirectoryScreen({super.key});

  @override
  State<EmployeeDirectoryScreen> createState() =>
      _EmployeeDirectoryScreenState();
}

class _EmployeeDirectoryScreenState extends State<EmployeeDirectoryScreen> {
  final _fixtureEmployees = [...demoEmployeeDirectoryProfiles];
  DirectoryPersistenceSession? get _directory =>
      PrototypeOperationsScope.maybeOf(context)?.directorySession;
  List<EmployeeDirectoryProfile> get _employees =>
      _directory?.employees ?? _fixtureEmployees;

  @override
  Widget build(BuildContext context) {
    final directory = _directory;
    if (directory != null && !directory.permissions.canViewEmployees) {
      return Scaffold(
        appBar: AppBar(title: const Text('Employees')),
        body: const Center(
          child: Text('Employee records are not available for this account.'),
        ),
      );
    }
    final canEdit = directory?.permissions.canManageEmployees ?? true;
    final active = _employees.where((employee) => employee.active).toList();
    final former = _employees.where((employee) => !employee.active).toList();
    return Scaffold(
      key: const ValueKey('employee-directory-screen'),
      appBar: AppBar(title: const Text('Employees')),
      floatingActionButton: !canEdit
          ? null
          : FloatingActionButton.extended(
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
                        'Keep active and former employee records. Pay and emergency contacts remain private company records.',
                      ),
                      const SizedBox(height: 14),
                      _EmployeeSection(
                        title: 'Active employees',
                        employees: active,
                        onEdit: canEdit ? _edit : null,
                      ),
                      const SizedBox(height: 12),
                      _EmployeeSection(
                        title: 'Former employees',
                        employees: former,
                        onEdit: canEdit ? _edit : null,
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

  Future<void> _edit([EmployeeDirectoryProfile? profile]) async {
    if (_directory != null && !_directory!.permissions.canManageEmployees) {
      return;
    }
    final updated = await Navigator.of(context).push<EmployeeDirectoryProfile>(
      MaterialPageRoute(builder: (_) => EmployeeEditorScreen(initial: profile)),
    );
    if (!mounted || updated == null) return;
    if (_directory != null) {
      setState(() {});
      return;
    }
    setState(() {
      final index = _fixtureEmployees.indexWhere(
        (employee) => employee.id == updated.id,
      );
      if (index < 0) {
        _fixtureEmployees.add(updated);
      } else {
        _fixtureEmployees[index] = updated;
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
  final List<EmployeeDirectoryProfile> employees;
  final ValueChanged<EmployeeDirectoryProfile>? onEdit;
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
              onTap: onEdit == null ? null : () => onEdit!(employee),
            ),
      ],
    ),
  );
}

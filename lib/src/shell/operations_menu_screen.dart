import '../shared/application_recovery_scope.dart';
import 'open_saved_work_recovery.dart';
import 'package:flutter/material.dart';

import '../screens/expenses/reports_screen.dart';
import '../data/prototype_operations_store.dart';
import '../screens/work/company_profile_screen.dart';
import '../screens/work/saved_clients_screen.dart';
import '../shared/app_preferences.dart';
import '../theme/app_theme.dart';
import 'employee_directory_screen.dart';
import 'vehicle_directory_screen.dart';

class OperationsMenuScreen extends StatelessWidget {
  const OperationsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('operations-menu-screen'),
      appBar: AppBar(title: const Text('Business menu')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          children: [
            const _MenuIntroduction(),
            const SizedBox(height: 14),
            _MenuSection(
              title: 'Company records',
              children: [
                _MenuDestination(
                  key: const ValueKey('menu-customers'),
                  icon: Icons.people_alt_outlined,
                  title: 'Customers',
                  detail: 'Contacts, service locations, and work history',
                  onTap: () {
                    final store = PrototypeOperationsScope.of(context);
                    _open(
                      context,
                      SavedClientsScreen(
                        initialClients: store.customers,
                        selectedDay: DateTime.now(),
                        onClientsChanged: store.replaceCustomers,
                      ),
                    );
                  },
                ),
                _MenuDestination(
                  key: const ValueKey('menu-company-profile'),
                  icon: Icons.business_outlined,
                  title: 'Company Profile',
                  detail: 'Business identity and document information',
                  onTap: () {
                    final store = PrototypeOperationsScope.of(context);
                    _open(
                      context,
                      CompanyProfileScreen(
                        initialProfile: store.companyProfile,
                        selectedDay: DateTime.now(),
                        onSaved: store.updateCompanyProfile,
                      ),
                    );
                  },
                ),
                if (PrototypeOperationsScope.maybeOf(
                      context,
                    )?.directorySession?.permissions.canViewEmployees ??
                    true)
                  _MenuDestination(
                    key: const ValueKey('menu-employees'),
                    icon: Icons.badge_outlined,
                    title: 'Employees',
                    detail: 'Active and former employees, roles, and access',
                    onTap: () =>
                        _open(context, const EmployeeDirectoryScreen()),
                  ),
                if (PrototypeOperationsScope.maybeOf(
                      context,
                    )?.directorySession?.permissions.canViewVehicles ??
                    true)
                  _MenuDestination(
                    key: const ValueKey('menu-vehicles'),
                    icon: Icons.local_shipping_outlined,
                    title: 'Vehicle profiles',
                    detail: 'Odometers, assignments, status, and records',
                    onTap: () => _open(context, const VehicleDirectoryScreen()),
                  ),
                _MenuDestination(
                  key: const ValueKey('menu-reports'),
                  icon: Icons.assessment_outlined,
                  title: 'Reports and recap',
                  detail: 'Income, expenses, margin, mileage, and trends',
                  onTap: () => _open(context, const ReportsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _MenuSection(
              title: 'Company setup',
              children: [
                _MenuDestination(
                  key: const ValueKey('menu-invite'),
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'Invite employees',
                  detail: 'Prepare a private invitation for a team member',
                  onTap: () => _open(context, const _InviteEmployeeScreen()),
                ),
                _MenuDestination(
                  key: const ValueKey('menu-system-settings'),
                  icon: Icons.settings_outlined,
                  title: 'System settings',
                  detail: 'Language, units, appearance, backup, and sync',
                  onTap: () => _open(context, const _SystemSettingsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _OfflineNote(),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));
}

class _MenuIntroduction extends StatelessWidget {
  const _MenuIntroduction();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Run your company',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 4),
      const Text(
        'Open company-wide records and settings. Settings for one screen stay on that screen.',
      ),
    ],
  );
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(AppRadii.surface),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        ...children,
      ],
    ),
  );
}

class _MenuDestination extends StatelessWidget {
  const _MenuDestination({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(detail),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote();

  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(AppRadii.control),
    ),
    leading: const Icon(Icons.offline_bolt_outlined),
    title: const Text('Works without an account'),
    subtitle: const Text(
      'An account is needed only for protected backup and company sync.',
    ),
  );
}

class _InviteEmployeeScreen extends StatelessWidget {
  const _InviteEmployeeScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Invite employees')),
    body: ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(
          'Invite a team member',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose the employee record and answer plain-language access questions before creating a private invitation.',
        ),
        const SizedBox(height: 16),
        const ListTile(
          leading: Icon(Icons.lock_outline),
          title: Text('No invitation has been created'),
          subtitle: Text(
            'No invitation link is created until protected company sync is configured.',
          ),
        ),
        FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Create invitation after sync is configured'),
        ),
      ],
    ),
  );
}

class _SystemSettingsScreen extends StatelessWidget {
  const _SystemSettingsScreen();

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferencesScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('System settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const ListTile(
            leading: Icon(Icons.language_outlined),
            title: Text('Language'),
            subtitle: Text(
              'English (United States). Spanish is the first required production translation.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.straighten_outlined),
            title: Text('Measurements'),
            subtitle: Text(
              'U.S. customary. Metric display and input remain a required production adapter.',
            ),
          ),
          ListTile(
            key: const ValueKey('system-appearance-setting'),
            leading: const Icon(Icons.contrast_outlined),
            title: const Text('Appearance'),
            subtitle: Text(_themeModeLabel(preferences.themeMode)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _openAppearance(context),
          ),
          ListTile(
            key: const ValueKey('system-saved-work'),
            leading: const Icon(Icons.restore_outlined),
            title: const Text('Saved work'),
            subtitle: Text(
              ApplicationRecoveryScope.maybeOf(context) == null
                  ? 'Saved work recovery is unavailable in this session'
                  : 'Continue or review unfinished work saved on this device',
            ),
            onTap: ApplicationRecoveryScope.maybeOf(context) == null
                ? null
                : () => openSavedWorkRecovery(context),
          ),
          const ListTile(
            leading: Icon(Icons.cloud_sync_outlined),
            title: Text('Backup and company sync'),
            subtitle: Text('Optional; local records work without an account'),
          ),
        ],
      ),
    );
  }

  void _openAppearance(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const _AppearanceSettingsScreen()),
  );
}

class _AppearanceSettingsScreen extends StatelessWidget {
  const _AppearanceSettingsScreen();

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferencesScope.of(context);
    return Scaffold(
      key: const ValueKey('appearance-settings-screen'),
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          const Text(
            'Choose how Tame Your Biz looks on this device. This does not change company records.',
          ),
          const SizedBox(height: 12),
          if (preferences.isSaving) const Text('Saving on this device…'),
          if (preferences.saveError != null) ...[
            Text(preferences.saveError!),
            if (preferences.canRetrySave)
              TextButton(
                onPressed: preferences.retrySave,
                child: const Text('Retry save'),
              ),
          ],
          for (final mode in ThemeMode.values)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                key: ValueKey('appearance-${mode.name}'),
                leading: Icon(_themeModeIcon(mode)),
                title: Text(_themeModeLabel(mode)),
                subtitle: Text(_themeModeDescription(mode)),
                trailing: preferences.themeMode == mode
                    ? const Icon(Icons.check_circle_rounded)
                    : null,
                selected: preferences.themeMode == mode,
                onTap: () => preferences.setThemeMode(mode),
              ),
            ),
        ],
      ),
    );
  }
}

String _themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Follow this device',
  ThemeMode.light => 'Light mode',
  ThemeMode.dark => 'Dark mode',
};

String _themeModeDescription(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Uses the current phone, tablet, or computer setting.',
  ThemeMode.light => 'Uses the blue-gray light workspace.',
  ThemeMode.dark => 'Uses the layered charcoal workspace.',
};

IconData _themeModeIcon(ThemeMode mode) => switch (mode) {
  ThemeMode.system => Icons.devices_outlined,
  ThemeMode.light => Icons.light_mode_outlined,
  ThemeMode.dark => Icons.dark_mode_outlined,
};

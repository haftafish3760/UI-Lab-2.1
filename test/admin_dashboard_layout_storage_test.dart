import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'Layout survives database reopening and rejects missing calendar',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final database = await harness.open();
      final repository = await LocalAppPreferencesStore.open(database);
      final controller = AppPreferencesController(storage: repository);
      expect(
        await controller.setAdminDashboardWidgets([
          'calendar',
          'payments',
          'work',
        ]),
        isTrue,
      );
      expect(
        () => controller.setAdminDashboardWidgets(['work']),
        throwsArgumentError,
      );
    controller.dispose();
      await harness.close(database);
      final reopened = await LocalAppPreferencesStore.open(
        await harness.open(),
      );
      final restored = AppPreferencesController(storage: reopened);
      addTearDown(restored.dispose);
      expect(restored.adminDashboardWidgets, ['calendar', 'payments', 'work']);
    },
  );
}

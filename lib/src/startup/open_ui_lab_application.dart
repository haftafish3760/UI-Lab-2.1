import 'package:flutter/foundation.dart';
import '../data/work/work_review_examples.dart';
import 'dart:io';
import '../data/notifications/native_notification_gateway.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import 'application_media_coordinator.dart';
import '../data/storage/native_device_media_gateway.dart';
import '../data/receipts/receipt_draft_ui_lab_policy.dart';
import '../data/work/work_persistence_session.dart';
import '../data/work/directory_persistence_session.dart';
import '../data/workday/workday_persistence_session.dart';
import '../data/day_notes/day_note_persistence_session.dart';
import '../data/storage/local_app_preferences_store.dart';
import '../data/storage/local_persistence.dart';
import '../data/storage/application_storage_lifecycle.dart';
import '../data/storage/serialized_async_actions.dart';
import '../data/storage/selected_local_installation.dart';
import '../data/work/work_ui_lab_bootstrap.dart';
import '../data/work/directory_ui_lab_bootstrap.dart';
import '../data/workday/workday_ui_lab_bootstrap.dart';
import '../data/day_notes/day_note_ui_lab_bootstrap.dart';

Future<Widget> openUiLabApplication({
  Directory? storageDirectory,
  String Function(String)? resolveRetainedPath,
  required NativeNotificationGateway nativeNotifications,
}) async {
  // Native reminders initialize after mounting, independently of local storage.
  LocalPersistence? persistence;
  WorkPersistenceSession? workSession;
  DirectoryPersistenceSession? directory;
  WorkdayPersistenceSession? workday;
  DayNotePersistenceSession? dayNotes;
  try {
    final selected = await SelectedLocalInstallation.resolve(
      storageDirectory ?? await LocalPersistence.defaultDirectory(),
    );
    storageDirectory = selected.directory;
    resolveRetainedPath = selected.resolveRetainedPath ?? resolveRetainedPath;
    persistence = await LocalPersistence.open(
      directory: storageDirectory,
      resolveRetainedPath: resolveRetainedPath,
      removeOwnerDemoData: false,
    );
    await persistence.seedDemoIfNew();
    if (kDebugMode && const bool.fromEnvironment('UI_LAB_REVIEW_EXAMPLES', defaultValue: true)) {
      await loadRequestedWorkExamples(persistence.database);
    }
    workSession = await openUiLabWorkSession(persistence.database);
    directory = await openUiLabDirectory(persistence.database);
    workday = await openUiLabWorkdaySession(persistence.database);
    dayNotes = await openUiLabDayNotes(persistence.database);
    final preferences = await LocalAppPreferencesStore.open(
      persistence.database,
    );
    final activePersistence = persistence;
    final activeWork = workSession;
    final activeDirectory = directory;
    final activeWorkday = workday;
    final activeNotes = dayNotes;
    final lifecycle = ApplicationStorageLifecycle(
      pauseDomainSources: () async {
        final lease = await pauseOperationSources([
          activeWork.pauseOperations,
          activeDirectory.pauseOperations,
          activeWorkday.pauseOperations,
          activeNotes.pauseOperations,
        ]);
        return lease.release;
      },
      pauseDrafts: () async {
        final lease = await activePersistence.database.draftSessions
            .pauseAndFlush();
        return lease.release;
      },
      pauseStorage: () async {
        final lease = await pauseOperationSources([
          preferences.pauseOperations,
          activePersistence.pauseOperations,
        ]);
        return lease.release;
      },
      closeStorage: () async {
        activeNotes.dispose();
        activeWorkday.dispose();
        activeDirectory.dispose();
        activeWork.dispose();
        await activePersistence.close();
      },
    );
    return UiLabApp(
      storageLifecycle: lifecycle,
      expenseRepository: persistence.expenses,
      recurringExpenseRepository: persistence.recurringExpenses,
      receiptDraftRepository: persistence.receiptDrafts,
      notificationRepository: persistence.notifications,
      nativeNotificationGateway: nativeNotifications,
      mediaCoordinator: createApplicationMediaCoordinator(
        database: persistence.database,
        gateway: NativeDeviceMediaGateway(),
        receiptPermissions: receiptDraftUiLabOwnerPermissions(),
        receipts: persistence.receiptDrafts,
        work: workSession,
      ),
      workSession: workSession,
      workdaySession: workday,
      dayNoteSession: dayNotes,
      directorySession: directory,
      draftStore: persistence.drafts,
      preferencesStore: preferences,
      resolveRetainedPath: resolveRetainedPath,
    );
  } on Object {
    dayNotes?.dispose();
    workday?.dispose();
    directory?.dispose();
    workSession?.dispose();
    await persistence?.close();
    rethrow;
  }
}

/// Only for a completed load that was never mounted; no editors can be writing.
Future<void> closeUnstartedApplication(Widget application) async {
  if (application is! UiLabApp) return;
  if (application.storageLifecycle case final lifecycle?) {
    await lifecycle.close();
    return;
  }
  application.dayNoteSession?.dispose();
  application.workdaySession?.dispose();
  application.directorySession?.dispose();
  final work = application.workSession;
  work?.dispose();
  await work?.repository.database.close();
}

import 'shared/documents/document_image_scope.dart';
import 'data/work/company_document_branding.dart';
import 'shared/documents/customer_portal_gateway.dart';
import 'startup/application_route_pause.dart';
import 'data/storage/application_storage_lifecycle.dart';
import 'data/storage/serialized_async_actions.dart';
import 'shared/local_document_path_scope.dart';
import 'shared/application_recovery_scope.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'data/expenses/authorized_expense_service.dart';
import 'data/expenses/local_expense_repository.dart';
import 'data/expenses/local_recurring_expense_repository.dart';
import 'data/expenses/atomic_recurring_expense_payment.dart';
import 'data/expenses/recurring_payment_session.dart';
import 'data/receipts/local_receipt_draft_repository.dart';
import 'data/receipts/atomic_receipt_submission.dart';
import 'data/receipts/receipt_submission_session.dart';
import 'data/expenses/expense_repository.dart';
import 'data/expenses/expense_ui_lab_policy.dart';
import 'data/expenses/expense_ui_repository_bridge.dart';
import 'data/expenses/expense_ui_repository_controller.dart';
import 'data/expenses/authorized_recurring_expense_service.dart';
import 'data/expenses/recurring_expense_repository.dart';
import 'data/expenses/recurring_expense_ui_controller.dart';
import 'data/expenses/recurring_expense_ui_lab_policy.dart';
import 'data/notifications/authorized_notification_service.dart';
import 'data/notifications/file_notification_repository.dart';
import 'data/notifications/native_notification_delivery_coordinator.dart';
import 'data/notifications/native_notification_gateway.dart';
import 'data/notifications/native_notification_ui_controller.dart';
import 'data/notifications/notification_demo_policy.dart';
import 'data/notifications/notification_repository.dart';
import 'data/notifications/notification_ui_controller.dart';
import 'data/notifications/recurring_expense_notification_publisher.dart';
import 'data/prototype_operations_store.dart';
import 'data/storage/draft_repository.dart';
import 'data/storage/native_media_picker_coordinator.dart';
import 'data/receipts/receipt_media_session.dart';
import 'data/work/work_persistence_session.dart';
import 'data/workday/workday_persistence_session.dart';
import 'data/day_notes/day_note_persistence_session.dart';
import 'data/work/directory_persistence_session.dart';
import 'data/receipts/authorized_receipt_draft_service.dart';
import 'data/receipts/receipt_draft_repository.dart';
import 'data/receipts/receipt_draft_ui_controller.dart';
import 'data/receipts/receipt_draft_ui_lab_policy.dart';
import 'screens/dashboard/notification_source_route.dart';
import 'screens/expenses/expense_permissions.dart';
import 'shared/app_preferences.dart';
import 'data/storage/app_preferences_repository.dart';
import 'shared/local_draft_scope.dart';
import 'shared/native_media_picker_scope.dart';
import 'startup/application_media_coordinator.dart';
import 'shared/operational_scope.dart';
import 'shared/workday_recovery_notice.dart';
import 'shell/app_shell.dart';
import 'theme/app_theme.dart';

part 'application_data_scopes.dart';
part 'application_service_lifecycle.dart';

class UiLabApp extends StatefulWidget {
  const UiLabApp({
    this.expenseRepository,
    this.recurringExpenseRepository,
    this.receiptDraftRepository,
    this.notificationRepository,
    this.nativeNotificationGateway,
    this.mediaCoordinator,
    this.workSession,
    this.customerPortal,
    this.workdaySession,
    this.dayNoteSession,
    this.directorySession,
    this.draftStore,
    this.preferencesStore,
    this.resolveRetainedPath,
    this.storageLifecycle,
    super.key,
  });

  final String Function(String)? resolveRetainedPath;
  final ApplicationStorageLifecycle? storageLifecycle;
  final ExpenseRepository? expenseRepository;
  final RecurringExpenseRepository? recurringExpenseRepository;
  final ReceiptDraftRepository? receiptDraftRepository;
  final NotificationRepository? notificationRepository;
  final NativeNotificationGateway? nativeNotificationGateway;
  final NativeMediaPickerCoordinator? mediaCoordinator;
  final WorkPersistenceSession? workSession;
  final CustomerPortalGateway? customerPortal;
  final WorkdayPersistenceSession? workdaySession;
  final DayNotePersistenceSession? dayNoteSession;
  final DirectoryPersistenceSession? directorySession;
  final DraftRepository? draftStore;
  final AppPreferencesRepository? preferencesStore;

  @override
  State<UiLabApp> createState() => _UiLabAppState();
}

class _UiLabAppState extends State<UiLabApp> {
  late final OperationalScopeController _scope;
  late final AppPreferencesController _preferences;
  late final PrototypeOperationsStore _operationsStore;
  late final ExpenseUiRepositoryController? _expenseController;
  late final RecurringExpenseUiController? _recurringExpenseController;
  ReceiptDraftUiController? _receiptDraftController;
  ReceiptSubmissionSession? _receiptSubmission;
  NativeMediaPickerCoordinator? _mediaCoordinator;
  RecurringPaymentSession? _recurringPayment;
  late final RecurringExpenseNotificationPublisher _notificationPublisher;
  late final NotificationUiController _notificationController;
  late final NativeNotificationGateway _nativeNotificationGateway;
  late final NativeNotificationDeliveryCoordinator
  _nativeNotificationCoordinator;
  late final NativeNotificationUiController _nativeNotificationController;
  late final StreamSubscription<String> _nativeNotificationTapSubscription;
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _routePause = ApplicationRoutePause();
  final _notificationSourceActions = SerializedAsyncActions();
  final _notificationTapActions = SerializedAsyncActions();
  Future<void> _initialSourceSettled = Future.value();
  bool _servicesSuspended = false, _deferredSourceChange = false;
  void Function()? _detachStorageLifecycle;
  int _lastRecurringNotificationRevision = -1;
  int _pendingRecurringNotificationRevision = -1;
  bool _recurringNotificationSourceInitialized = false;

  @override
  void initState() {
    super.initState();
    _scope = OperationalScopeController(workdaySession: widget.workdaySession);
    _preferences = AppPreferencesController(storage: widget.preferencesStore);
    _operationsStore = PrototypeOperationsStore(
      workSession: widget.workSession,
      workdaySession: widget.workdaySession,
      dayNoteSession: widget.dayNoteSession,
      directorySession: widget.directorySession,
    );
    final expenseRepository = widget.expenseRepository;
    _expenseController = expenseRepository == null
        ? null
        : ExpenseUiRepositoryController(
            ExpenseUiRepositoryBridge(
              service: AuthorizedExpenseService(expenseRepository),
              employeeLabelForId: expenseUiLabEmployeeLabel,
              jobLabelForId: (jobId) =>
                  expenseUiLabJobLabel(jobId, _operationsStore.workRecords),
            ),
            expenseUiLabOwnerPermissions(),
            drafts: widget.draftStore,
            recoveredFromDamagedSnapshot: expenseRepositoryRecoveredFromDamage(
              expenseRepository,
            ),
          );
    final expenseController = _expenseController;
    if (expenseController != null) {
      _operationsStore.bindAuthorizedExpenseController(expenseController);
      unawaited(expenseController.load());
    }
    final recurringRepository = widget.recurringExpenseRepository;
    _recurringExpenseController = recurringRepository == null
        ? null
        : RecurringExpenseUiController(
            AuthorizedRecurringExpenseService(recurringRepository),
            recurringExpenseUiLabOwnerPermissions(),
            expenseUiLabEmployeeLabel,
            drafts: widget.draftStore,
            recoveredFromDamagedSnapshot:
                recurringExpenseRepositoryRecoveredFromDamage(
                  recurringRepository,
                ),
          );
    final recurringController = _recurringExpenseController;
    final recurringReady = recurringController?.load() ?? Future.value(true);
    if (expenseRepository is LocalExpenseRepository &&
        recurringRepository is LocalRecurringExpenseRepository &&
        expenseRepository.supportsDraftConfirmation &&
        recurringRepository.supportsDraftConfirmation &&
        expenseController != null &&
        recurringController != null) {
      _recurringPayment = RecurringPaymentSession(
        drafts: widget.draftStore,
        service: AtomicRecurringExpensePayment(
          expenses: expenseRepository,
          recurringExpenses: recurringRepository,
          employeeLabelForId: expenseUiLabEmployeeLabel,
        ),
        expenses: expenseController,
        recurringExpenses: recurringController,
        expensePermissions: expenseUiLabOwnerPermissions(),
        recurringPermissions: recurringExpenseUiLabOwnerPermissions(),
      );
    }

    final receiptDraftRepository = widget.receiptDraftRepository;
    _receiptDraftController = receiptDraftRepository == null
        ? null
        : ReceiptDraftUiController(
            AuthorizedReceiptDraftService(receiptDraftRepository),
            receiptDraftUiLabOwnerPermissions(),
            recoveredFromDamagedSnapshot:
                receiptDraftRepositoryRecoveredFromDamage(
                  receiptDraftRepository,
                ),
          );
    final receiptDraftController = _receiptDraftController;
    if (receiptDraftController != null) {
      unawaited(receiptDraftController.load());
    }
    _mediaCoordinator = widget.mediaCoordinator;
    if (expenseRepository is LocalExpenseRepository &&
        receiptDraftRepository is LocalReceiptDraftRepository &&
        expenseRepository.supportsDraftConfirmation &&
        receiptDraftRepository.supportsAtomicSubmission &&
        expenseController != null &&
        receiptDraftController != null) {
      _receiptSubmission = ReceiptSubmissionSession(
        drafts: widget.draftStore,
        media: _mediaCoordinator == null
            ? null
            : ReceiptMediaSession(
                coordinator: _mediaCoordinator!,
                repository: receiptDraftRepository,
                receipts: receiptDraftController,
                permissions: receiptDraftUiLabOwnerPermissions(),
              ),
        service: AtomicReceiptSubmission(
          expenses: expenseRepository,
          receiptDrafts: receiptDraftRepository,
          employeeLabelForId: expenseUiLabEmployeeLabel,
          jobLabelForId: (id) =>
              expenseUiLabJobLabel(id, _operationsStore.workRecords),
        ),
        expenses: expenseController,
        receipts: receiptDraftController,
        expensePermissions: expenseUiLabOwnerPermissions(),
        receiptPermissions: receiptDraftUiLabOwnerPermissions(),
      );
    }
    final repository =
        widget.notificationRepository ?? FileNotificationRepository.transient();
    final service = AuthorizedNotificationService(repository);
    _nativeNotificationGateway =
        widget.nativeNotificationGateway ??
        const UnsupportedNativeNotificationGateway();
    _notificationPublisher = RecurringExpenseNotificationPublisher(
      service,
      () =>
          recurringController?.records ??
          _operationsStore.expenseStore.scheduledExpenses.toList(),
      () =>
          recurringController?.occurrences ??
          _operationsStore.expenseStore.scheduledExpenseOccurrences.toList(),
    );
    final sourceReady = recurringReady.then(
      (_) => _initializeNotificationSources(recurringController),
    );
    _initialSourceSettled = sourceReady.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _notificationController = NotificationUiController(
      service,
      demoNotificationUserPermissions(),
      sourceReady,
    );
    _nativeNotificationCoordinator = NativeNotificationDeliveryCoordinator(
      service,
      demoNotificationPublisherPermissions(),
      _nativeNotificationGateway,
    );
    _nativeNotificationController = NativeNotificationUiController(
      _nativeNotificationGateway,
      _nativeNotificationCoordinator,
      () => _preferences.language.locale,
      sourceReady,
    );
    _nativeNotificationTapSubscription = _nativeNotificationGateway
        .tappedPayloads
        .listen(_openNativeNotification);
    unawaited(_notificationController.load(availableAt: DateTime.now()));
    unawaited(_nativeNotificationController.load());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openInitialNativeNotification());
      if (mounted) {
        final media = _mediaCoordinator;
        if (media != null) {
          final permissions = receiptDraftUiLabOwnerPermissions();
          unawaited(
            _receiptSubmission?.media?.recoverAtStartup() ??
                recoverApplicationMedia(
                  media,
                  organizationId:
                      widget.workSession?.permissions.organizationId ??
                      permissions.organizationId,
                  ownerId:
                      widget.workSession?.permissions.actorEmployeeId ??
                      permissions.actorEmployeeId,
                ),
          );
        }
      }
    });
    _detachStorageLifecycle = widget.storageLifecycle?.attach(
      _pauseApplicationServices,
    );
    if (recurringController == null) {
      _operationsStore.expenseStore.addListener(_onNotificationSourceChanged);
    } else {
      recurringController.addListener(_onNotificationSourceChanged);
    }
  }

  Future<void> _synchronizeNotificationSources() => _notificationSourceActions
      .run(() => _notificationPublisher.synchronize(asOf: DateTime.now()));

  Future<void> _initializeNotificationSources(
    RecurringExpenseUiController? recurringController,
  ) async {
    try {
      await _synchronizeNotificationSources();
      _lastRecurringNotificationRevision =
          recurringController?.sourceRevision ?? -1;
    } finally {
      _recurringNotificationSourceInitialized = true;
    }
  }

  void _onNotificationSourceChanged() {
    if (_servicesSuspended) {
      _deferredSourceChange = true;
      return;
    }
    final recurringController = _recurringExpenseController;
    if (recurringController != null) {
      if (!_recurringNotificationSourceInitialized ||
          recurringController.sourceRevision <=
              _lastRecurringNotificationRevision ||
          recurringController.sourceRevision ==
              _pendingRecurringNotificationRevision) {
        return;
      }
      _pendingRecurringNotificationRevision =
          recurringController.sourceRevision;
    }
    final sourceReady = _synchronizeNotificationSources();
    _notificationController.sourceChanged(sourceReady);
    _nativeNotificationController.sourceChanged(sourceReady);
    unawaited(
      _completeNotificationSourceChange(
        sourceReady,
        recurringController?.sourceRevision,
      ),
    );
  }

  Future<void> _openInitialNativeNotification() async {
    final payload = await _nativeNotificationController.takeLaunchPayload();
    if (mounted && payload != null) await _openNativeNotification(payload);
  }

  Future<void> _openNativeNotification(String notificationId) async {
    if (_servicesSuspended || !mounted) return;
    return _notificationTapActions.run(
      () => _deliverNativeNotification(notificationId),
    );
  }

  Future<void> _deliverNativeNotification(String notificationId) async {
    final event = await _notificationController.eventForOpen(notificationId);
    if (event == null || !mounted) return;
    await _nativeNotificationCoordinator.recordOpened(
      notificationId: notificationId,
      occurredAtUtc: DateTime.now().toUtc(),
    );
    if (!mounted) return;
    final route = notificationSourceRoute(
      event,
      expensePermissions: const ExpensePermissions.development(),
    );
    final navigator = _navigatorKey.currentState;
    if (route != null && navigator != null && !_servicesSuspended) {
      unawaited(navigator.push(route));
    }
  }

  Future<void> _completeNotificationSourceChange(
    Future<void> sourceReady,
    int? recurringRevision,
  ) async {
    try {
      await sourceReady;
      if (recurringRevision != null &&
          recurringRevision > _lastRecurringNotificationRevision) {
        _lastRecurringNotificationRevision = recurringRevision;
      }
    } on Object {
      // NotificationUiController exposes the retryable load failure.
    } finally {
      if (recurringRevision == _pendingRecurringNotificationRevision) {
        _pendingRecurringNotificationRevision = -1;
      }
    }
  }

  @override
  void dispose() {
    _routePause.dispose();
    _detachStorageLifecycle?.call();
    _receiptSubmission?.media?.dispose();
    _scope.dispose();
    _preferences.dispose();
    _recurringPayment?.dispose();
    _expenseController?.dispose();
    _receiptDraftController?.dispose();
    final recurringController = _recurringExpenseController;
    if (recurringController == null) {
      _operationsStore.expenseStore.removeListener(
        _onNotificationSourceChanged,
      );
    } else {
      recurringController.removeListener(_onNotificationSourceChanged);
      recurringController.dispose();
    }
    _notificationController.dispose();
    _nativeNotificationTapSubscription.cancel();
    _nativeNotificationController.dispose();
    _operationsStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _preferences,
      builder: (context, _) => MaterialApp(
        navigatorKey: _navigatorKey,
        navigatorObservers: [_routePause],
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _preferences.themeMode,
        locale: _preferences.language.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLanguage.values
            .map((language) => language.locale)
            .toList(growable: false),
        builder: (context, child) => AppPreferencesScope(
          controller: _preferences,
          child: NativeNotificationUiScope(
            controller: _nativeNotificationController,
            child: NotificationUiScope(
              controller: _notificationController,
              child: _buildDataScopes(
                OperationalScope(
                  controller: _scope,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
        home: const AppShell(),
      ),
    );
  }
}

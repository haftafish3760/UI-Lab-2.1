import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'data/expenses/authorized_expense_service.dart';
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
import 'data/receipts/authorized_receipt_draft_service.dart';
import 'data/receipts/receipt_draft_repository.dart';
import 'data/receipts/receipt_draft_ui_controller.dart';
import 'data/receipts/receipt_draft_ui_lab_policy.dart';
import 'screens/dashboard/notification_source_route.dart';
import 'screens/expenses/expense_permissions.dart';
import 'shared/app_preferences.dart';
import 'shared/operational_scope.dart';
import 'shell/app_shell.dart';
import 'theme/app_theme.dart';

class UiLabApp extends StatefulWidget {
  const UiLabApp({
    this.expenseRepository,
    this.recurringExpenseRepository,
    this.receiptDraftRepository,
    this.notificationRepository,
    this.nativeNotificationGateway,
    super.key,
  });

  final ExpenseRepository? expenseRepository;
  final RecurringExpenseRepository? recurringExpenseRepository;
  final ReceiptDraftRepository? receiptDraftRepository;
  final NotificationRepository? notificationRepository;
  final NativeNotificationGateway? nativeNotificationGateway;

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
  late final RecurringExpenseNotificationPublisher _notificationPublisher;
  late final NotificationUiController _notificationController;
  late final NativeNotificationGateway _nativeNotificationGateway;
  late final NativeNotificationDeliveryCoordinator
  _nativeNotificationCoordinator;
  late final NativeNotificationUiController _nativeNotificationController;
  late final StreamSubscription<String> _nativeNotificationTapSubscription;
  final _navigatorKey = GlobalKey<NavigatorState>();
  int _lastRecurringNotificationRevision = -1;
  int _pendingRecurringNotificationRevision = -1;
  bool _recurringNotificationSourceInitialized = false;

  @override
  void initState() {
    super.initState();
    _scope = OperationalScopeController();
    _preferences = AppPreferencesController();
    _operationsStore = PrototypeOperationsStore();
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
            recoveredFromDamagedSnapshot:
                recurringExpenseRepositoryRecoveredFromDamage(
                  recurringRepository,
                ),
          );
    final recurringController = _recurringExpenseController;
    final recurringReady = recurringController?.load() ?? Future.value(true);
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
    });
    if (recurringController == null) {
      _operationsStore.expenseStore.addListener(_onNotificationSourceChanged);
    } else {
      recurringController.addListener(_onNotificationSourceChanged);
    }
  }

  Future<void> _synchronizeNotificationSources() =>
      _notificationPublisher.synchronize(asOf: DateTime.now());

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
    final payload = await _nativeNotificationGateway.takeLaunchPayload();
    if (payload != null) await _openNativeNotification(payload);
  }

  Future<void> _openNativeNotification(String notificationId) async {
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
    if (route != null && navigator != null) await navigator.push(route);
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
    _scope.dispose();
    _preferences.dispose();
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

  Widget _buildDataScopes(Widget child) {
    Widget scoped = PrototypeOperationsScope(
      store: _operationsStore,
      child: child,
    );
    final recurringController = _recurringExpenseController;
    if (recurringController != null) {
      scoped = RecurringExpenseUiScope(
        controller: recurringController,
        child: scoped,
      );
    }
    final receiptDraftController = _receiptDraftController;
    if (receiptDraftController != null) {
      scoped = ReceiptDraftUiScope(
        controller: receiptDraftController,
        child: scoped,
      );
    }
    final expenseController = _expenseController;
    if (expenseController == null) return scoped;
    return ExpenseUiScope(controller: expenseController, child: scoped);
  }
}

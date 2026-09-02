// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Maintainiac UI Lab 2.1';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navDashboardCompact => 'Inicio';

  @override
  String get navWork => 'Trabajo';

  @override
  String get navExpenses => 'Gastos';

  @override
  String get navInventory => 'Materiales';

  @override
  String get navMaintenance => 'Mantenimiento';

  @override
  String get fieldRecords => 'Registros de campo';

  @override
  String get offlineRecordsAvailable =>
      'Los registros siguen disponibles sin conexión.';

  @override
  String get advertisementPlaceholder => 'Espacio publicitario de muestra';

  @override
  String get advertisement => 'PUBLICIDAD';

  @override
  String get sampleAdSpace => 'Espacio publicitario';

  @override
  String get demo => 'Demostración';

  @override
  String get operationalViewLabel => 'Vista';

  @override
  String operationalViewValue(String view) {
    return 'Vista: $view';
  }

  @override
  String get operationalChangeViewTooltip => 'Cambiar vista';

  @override
  String get operationalChangeContextTooltip => 'Cambiar contexto de trabajo';

  @override
  String operationalContextSemantics(String context, String value) {
    return '$context: $value';
  }

  @override
  String get operationalViewTechnician => 'Técnico';

  @override
  String get operationalViewAdmin => 'Administrador';

  @override
  String get operationalContextEmployee => 'Empleado';

  @override
  String get operationalContextVehicle => 'Vehículo';

  @override
  String get operationalContextActiveVehicle => 'Vehículo activo';

  @override
  String get operationalCompanyOverview => 'Resumen de la empresa';

  @override
  String get operationalFleetOverview => 'Resumen de la flota';

  @override
  String get operationalPreviousDay => 'Día anterior';

  @override
  String get operationalNextDay => 'Día siguiente';

  @override
  String get operationalReturnToToday => 'Volver a hoy';

  @override
  String operationalUnreadNotifications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notificaciones. $count elementos sin leer.',
      one: 'Notificaciones. 1 elemento sin leer.',
      zero: 'Notificaciones. Nada nuevo.',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsHeading => 'Recordatorios y novedades';

  @override
  String get notificationsDescription =>
      'Las notificaciones muestran recordatorios y novedades. Las decisiones permanecen en Necesita atención.';

  @override
  String get nativeReminderTitle => 'Recordatorio de Maintainiac';

  @override
  String get nativeReminderBody =>
      'Abra Maintainiac para revisar un recordatorio programado.';

  @override
  String get deviceRemindersOffTitle =>
      'Los recordatorios del dispositivo están desactivados';

  @override
  String get deviceRemindersOffBody =>
      'Los recordatorios dentro de la aplicación siguen funcionando. Active las notificaciones del dispositivo para recibir recordatorios cuando Maintainiac esté cerrado.';

  @override
  String get deviceRemindersEnable => 'Activar recordatorios del dispositivo';

  @override
  String get deviceRemindersEnabling =>
      'Activando recordatorios del dispositivo';

  @override
  String get deviceRemindersDenied =>
      'Los recordatorios del dispositivo siguen desactivados. Puede permitir las notificaciones de Maintainiac en la configuración del sistema.';

  @override
  String get deviceRemindersFailed =>
      'No se pudieron actualizar los recordatorios del dispositivo. Inténtelo de nuevo.';

  @override
  String get notificationsMarkAllRead => 'Marcar todo como leído';

  @override
  String get notificationsEmpty =>
      'No hay recordatorios ni novedades disponibles.';

  @override
  String get notificationsLoadFailed =>
      'No se pudieron cargar las notificaciones.';

  @override
  String get notificationUnreadState => 'Sin leer';

  @override
  String get notificationReadState => 'Leída';

  @override
  String get notificationDueToday => 'Vence hoy';

  @override
  String get notificationDueTomorrow => 'Vence mañana';

  @override
  String notificationDueInDays(int count) {
    return 'Vence en $count días';
  }

  @override
  String notificationDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días de atraso',
      one: '1 día de atraso',
    );
    return '$_temp0';
  }

  @override
  String operationalNotificationsAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notificaciones. $count elementos necesitan atención.',
      one: 'Notificaciones. 1 elemento necesita atención.',
      zero: 'Notificaciones. Nada necesita atención.',
    );
    return '$_temp0';
  }

  @override
  String get attentionTitle => 'Necesita atención';

  @override
  String attentionShowAll(int count) {
    return 'Ver todo ($count)';
  }

  @override
  String get attentionDismiss => 'Descartar Necesita atención';

  @override
  String get attentionNothing => 'Nada necesita atención en este momento.';

  @override
  String get reportToday => 'Hoy';

  @override
  String get reportThisWeek => 'Esta semana';

  @override
  String get reportThisMonth => 'Este mes';

  @override
  String get reportThisCalendarQuarter => 'Este trimestre';

  @override
  String get reportPreviousCalendarQuarter => 'Trimestre anterior';

  @override
  String get reportPrevious90Days => '90 días anteriores';

  @override
  String get reportYearToDate => 'Año hasta la fecha';

  @override
  String get reportPrevious12Months => '12 meses anteriores';

  @override
  String get calendarMonthView => 'Mes';

  @override
  String get calendarWeekView => 'Semana';

  @override
  String get calendarPreviousMonth => 'Mes anterior';

  @override
  String get calendarNextMonth => 'Mes siguiente';

  @override
  String get calendarPreviousWeek => 'Semana anterior';

  @override
  String get calendarNextWeek => 'Semana siguiente';

  @override
  String get calendarChooseWorkDate => 'Elija una fecha de trabajo';

  @override
  String get calendarMondayShort => 'lun.';

  @override
  String get calendarTuesdayShort => 'mar.';

  @override
  String get calendarWednesdayShort => 'mié.';

  @override
  String get calendarThursdayShort => 'jue.';

  @override
  String get calendarFridayShort => 'vie.';

  @override
  String get calendarSaturdayShort => 'sáb.';

  @override
  String get calendarSundayShort => 'dom.';

  @override
  String get calendarTodayState => 'Hoy.';

  @override
  String get calendarOutsideMonthState => 'Fuera del mes seleccionado.';

  @override
  String get calendarNeedsApprovalState => 'Necesita aprobación.';

  @override
  String get calendarRecordSingular => 'registro';

  @override
  String get calendarRecordPlural => 'registros';

  @override
  String get calendarDashboardEntrySingular => 'entrada del panel';

  @override
  String get calendarDashboardEntryPlural => 'entradas del panel';

  @override
  String get calendarWorkRecordSingular => 'registro de trabajo';

  @override
  String get calendarWorkRecordPlural => 'registros de trabajo';

  @override
  String get calendarJobSingular => 'trabajo';

  @override
  String get calendarJobPlural => 'trabajos';

  @override
  String get calendarEstimateSingular => 'presupuesto';

  @override
  String get calendarEstimatePlural => 'presupuestos';

  @override
  String get calendarInvoiceSingular => 'factura';

  @override
  String get calendarInvoicePlural => 'facturas';

  @override
  String get calendarPaymentSingular => 'pago';

  @override
  String get calendarPaymentPlural => 'pagos';

  @override
  String get calendarExpenseSingular => 'gasto';

  @override
  String get calendarExpensePlural => 'gastos';

  @override
  String get calendarInventoryRecordSingular => 'registro de materiales';

  @override
  String get calendarInventoryRecordPlural => 'registros de materiales';

  @override
  String calendarNoRecords(String recordLabel) {
    return 'No hay $recordLabel.';
  }

  @override
  String calendarRecordCount(int count, String recordLabel) {
    return '$count $recordLabel.';
  }
}

/// The translations for Spanish Castilian, as used in the United States (`es_US`).
class AppLocalizationsEsUs extends AppLocalizationsEs {
  AppLocalizationsEsUs() : super('es_US');

  @override
  String get appTitle => 'Maintainiac UI Lab 2.1';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navWork => 'Trabajo';

  @override
  String get navExpenses => 'Gastos';

  @override
  String get navInventory => 'Materiales';

  @override
  String get navMaintenance => 'Mantenimiento';

  @override
  String get fieldRecords => 'Registros de campo';

  @override
  String get offlineRecordsAvailable =>
      'Los registros siguen disponibles sin conexión.';

  @override
  String get advertisementPlaceholder => 'Espacio publicitario de muestra';

  @override
  String get advertisement => 'PUBLICIDAD';

  @override
  String get sampleAdSpace => 'Espacio publicitario';

  @override
  String get demo => 'Demostración';

  @override
  String get calendarMonthView => 'Mes';

  @override
  String get calendarWeekView => 'Semana';

  @override
  String get calendarPreviousMonth => 'Mes anterior';

  @override
  String get calendarNextMonth => 'Mes siguiente';

  @override
  String get calendarPreviousWeek => 'Semana anterior';

  @override
  String get calendarNextWeek => 'Semana siguiente';

  @override
  String get calendarChooseWorkDate => 'Elija una fecha de trabajo';

  @override
  String get calendarTodayState => 'Hoy.';

  @override
  String get calendarOutsideMonthState => 'Fuera del mes seleccionado.';

  @override
  String get calendarNeedsApprovalState => 'Necesita aprobación.';

  @override
  String calendarNoRecords(String recordLabel) {
    return 'No hay $recordLabel.';
  }

  @override
  String calendarRecordCount(int count, String recordLabel) {
    return '$count $recordLabel.';
  }
}

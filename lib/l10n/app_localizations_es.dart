// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get selectVehicleLabel => 'Seleccionar vehículo';

  @override
  String get appTitle => 'Tame Your Biz';

  @override
  String get navDashboard => 'Panel';

  @override
  String get dashboardOdometerLabel => 'Odómetro';

  @override
  String get dashboardStartWorkday => 'Iniciar jornada';

  @override
  String get dashboardPaymentsLabel => 'Cobros';

  @override
  String get dashboardMilesLabel => 'Millas';

  @override
  String get dashboardMileageUnavailable =>
      'Los totales de millas de negocio aún no están conectados en esta vista previa. No se ha supuesto un total de cero.';

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
  String get nativeReminderTitle => 'Recordatorio de Tame Your Biz';

  @override
  String get nativeReminderBody =>
      'Abra Tame Your Biz para revisar un recordatorio programado.';

  @override
  String get deviceRemindersUnavailableTitle =>
      'Recordatorios del dispositivo no disponibles';

  @override
  String get deviceRemindersRetry => 'Reintentar recordatorios';

  @override
  String get deviceRemindersOffTitle =>
      'Los recordatorios del dispositivo están desactivados';

  @override
  String get deviceRemindersOffBody =>
      'Los recordatorios dentro de la aplicación siguen funcionando. Active las notificaciones del dispositivo para recibir recordatorios cuando Tame Your Biz esté cerrado.';

  @override
  String get deviceRemindersEnable => 'Activar recordatorios del dispositivo';

  @override
  String get deviceRemindersEnabling =>
      'Activando recordatorios del dispositivo';

  @override
  String get deviceRemindersDenied =>
      'Los recordatorios del dispositivo siguen desactivados. Puede permitir las notificaciones de Tame Your Biz en la configuración del sistema.';

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

  @override
  String get catalogBrowse => 'Explorar catálogo';

  @override
  String get catalogInventory => 'Mi inventario';

  @override
  String get catalogGrid => 'Cuadrícula';

  @override
  String get catalogList => 'Lista';

  @override
  String get catalogChooseTrade => 'Elige un oficio';

  @override
  String get catalogChooseCategory => 'Elige una categoría';

  @override
  String get catalogSearch => 'Buscar artículos';

  @override
  String get catalogSearchCategory => 'Buscar en esta categoría';

  @override
  String get catalogClear => 'Borrar búsqueda';

  @override
  String get catalogPlumbing => 'Plomería';

  @override
  String get catalogElectrical => 'Electricidad';

  @override
  String get catalogHvac => 'Climatización';

  @override
  String get catalogFittings => 'Conexiones';

  @override
  String get catalogCopper => 'Cobre';

  @override
  String get catalogElbows90 => 'Codos de 90°';

  @override
  String get catalogItemDetails => 'Detalles del artículo';

  @override
  String get catalogAdd => 'Agregar a mi inventario';

  @override
  String catalogSize(String size) {
    return 'Medida nominal: $size';
  }

  @override
  String catalogUnit(String unit) {
    return 'Unidad: $unit';
  }

  @override
  String get catalogEach => 'pieza';

  @override
  String catalogCopperElbow(String size) {
    return 'Codo de cobre de 90° de $size';
  }

  @override
  String get catalogEmpty => 'Esta categoría se está reconstruyendo.';

  @override
  String get catalogNoMatches =>
      'No se encontraron artículos. Prueba otro nombre o medida.';

  @override
  String get workFilterAwaitingCustomer =>
      'Estimaciones pendientes del cliente';

  @override
  String get workFilterUnscheduledJobs => 'Trabajos por programar';

  @override
  String get workFilterActiveJobs => 'Trabajos activos';

  @override
  String get workFilterUnpaidInvoices => 'Facturas pendientes de pago';

  @override
  String get workFilterAllEstimates => 'Todas las estimaciones';

  @override
  String get workFilterDraftEstimates => 'Borradores de estimaciones';

  @override
  String get workFilterCompanyReviewEstimates =>
      'Estimaciones pendientes de aprobación de la empresa';

  @override
  String get workFilterReadyEstimates => 'Estimaciones listas para enviar';

  @override
  String get workFilterChangedEstimates =>
      'Estimaciones con cambios solicitados';

  @override
  String get workFilterApprovedEstimates => 'Estimaciones aprobadas';

  @override
  String get workFilterDeclinedEstimates => 'Estimaciones rechazadas';

  @override
  String get workFilterExpiredEstimates => 'Estimaciones vencidas';

  @override
  String get workFilterAllJobs => 'Todos los trabajos';

  @override
  String get workFilterCompletedJobs => 'Trabajos terminados';

  @override
  String get workFilterAllInvoices => 'Todas las facturas';

  @override
  String get workFilterDraftInvoices => 'Borradores de facturas';

  @override
  String get workFilterPaidInvoices => 'Facturas pagadas en su totalidad';

  @override
  String get workFilterOverdueInvoices => 'Facturas vencidas';

  @override
  String get workStatusDraft => 'Borrador';

  @override
  String get workStatusReady => 'Listo';

  @override
  String get workStatusSent => 'Enviado';

  @override
  String get workStatusAccepted => 'Aceptado';

  @override
  String get workStatusScheduled => 'Programado';

  @override
  String get workStatusEnRoute => 'En camino';

  @override
  String get workStatusArrived => 'En el lugar';

  @override
  String get workStatusInProgress => 'En curso';

  @override
  String get workStatusPaused => 'En pausa';

  @override
  String get workStatusNeedsReturnVisit => 'Requiere otra visita';

  @override
  String get workStatusCompleted => 'Terminado';

  @override
  String get workStatusDue => 'Pendiente de pago';

  @override
  String get workStatusPaid => 'Pagado';

  @override
  String get workStatusReadyToSend => 'Listo para enviar';

  @override
  String get workStatusAwaitingCustomer => 'Pendiente del cliente';

  @override
  String get workStatusViewed => 'Visto';

  @override
  String get workStatusChangesRequested => 'Cambios solicitados';

  @override
  String get workStatusApproved => 'Aprobado';

  @override
  String get workStatusDeclined => 'Rechazado';

  @override
  String get workStatusExpired => 'Vencido';

  @override
  String get workStatusConverted => 'Convertido en trabajo';

  @override
  String get workStatusArchived => 'Archivado';

  @override
  String get workOverviewHeading => 'Resumen de trabajo · Todas las fechas';

  @override
  String get workBrowseRecords => 'Ver registros';

  @override
  String get workRecordsHeading => 'Registros de trabajo';

  @override
  String get workShowRecords => 'Mostrar registros';

  @override
  String get workSearchRecords => 'Buscar cliente, título o número';

  @override
  String get workNoMatchingRecords =>
      'No hay registros coincidentes. Pruebe otro estado o búsqueda.';

  @override
  String get workRecordUnavailable => 'Este registro ya no está disponible.';

  @override
  String get workNotScheduled => 'Sin programar';

  @override
  String get workCreatedDateMissing => 'Fecha de creación no registrada';

  @override
  String workCreatedDate(String date) {
    return 'Creado el $date';
  }

  @override
  String workCompletedDate(String date) {
    return 'Terminado el $date';
  }

  @override
  String workScheduledDate(String date) {
    return 'Programado para $date';
  }

  @override
  String workDueDate(String date) {
    return 'Vence el $date';
  }

  @override
  String workRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros',
      one: '1 registro',
      zero: '0 registros',
    );
    return 'Todas las fechas · $_temp0';
  }

  @override
  String get workDocumentStyle => 'Documento para el cliente';

  @override
  String get workDocumentDetailed => 'Detallado';

  @override
  String get workDocumentSummary => 'Resumen';

  @override
  String get workDocumentDetailedHelp =>
      'Mostrar cada artículo, descripción, cantidad y precio.';

  @override
  String get workDocumentSummaryHelp =>
      'Mostrar la descripción del trabajo y el precio total. Conservar los artículos y costos individuales en sus registros.';

  @override
  String get workServicePrice => 'Precio del trabajo';

  @override
  String get workEnterServicePrice => 'Ingrese un precio';

  @override
  String get workPriceBeforeAdjustments =>
      'Precio antes de descuento e impuestos';

  @override
  String get workMoneyPaid => 'Pagado en su totalidad';

  @override
  String get workMoneyUnpaid => 'Pendiente';

  @override
  String get workMoneyOverdue => 'Vencido';

  @override
  String get workMoneyAllTime => 'Todo el período';

  @override
  String get workInvoicesWithPayments => 'Facturas con pagos';

  @override
  String get workPartiallyPaid => 'Pago parcial';

  @override
  String get workInvoiceHeading => 'Facturas';

  @override
  String get workFilterAllShort => 'Todas';

  @override
  String get workPaymentsReceivedShort => 'Pagos recibidos';

  @override
  String get workDraftsShort => 'Borradores';

  @override
  String get workInvoiceTotal => 'Total de la factura';

  @override
  String get workInvoiceBalance => 'Saldo pendiente';

  @override
  String get workNewInvoice => 'Nueva factura';

  @override
  String get workInvoiceActivityByDate => 'Actividad por fecha';

  @override
  String get workInvoiceActivityHeading => 'Actividad de facturas';

  @override
  String get workInvoiceAccessDenied =>
      'No tienes permiso para ver las facturas.';

  @override
  String get workSearchInvoices => 'Buscar facturas';

  @override
  String get workSearchInvoicesHint =>
      'Cliente, trabajo, número de factura o título del trabajo';

  @override
  String get workInvoiceMatches => 'Facturas encontradas';

  @override
  String get workInvoiceNoMatches =>
      'No hay facturas autorizadas que coincidan con la búsqueda.';

  @override
  String get workInvoicesForDate => 'Facturas de esta fecha';

  @override
  String get workInvoiceNoDateActivity =>
      'No hay actividad de facturas registrada para esta fecha.';

  @override
  String get workOpenInvoices => 'Otras facturas pendientes';

  @override
  String get workInvoiceNoOpenBalance =>
      'No hay otras facturas con saldo pendiente.';

  @override
  String get workShowOnlyThree => 'Mostrar solo 3';

  @override
  String get workInvoiceUnavailable => 'Esta factura ya no está disponible.';

  @override
  String get workInvoiceAttention => 'Facturas que requieren atención';

  @override
  String get workInvoiceDrafts => 'Borradores de facturas';

  @override
  String workInvoiceOverdueReason(String customer) {
    return 'Factura vencida · $customer';
  }

  @override
  String get workInvoiceActivityCreated => 'Creada';

  @override
  String get workInvoiceActivityIssued => 'Emitida';

  @override
  String get workInvoiceActivityDue => 'Vencimiento';

  @override
  String get workInvoiceActivityPayment => 'Pago recibido';

  @override
  String get workInvoiceActivityApplied => 'Pago aplicado';

  @override
  String get workSavedClients => 'Clientes guardados';

  @override
  String get workAddClient => 'Agregar nuevo';

  @override
  String get workUseClient => 'Usar este cliente';

  @override
  String get workSearchClients => 'Buscar clientes guardados';

  @override
  String get workClientsUnavailable =>
      'No tienes permiso para ver los clientes guardados.';

  @override
  String get workNoMatchingClients =>
      'No hay clientes que coincidan. Prueba otra búsqueda o agrega un cliente.';

  @override
  String get invoiceRequestApproval => 'Solicitar aprobación';

  @override
  String get invoiceApprove => 'Aprobar factura';

  @override
  String get invoiceRequestChanges => 'Solicitar cambios';

  @override
  String get invoiceChangesReason => '¿Qué debe cambiar?';

  @override
  String get invoiceChangesReasonRequired =>
      'Explica qué cambios se necesitan.';

  @override
  String get invoiceApprovalSaveFailed =>
      'No se pudo guardar la aprobación. Inténtalo de nuevo.';

  @override
  String get invoiceNeedsApproval => 'Requiere aprobación';

  @override
  String get workOverallPrice => 'Precio del trabajo';

  @override
  String get workOverallPriceHint =>
      'Introduce un precio o añade artículos individuales abajo';

  @override
  String get workOptionalItems => 'Añadir artículos (opcional)';

  @override
  String get clientSaved => 'Clientes guardados';

  @override
  String get clientAddNew => 'Agregar cliente';

  @override
  String get clientNoSaved => 'No hay clientes guardados';

  @override
  String get clientSearch => 'Buscar clientes';

  @override
  String get clientNoMatches => 'No hay clientes que coincidan';

  @override
  String get clientForEstimate => 'Cliente de este presupuesto';

  @override
  String get clientSelectForEstimate =>
      'Seleccione un cliente para este presupuesto.';

  @override
  String get clientViewDenied =>
      'No tiene permiso para ver los clientes guardados.';

  @override
  String get clientUnfinished => 'Formularios de clientes sin terminar';

  @override
  String get clientContinueHint => 'Continúe la información que comenzó antes.';

  @override
  String get clientRecoveryRetry =>
      'Formularios sin terminar no disponibles — Reintentar';

  @override
  String get clientNameMissing => 'Nombre del cliente sin ingresar';

  @override
  String get clientRecoveryFailed =>
      'No se pudo abrir la información del cliente sin terminar. Se conservaron sus datos. Inténtelo de nuevo.';

  @override
  String get clientDetails => 'Datos del cliente';

  @override
  String get clientName => 'Nombre del cliente';

  @override
  String get clientNameHint => 'Nombre y apellido, o nombre del negocio';

  @override
  String get clientBusiness => 'Negocio del cliente (opcional)';

  @override
  String get clientPhone => 'Teléfono (con código de área)';

  @override
  String get clientEmail => 'Correo electrónico (opcional)';

  @override
  String get clientPreferredContact => 'Contacto preferido';

  @override
  String get clientCall => 'Llamada telefónica';

  @override
  String get clientText => 'Mensaje de texto';

  @override
  String get clientEmailMethod => 'Correo electrónico';

  @override
  String get clientLocations => 'Dirección de facturación y del servicio';

  @override
  String get clientBilling => 'Dirección de facturación';

  @override
  String get clientAddressLabel => 'Nombre de la dirección (opcional)';

  @override
  String get clientAddressHint => 'Casa, oficina u otro nombre';

  @override
  String get clientServiceAddress => 'Dirección del servicio';

  @override
  String get clientAccess => 'Acceso a la propiedad (opcional)';

  @override
  String get clientAccessHint =>
      'Código de acceso, estacionamiento o instrucciones de entrada';

  @override
  String get clientNotes => 'Notas del cliente (opcional)';

  @override
  String get clientNotesHint =>
      'Notas sobre el cliente, aparte de las instrucciones de acceso a la propiedad.';

  @override
  String get clientSaveUse => 'Guardar y usar cliente';

  @override
  String get clientSave => 'Guardar cliente';

  @override
  String get clientSaveChanges => 'Guardar cambios del cliente';

  @override
  String get clientEdit => 'Editar cliente';
}

/// The translations for Spanish Castilian, as used in the United States (`es_US`).
class AppLocalizationsEsUs extends AppLocalizationsEs {
  AppLocalizationsEsUs() : super('es_US');

  @override
  String get appTitle => 'Tame Your Biz';

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

  @override
  String get catalogBrowse => 'Explorar catálogo';

  @override
  String get catalogInventory => 'Mi inventario';

  @override
  String get catalogGrid => 'Cuadrícula';

  @override
  String get catalogList => 'Lista';

  @override
  String get catalogChooseTrade => 'Elige un oficio';

  @override
  String get catalogChooseCategory => 'Elige una categoría';

  @override
  String get catalogSearch => 'Buscar artículos';

  @override
  String get catalogSearchCategory => 'Buscar en esta categoría';

  @override
  String get catalogClear => 'Borrar búsqueda';

  @override
  String get catalogPlumbing => 'Plomería';

  @override
  String get catalogElectrical => 'Electricidad';

  @override
  String get catalogHvac => 'Climatización';

  @override
  String get catalogFittings => 'Conexiones';

  @override
  String get catalogCopper => 'Cobre';

  @override
  String get catalogElbows90 => 'Codos de 90°';

  @override
  String get catalogItemDetails => 'Detalles del artículo';

  @override
  String get catalogAdd => 'Agregar a mi inventario';

  @override
  String catalogSize(String size) {
    return 'Medida nominal: $size';
  }

  @override
  String catalogUnit(String unit) {
    return 'Unidad: $unit';
  }

  @override
  String get catalogEach => 'pieza';

  @override
  String catalogCopperElbow(String size) {
    return 'Codo de cobre de 90° de $size';
  }

  @override
  String get catalogEmpty => 'Esta categoría se está reconstruyendo.';

  @override
  String get catalogNoMatches =>
      'No se encontraron artículos. Prueba otro nombre o medida.';

  @override
  String get workFilterAwaitingCustomer =>
      'Estimaciones pendientes del cliente';

  @override
  String get workFilterUnscheduledJobs => 'Trabajos por programar';

  @override
  String get workFilterActiveJobs => 'Trabajos activos';

  @override
  String get workFilterUnpaidInvoices => 'Facturas pendientes de pago';

  @override
  String get workFilterAllEstimates => 'Todas las estimaciones';

  @override
  String get workFilterDraftEstimates => 'Borradores de estimaciones';

  @override
  String get workFilterCompanyReviewEstimates =>
      'Estimaciones pendientes de aprobación de la empresa';

  @override
  String get workFilterReadyEstimates => 'Estimaciones listas para enviar';

  @override
  String get workFilterChangedEstimates =>
      'Estimaciones con cambios solicitados';

  @override
  String get workFilterApprovedEstimates => 'Estimaciones aprobadas';

  @override
  String get workFilterDeclinedEstimates => 'Estimaciones rechazadas';

  @override
  String get workFilterExpiredEstimates => 'Estimaciones vencidas';

  @override
  String get workFilterAllJobs => 'Todos los trabajos';

  @override
  String get workFilterCompletedJobs => 'Trabajos terminados';

  @override
  String get workFilterAllInvoices => 'Todas las facturas';

  @override
  String get workFilterDraftInvoices => 'Borradores de facturas';

  @override
  String get workFilterPaidInvoices => 'Facturas pagadas en su totalidad';

  @override
  String get workFilterOverdueInvoices => 'Facturas vencidas';

  @override
  String get workStatusDraft => 'Borrador';

  @override
  String get workStatusReady => 'Listo';

  @override
  String get workStatusSent => 'Enviado';

  @override
  String get workStatusAccepted => 'Aceptado';

  @override
  String get workStatusScheduled => 'Programado';

  @override
  String get workStatusEnRoute => 'En camino';

  @override
  String get workStatusArrived => 'En el lugar';

  @override
  String get workStatusInProgress => 'En curso';

  @override
  String get workStatusPaused => 'En pausa';

  @override
  String get workStatusNeedsReturnVisit => 'Requiere otra visita';

  @override
  String get workStatusCompleted => 'Terminado';

  @override
  String get workStatusDue => 'Pendiente de pago';

  @override
  String get workStatusPaid => 'Pagado';

  @override
  String get workStatusReadyToSend => 'Listo para enviar';

  @override
  String get workStatusAwaitingCustomer => 'Pendiente del cliente';

  @override
  String get workStatusViewed => 'Visto';

  @override
  String get workStatusChangesRequested => 'Cambios solicitados';

  @override
  String get workStatusApproved => 'Aprobado';

  @override
  String get workStatusDeclined => 'Rechazado';

  @override
  String get workStatusExpired => 'Vencido';

  @override
  String get workStatusConverted => 'Convertido en trabajo';

  @override
  String get workStatusArchived => 'Archivado';

  @override
  String get workOverviewHeading => 'Resumen de trabajo · Todas las fechas';

  @override
  String get workBrowseRecords => 'Ver registros';

  @override
  String get workRecordsHeading => 'Registros de trabajo';

  @override
  String get workShowRecords => 'Mostrar registros';

  @override
  String get workSearchRecords => 'Buscar cliente, título o número';

  @override
  String get workNoMatchingRecords =>
      'No hay registros coincidentes. Pruebe otro estado o búsqueda.';

  @override
  String get workRecordUnavailable => 'Este registro ya no está disponible.';

  @override
  String get workNotScheduled => 'Sin programar';

  @override
  String get workCreatedDateMissing => 'Fecha de creación no registrada';

  @override
  String workCreatedDate(String date) {
    return 'Creado el $date';
  }

  @override
  String workCompletedDate(String date) {
    return 'Terminado el $date';
  }

  @override
  String workScheduledDate(String date) {
    return 'Programado para $date';
  }

  @override
  String workDueDate(String date) {
    return 'Vence el $date';
  }

  @override
  String workRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros',
      one: '1 registro',
      zero: '0 registros',
    );
    return 'Todas las fechas · $_temp0';
  }

  @override
  String get workDocumentStyle => 'Documento para el cliente';

  @override
  String get workDocumentDetailed => 'Detallado';

  @override
  String get workDocumentSummary => 'Resumen';

  @override
  String get workDocumentDetailedHelp =>
      'Mostrar cada artículo, descripción, cantidad y precio.';

  @override
  String get workDocumentSummaryHelp =>
      'Mostrar la descripción del trabajo y el precio total. Conservar los artículos y costos individuales en sus registros.';

  @override
  String get workServicePrice => 'Precio del trabajo';

  @override
  String get workEnterServicePrice => 'Ingrese un precio';

  @override
  String get workPriceBeforeAdjustments =>
      'Precio antes de descuento e impuestos';

  @override
  String get workMoneyPaid => 'Pagado en su totalidad';

  @override
  String get workMoneyUnpaid => 'Pendiente';

  @override
  String get workMoneyOverdue => 'Vencido';

  @override
  String get workMoneyAllTime => 'Todo el período';

  @override
  String get workInvoicesWithPayments => 'Facturas con pagos';

  @override
  String get workPartiallyPaid => 'Pago parcial';

  @override
  String get workInvoiceHeading => 'Facturas';

  @override
  String get workFilterAllShort => 'Todas';

  @override
  String get workPaymentsReceivedShort => 'Pagos recibidos';

  @override
  String get workDraftsShort => 'Borradores';

  @override
  String get workInvoiceTotal => 'Total de la factura';

  @override
  String get workInvoiceBalance => 'Saldo pendiente';

  @override
  String get workNewInvoice => 'Nueva factura';

  @override
  String get workInvoiceActivityByDate => 'Actividad por fecha';

  @override
  String get workInvoiceActivityHeading => 'Actividad de facturas';

  @override
  String get workInvoiceAccessDenied =>
      'No tienes permiso para ver las facturas.';

  @override
  String get workSearchInvoices => 'Buscar facturas';

  @override
  String get workSearchInvoicesHint =>
      'Cliente, trabajo, número de factura o título del trabajo';

  @override
  String get workInvoiceMatches => 'Facturas encontradas';

  @override
  String get workInvoiceNoMatches =>
      'No hay facturas autorizadas que coincidan con la búsqueda.';

  @override
  String get workInvoicesForDate => 'Facturas de esta fecha';

  @override
  String get workInvoiceNoDateActivity =>
      'No hay actividad de facturas registrada para esta fecha.';

  @override
  String get workOpenInvoices => 'Otras facturas pendientes';

  @override
  String get workInvoiceNoOpenBalance =>
      'No hay otras facturas con saldo pendiente.';

  @override
  String get workShowOnlyThree => 'Mostrar solo 3';

  @override
  String get workInvoiceUnavailable => 'Esta factura ya no está disponible.';

  @override
  String get workInvoiceAttention => 'Facturas que requieren atención';

  @override
  String get workInvoiceDrafts => 'Borradores de facturas';

  @override
  String workInvoiceOverdueReason(String customer) {
    return 'Factura vencida · $customer';
  }

  @override
  String get workInvoiceActivityCreated => 'Creada';

  @override
  String get workInvoiceActivityIssued => 'Emitida';

  @override
  String get workInvoiceActivityDue => 'Vencimiento';

  @override
  String get workInvoiceActivityPayment => 'Pago recibido';

  @override
  String get workInvoiceActivityApplied => 'Pago aplicado';

  @override
  String get workSavedClients => 'Clientes guardados';

  @override
  String get workAddClient => 'Agregar nuevo';

  @override
  String get workUseClient => 'Usar este cliente';

  @override
  String get workSearchClients => 'Buscar clientes guardados';

  @override
  String get workClientsUnavailable =>
      'No tienes permiso para ver los clientes guardados.';

  @override
  String get workNoMatchingClients =>
      'No hay clientes que coincidan. Prueba otra búsqueda o agrega un cliente.';

  @override
  String get invoiceRequestApproval => 'Solicitar aprobación';

  @override
  String get invoiceApprove => 'Aprobar factura';

  @override
  String get invoiceRequestChanges => 'Solicitar cambios';

  @override
  String get invoiceChangesReason => '¿Qué debe cambiar?';

  @override
  String get invoiceChangesReasonRequired =>
      'Explica qué cambios se necesitan.';

  @override
  String get invoiceApprovalSaveFailed =>
      'No se pudo guardar la aprobación. Inténtalo de nuevo.';

  @override
  String get invoiceNeedsApproval => 'Requiere aprobación';

  @override
  String get workOverallPrice => 'Precio del trabajo';

  @override
  String get workOverallPriceHint =>
      'Introduce un precio o añade artículos individuales abajo';

  @override
  String get workOptionalItems => 'Añadir artículos (opcional)';

  @override
  String get clientSaved => 'Clientes guardados';

  @override
  String get clientAddNew => 'Agregar cliente';

  @override
  String get clientNoSaved => 'No hay clientes guardados';

  @override
  String get clientSearch => 'Buscar clientes';

  @override
  String get clientNoMatches => 'No hay clientes que coincidan';

  @override
  String get clientForEstimate => 'Cliente de este presupuesto';

  @override
  String get clientSelectForEstimate =>
      'Seleccione un cliente para este presupuesto.';

  @override
  String get clientViewDenied =>
      'No tiene permiso para ver los clientes guardados.';

  @override
  String get clientUnfinished => 'Formularios de clientes sin terminar';

  @override
  String get clientContinueHint => 'Continúe la información que comenzó antes.';

  @override
  String get clientRecoveryRetry =>
      'Formularios sin terminar no disponibles — Reintentar';

  @override
  String get clientNameMissing => 'Nombre del cliente sin ingresar';

  @override
  String get clientRecoveryFailed =>
      'No se pudo abrir la información del cliente sin terminar. Se conservaron sus datos. Inténtelo de nuevo.';

  @override
  String get clientDetails => 'Datos del cliente';

  @override
  String get clientName => 'Nombre del cliente';

  @override
  String get clientNameHint => 'Nombre y apellido, o nombre del negocio';

  @override
  String get clientBusiness => 'Negocio del cliente (opcional)';

  @override
  String get clientPhone => 'Teléfono (con código de área)';

  @override
  String get clientEmail => 'Correo electrónico (opcional)';

  @override
  String get clientPreferredContact => 'Contacto preferido';

  @override
  String get clientCall => 'Llamada telefónica';

  @override
  String get clientText => 'Mensaje de texto';

  @override
  String get clientEmailMethod => 'Correo electrónico';

  @override
  String get clientLocations => 'Dirección de facturación y del servicio';

  @override
  String get clientBilling => 'Dirección de facturación';

  @override
  String get clientAddressLabel => 'Nombre de la dirección (opcional)';

  @override
  String get clientAddressHint => 'Casa, oficina u otro nombre';

  @override
  String get clientServiceAddress => 'Dirección del servicio';

  @override
  String get clientAccess => 'Acceso a la propiedad (opcional)';

  @override
  String get clientAccessHint =>
      'Código de acceso, estacionamiento o instrucciones de entrada';

  @override
  String get clientNotes => 'Notas del cliente (opcional)';

  @override
  String get clientNotesHint =>
      'Notas sobre el cliente, aparte de las instrucciones de acceso a la propiedad.';

  @override
  String get clientSaveUse => 'Guardar y usar cliente';

  @override
  String get clientSave => 'Guardar cliente';

  @override
  String get clientSaveChanges => 'Guardar cambios del cliente';

  @override
  String get clientEdit => 'Editar cliente';
}

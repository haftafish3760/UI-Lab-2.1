import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_extension.dart';
import '../layout/app_layout_engine.dart';
import '../shell/app_menu_scope.dart';
import '../theme/app_theme.dart';
import 'app_view_mode.dart';

part 'operational_header_controls.dart';
part 'operational_owner_header.dart';
part 'operational_dashboard_header.dart';
part 'operational_context_picker.dart';

enum OperationalContextKind { employee, vehicle, activeVehicle }

enum OperationalContextTitleKind { companyOverview, fleetOverview }

@immutable
class OperationalHeaderContextOption {
  const OperationalHeaderContextOption({
    required this.id,
    required this.kind,
    required this.title,
    required this.icon,
    this.titleKind,
    this.detail,
    this.iconColor,
  });

  final String id;
  final OperationalContextKind kind;
  final String title;
  final OperationalContextTitleKind? titleKind;
  final String? detail;
  final IconData icon;
  final Color? iconColor;

  String localizedLabel(AppLocalizations localizations) => switch (kind) {
    OperationalContextKind.employee => localizations.operationalContextEmployee,
    OperationalContextKind.vehicle => localizations.operationalContextVehicle,
    OperationalContextKind.activeVehicle =>
      localizations.operationalContextActiveVehicle,
  };

  String localizedTitle(AppLocalizations localizations) => switch (titleKind) {
    OperationalContextTitleKind.companyOverview =>
      localizations.operationalCompanyOverview,
    OperationalContextTitleKind.fleetOverview =>
      localizations.operationalFleetOverview,
    null => title,
  };
}

class OperationalHeader extends StatelessWidget {
  const OperationalHeader({
    required this.view,
    required this.onViewChanged,
    required this.selectedContext,
    required this.contextOptions,
    required this.onContextChanged,
    required this.settingsTooltip,
    required this.onSettings,
    this.showSettings = true,
    this.showStartWorkday = false,
    this.onStartWorkday,
    this.primaryActionLabel = 'Start workday',
    this.primaryActionIcon = Icons.play_arrow_rounded,
    this.primaryActionKey = const ValueKey('start-workday-button'),
    this.leadingIcon = Icons.menu_rounded,
    this.leadingTooltip = 'Open navigation menu',
    this.onLeading,
    this.contextKey = const ValueKey('operational-context-selector'),
    this.viewKey = const ValueKey('operational-view-selector'),
    this.settingsKey = const ValueKey('operational-settings-button'),
    this.headerTitle,
    this.ownerPresentation = false,
    this.dashboardWide = false,
    this.contextReading,
    super.key,
  });

  final AppViewMode view;
  final ValueChanged<AppViewMode> onViewChanged;
  final OperationalHeaderContextOption selectedContext;
  final List<OperationalHeaderContextOption> contextOptions;
  final ValueChanged<OperationalHeaderContextOption> onContextChanged;
  final bool showStartWorkday;
  final VoidCallback? onStartWorkday;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final Key primaryActionKey;
  final IconData leadingIcon;
  final String leadingTooltip;
  final VoidCallback? onLeading;
  final String settingsTooltip;
  final VoidCallback onSettings;
  final bool showSettings;
  final Key contextKey;
  final Key viewKey;
  final Key settingsKey;
  final String? headerTitle;
  final bool ownerPresentation;
  final bool dashboardWide;
  final Widget? contextReading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.header,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.surface),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (dashboardWide) return _DashboardHeaderContents(header: this);
          if (ownerPresentation) {
            return Align(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayoutEngine.maximumFormWorkspaceWidth,
                ),
                child: _OwnerHeaderContents(header: this),
              ),
            );
          }
          final layout = AppLayoutEngine.headerFor(
            availableWidth: constraints.maxWidth,
            textScaler: MediaQuery.textScalerOf(context),
            hasStartAction: showStartWorkday,
          );
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: layout.padding,
              vertical: 6,
            ),
            child: layout.singleRow
                ? _wideHeader(layout)
                : _compactHeader(context, layout),
          );
        },
      ),
    );
  }

  Widget _wideHeader(HeaderLayout layout) {
    return SizedBox(
      height: layout.controlHeight,
      child: Row(
        children: [
          _leadingButton(),
          const SizedBox(width: 8),
          if (showStartWorkday) ...[
            SizedBox(
              width: layout.startWidth,
              child: _StartWorkdayButton(
                stackLabel: layout.stackStartLabel,
                onPressed: onStartWorkday,
                label: primaryActionLabel,
                icon: primaryActionIcon,
                controlKey: primaryActionKey,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: layout.vehicleWidth,
              height: layout.controlHeight,
              child: _ContextSelector(
                selected: selectedContext,
                options: contextOptions,
                onSelected: onContextChanged,
                controlKey: contextKey,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: layout.viewWidth,
              child: _ViewSelector(
                selected: view,
                stackLabel: layout.stackViewLabel,
                onSelected: onViewChanged,
                controlKey: viewKey,
              ),
            ),
          ] else ...[
            SizedBox(
              width: layout.viewWidth,
              child: _ViewSelector(
                selected: view,
                stackLabel: layout.stackViewLabel,
                onSelected: onViewChanged,
                controlKey: viewKey,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: layout.vehicleWidth,
              height: layout.controlHeight,
              child: _ContextSelector(
                selected: selectedContext,
                options: contextOptions,
                onSelected: onContextChanged,
                controlKey: contextKey,
              ),
            ),
          ],
          const SizedBox(width: 8),
          _settingsSlot(),
        ],
      ),
    );
  }

  Widget _compactHeader(BuildContext context, HeaderLayout layout) {
    if (!showStartWorkday) return _compactScopedHeader(context, layout);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: layout.controlHeight,
          child: Row(
            children: [
              _leadingButton(),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.center,
                  child: SizedBox(
                    width: layout.vehicleWidth,
                    height: layout.controlHeight,
                    child: _ContextSelector(
                      selected: selectedContext,
                      options: contextOptions,
                      onSelected: onContextChanged,
                      controlKey: contextKey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _settingsSlot(),
            ],
          ),
        ),
        const SizedBox(height: 5),
        if (showStartWorkday)
          _compactDashboardActions(layout)
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: layout.viewWidth,
              height: layout.actionHeight,
              child: _ViewSelector(
                selected: view,
                stackLabel: layout.stackViewLabel,
                onSelected: onViewChanged,
                controlKey: viewKey,
              ),
            ),
          ),
      ],
    );
  }

  Widget _compactScopedHeader(BuildContext context, HeaderLayout layout) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 42,
          child: Row(
            children: [
              _leadingButton(),
              Expanded(
                child: Text(
                  headerTitle ?? selectedContext.localizedLabel(context.l10n),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onHeader,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _settingsSlot(),
            ],
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: layout.controlHeight,
          child: Row(
            children: [
              SizedBox(
                width: 132,
                child: _ViewSelector(
                  selected: view,
                  stackLabel: true,
                  onSelected: onViewChanged,
                  controlKey: viewKey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ContextSelector(
                  selected: selectedContext,
                  options: contextOptions,
                  onSelected: onContextChanged,
                  controlKey: contextKey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _compactDashboardActions(HeaderLayout layout) {
    if (!layout.actionsSideBySide) {
      return Column(
        key: const ValueKey('header-actions-stacked'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: layout.actionHeight,
            child: _StartWorkdayButton(
              stackLabel: layout.stackStartLabel,
              onPressed: onStartWorkday,
              label: primaryActionLabel,
              icon: primaryActionIcon,
              controlKey: primaryActionKey,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: layout.actionHeight,
            child: _ViewSelector(
              selected: view,
              stackLabel: layout.stackViewLabel,
              onSelected: onViewChanged,
              controlKey: viewKey,
            ),
          ),
        ],
      );
    }
    return Row(
      key: const ValueKey('header-actions-side-by-side'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: layout.startWidth,
          height: layout.actionHeight,
          child: _StartWorkdayButton(
            stackLabel: layout.stackStartLabel,
            onPressed: onStartWorkday,
            label: primaryActionLabel,
            icon: primaryActionIcon,
            controlKey: primaryActionKey,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: layout.viewWidth,
          height: layout.actionHeight,
          child: _ViewSelector(
            selected: view,
            stackLabel: layout.stackViewLabel,
            onSelected: onViewChanged,
            controlKey: viewKey,
          ),
        ),
      ],
    );
  }

  Widget _leadingButton() => Builder(
    builder: (context) => IconButton(
      onPressed: onLeading ?? AppMenuScope.maybeOpenOf(context) ?? _noop,
      tooltip: leadingTooltip,
      color: AppColors.onHeader,
      iconSize: 22,
      constraints: const BoxConstraints.tightFor(width: 42, height: 42),
      icon: Icon(leadingIcon),
    ),
  );

  Widget _settingsSlot() =>
      showSettings ? _settingsButton() : const SizedBox(width: 42, height: 42);

  Widget _settingsButton() => IconButton(
    key: settingsKey,
    onPressed: onSettings,
    tooltip: settingsTooltip,
    color: AppColors.onHeader,
    iconSize: 22,
    constraints: const BoxConstraints.tightFor(width: 42, height: 42),
    icon: const Icon(Icons.settings_outlined),
  );

  static void _noop() {}
}

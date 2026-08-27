import 'package:flutter/material.dart';

import '../../layout/app_breakpoints.dart';
import '../../theme/app_theme.dart';
import 'active_vehicle_header.dart';
import 'dashboard_calendar.dart';
import 'dashboard_navigation.dart';
import 'day_prep_summary.dart';
import 'today_entries.dart';
import 'today_plan.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppBreakpoints.of(context);
    final desktop = layout == AppLayoutClass.desktop;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (desktop) const DesktopNavigation(),
            Expanded(child: _DashboardBody(layout: layout)),
          ],
        ),
      ),
      bottomNavigationBar: desktop ? null : const _DashboardBottomNavigation(),
    );
  }
}

class _DashboardBottomNavigation extends StatelessWidget {
  const _DashboardBottomNavigation();

  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;
    return SizedBox(
      height: 80,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: phone ? 8 : 16),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: NavigationBar(
                selectedIndex: 0,
                indicatorColor: AppColors.blueSoft,
                destinations: dashboardDestinations,
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.layout});

  final AppLayoutClass layout;

  @override
  Widget build(BuildContext context) {
    final phone = layout == AppLayoutClass.phone;
    final compactTypography = MediaQuery.sizeOf(context).width < 380;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD6E5DF), Color(0xFFEAF0ED)],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              phone ? 8 : 16,
              16,
              phone ? 8 : 16,
              28,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1420),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final threePane = constraints.maxWidth >= 1120;
                      final twoPane = constraints.maxWidth >= 920;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const ActiveVehicleHeader(),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Tuesday, August 25, 2026',
                                  style: TextStyle(
                                    fontSize: compactTypography ? 20 : 24,
                                    fontWeight: compactTypography
                                        ? FontWeight.w700
                                        : FontWeight.w900,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              if (!threePane) const _DateNotificationButton(),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (!twoPane) ...[
                            const TodayPlan(),
                            const SizedBox(height: 16),
                            const DayPrepSummary(compact: true),
                            const SizedBox(height: 16),
                            const TodayEntries(),
                            const SizedBox(height: 16),
                            const DashboardCalendar(),
                          ] else if (!threePane)
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 500,
                                  child: Column(
                                    children: [
                                      TodayPlan(),
                                      SizedBox(height: 18),
                                      DayPrepSummary(compact: true),
                                      SizedBox(height: 18),
                                      TodayEntries(),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 18),
                                SizedBox(
                                  width: 380,
                                  child: DashboardCalendar(),
                                ),
                              ],
                            )
                          else
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 13,
                                  child: Column(
                                    children: [
                                      TodayPlan(),
                                      SizedBox(height: 18),
                                      TodayEntries(),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 18),
                                Expanded(flex: 10, child: DayPrepSummary()),
                                SizedBox(width: 18),
                                SizedBox(
                                  width: 380,
                                  child: DashboardCalendar(),
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateNotificationButton extends StatelessWidget {
  const _DateNotificationButton();

  @override
  Widget build(BuildContext context) {
    return Badge(
      label: const Text('2'),
      child: IconButton.filledTonal(
        onPressed: () {},
        mouseCursor: SystemMouseCursors.click,
        tooltip: 'Notifications, 2 unread',
        icon: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

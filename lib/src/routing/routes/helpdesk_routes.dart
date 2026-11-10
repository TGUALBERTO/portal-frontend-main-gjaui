import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/screens/timesheet_screen.dart';
import 'package:gjamobile/src/routing/app_routes.dart';
import 'package:gjamobile/src/routing/home_child_path.dart';
import 'package:go_router/go_router.dart';

/// Helpdesk
final List<RouteBase> helpdeskRoutes = <RouteBase>[
  GoRoute(
    path: homeChild(AppRoutes.helpdeskTimesheet),
    name: 'helpdesk-timesheet',
    builder: (context, state) => const TimesheetScreen(),
  ),
];

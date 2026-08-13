import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/chatbot/presentation/chatbot_screen.dart';
import '../../features/dashboard/presentation/dealer_dashboard_screen.dart';
import '../../features/incentives/presentation/incentives_screen.dart';
import '../../features/leads/presentation/convert_customer_screen.dart';
import '../../features/leads/presentation/lead_detail_screen.dart';
import '../../features/leads/presentation/leads_list_screen.dart';
import '../../features/leads/presentation/new_lead_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/customer_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/public/presentation/bike_detail_screen.dart';
import '../../features/public/presentation/exchange_value_screen.dart';
import '../../features/public/presentation/public_catalog_screen.dart';
import '../../features/public/presentation/test_ride_booking_screen.dart';
import '../../features/service/presentation/new_service_request_screen.dart';
import '../../features/service/presentation/service_history_screen.dart';
import '../../features/service/presentation/service_home_screen.dart';
import '../../features/service/presentation/service_request_thread_screen.dart';
import '../../features/tickets/presentation/ticket_thread_screen.dart';
import '../../features/tickets/presentation/tickets_list_screen.dart';
import '../../features/vehicles/presentation/customer_home_screen.dart';
import '../../features/vehicles/presentation/vehicle_analytics_screen.dart';
import '../../models/enums.dart';
import '../widgets/customer_shell.dart';
import '../widgets/dealer_shell.dart';
import '../auth/auth_controller.dart';

/// Bridges Riverpod's [authControllerProvider] to go_router's
/// `refreshListenable`, so a sign-in/sign-out re-evaluates [_redirect]
/// without the router being rebuilt from scratch.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) => notifyListeners());
  }
}

/// `/dealer/*` and `/customer/*` are role-gated; everything else — the
/// public catalog, bike detail, exchange estimator, test-ride booking, and
/// the login/OTP screens — is reachable with no session, per
/// PLAN_frontend.md's "public/guest funnel + two login-gated role shells"
/// design.
String? _redirect(BuildContext context, GoRouterState state, Ref ref) {
  final authState = ref.read(authControllerProvider);
  // Still resolving the initial session check: don't redirect yet.
  if (authState.isLoading && !authState.hasValue) return null;

  final session = authState.valueOrNull;
  final path = state.matchedLocation;
  final isAuthRoute = path == '/login' || path == '/otp';
  final isDealerRoute = path.startsWith('/dealer');
  final isCustomerRoute = path.startsWith('/customer');
  final homeFor = session?.role == UserRole.customer ? '/customer/home' : '/dealer/dashboard';

  if (session == null && (isDealerRoute || isCustomerRoute)) return '/login';
  if (session != null && isAuthRoute) return homeFor;
  // Wrong-role guard: a signed-in customer hitting /dealer/* (or vice versa)
  // lands on their own home instead of a 404.
  if (session != null && isDealerRoute && session.role != UserRole.dealerStaff) return homeFor;
  if (session != null && isCustomerRoute && session.role != UserRole.customer) return homeFor;
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) => _redirect(context, state, ref),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PublicCatalogScreen(),
      ),
      GoRoute(
        path: '/models/:id',
        builder: (context, state) =>
            BikeDetailScreen(modelId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/exchange',
        builder: (context, state) => const ExchangeValueScreen(),
      ),
      GoRoute(
        path: '/book-test-ride',
        builder: (context, state) =>
            TestRideBookingScreen(preselectedModelId: state.extra as String?),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final identifier = state.extra as String? ?? '';
          return OtpScreen(identifier: identifier);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            DealerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dealer/dashboard',
              builder: (context, state) => const DealerDashboardScreen(),
              routes: [
                GoRoute(
                  path: 'notifications',
                  builder: (context, state) => const NotificationsScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dealer/leads',
              builder: (context, state) => const LeadsListScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const NewLeadScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      LeadDetailScreen(leadId: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'convert',
                      builder: (context, state) =>
                          ConvertCustomerScreen(leadId: state.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dealer/tickets',
              builder: (context, state) => const TicketsListScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      TicketThreadScreen(ticketId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dealer/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'incentives',
                  builder: (context, state) => const IncentivesScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            CustomerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/customer/home',
              builder: (context, state) => const CustomerHomeScreen(),
              routes: [
                GoRoute(
                  path: 'analytics/:vehicleId',
                  builder: (context, state) =>
                      VehicleAnalyticsScreen(vehicleId: state.pathParameters['vehicleId']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/customer/service',
              builder: (context, state) => const ServiceHomeScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) =>
                      NewServiceRequestScreen(vehicleId: state.extra as String),
                ),
                GoRoute(
                  path: 'history/:vehicleId',
                  builder: (context, state) =>
                      ServiceHistoryScreen(vehicleId: state.pathParameters['vehicleId']!),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      ServiceRequestThreadScreen(requestId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/customer/chatbot',
              builder: (context, state) => const ChatbotScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/customer/profile',
              builder: (context, state) => const CustomerProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});

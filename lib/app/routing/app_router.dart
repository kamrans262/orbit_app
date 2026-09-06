import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/presentation/activity_page.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_view_state.dart';
import '../../features/auth/presentation/pages/auth_loading_page.dart';
import '../../features/auth/presentation/pages/device_approval_required_page.dart';
import '../../features/auth/presentation/pages/device_approvals_page.dart';
import '../../features/auth/presentation/pages/email_sign_in_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/camera/presentation/camera_page.dart';
import '../../features/circles/presentation/circles_page.dart';
import '../../features/circles/presentation/pages/circle_detail_page.dart';
import '../../features/circles/presentation/pages/circle_member_settings_page.dart';
import '../../features/circles/presentation/pages/circle_members_page.dart';
import '../../features/circles/presentation/pages/circle_settings_page.dart';
import '../../features/circles/presentation/pages/create_circle_invite_page.dart';
import '../../features/circles/presentation/pages/create_circle_page.dart';
import '../../features/circles/presentation/pages/join_circle_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/ping/presentation/ping_page.dart';
import '../../features/presence/presentation/presence_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import 'orbit_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final refreshNotifier = _RouterRefreshNotifier();

  ref.listen(authControllerProvider, (_, _) => refreshNotifier.refresh());
  ref.onDispose(refreshNotifier.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/auth/loading',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isAuthRoute = location.startsWith('/auth/');

      return auth.when(
        loading: () => location == '/auth/loading' ? null : '/auth/loading',
        error: (_, _) => location == '/auth/loading' ? null : '/auth/loading',
        data: (value) {
          switch (value.stage) {
            case AuthStage.restoreFailed:
              return location == '/auth/loading' ? null : '/auth/loading';
            case AuthStage.signedOut:
              return location == '/auth/email' ? null : '/auth/email';
            case AuthStage.otpRequested:
              return location == '/auth/otp' ? null : '/auth/otp';
            case AuthStage.deviceApprovalRequired:
              return location == '/auth/device-approval'
                  ? null
                  : '/auth/device-approval';
            case AuthStage.authenticated:
              if (isAuthRoute || location == '/') {
                return '/home';
              }
              return null;
          }
        },
      );
    },
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (context, state) => const AuthLoadingPage()),
      GoRoute(
        path: '/auth/loading',
        builder: (context, state) => const AuthLoadingPage(),
      ),
      GoRoute(
        path: '/auth/email',
        builder: (context, state) => const EmailSignInPage(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) => const OtpVerificationPage(),
      ),
      GoRoute(
        path: '/auth/device-approval',
        builder: (context, state) => const DeviceApprovalRequiredPage(),
      ),
      GoRoute(
        path: '/security/device-approvals',
        builder: (context, state) => const DeviceApprovalsPage(),
      ),
      GoRoute(
        path: '/presence',
        builder: (context, state) => const PresencePage(),
      ),
      GoRoute(path: '/pings', builder: (context, state) => const PingPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return OrbitShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/circles',
                builder: (context, state) => const CirclesPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const CreateCirclePage(),
                  ),
                  GoRoute(
                    path: 'join',
                    builder: (context, state) => const JoinCirclePage(),
                  ),
                  GoRoute(
                    path: ':circleId',
                    builder: (context, state) => CircleDetailPage(
                      circleId: state.pathParameters['circleId']!,
                    ),
                  ),
                  GoRoute(
                    path: ':circleId/members',
                    builder: (context, state) => CircleMembersPage(
                      circleId: state.pathParameters['circleId']!,
                    ),
                  ),
                  GoRoute(
                    path: ':circleId/members/:membershipId',
                    builder: (context, state) => CircleMemberSettingsPage(
                      circleId: state.pathParameters['circleId']!,
                      membershipId: state.pathParameters['membershipId']!,
                    ),
                  ),
                  GoRoute(
                    path: ':circleId/invite',
                    builder: (context, state) => CreateCircleInvitePage(
                      circleId: state.pathParameters['circleId']!,
                    ),
                  ),
                  GoRoute(
                    path: ':circleId/settings',
                    builder: (context, state) => CircleSettingsPage(
                      circleId: state.pathParameters['circleId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/camera',
                builder: (context, state) => const CameraPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/activity',
                builder: (context, state) => const ActivityPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

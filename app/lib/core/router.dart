import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_scene_screen.dart';
import '../screens/paywall/paywall_screen.dart';
import '../screens/profile/legal_info_screen.dart';
import '../screens/profile/profile_screen.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

final routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier();
  ref.listen<AuthState>(authProvider, (_, _) {
    notifier.refresh();
  });
  ref.listen<SubscriptionState>(subscriptionProvider, (_, _) {
    notifier.refresh();
  });
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      if (!authState.isInitialized) {
        return null;
      }

      final isLoggedIn = authState.isAuthenticated;
      final location = state.matchedLocation;
      final subscriptionState = ref.read(subscriptionProvider);
      const authRoutes = {'/login', '/register'};
      const entitlementAllowedRoutes = {
        '/paywall',
        '/subscription/loading',
        '/profile',
        '/profile/legal/privacy',
        '/profile/legal/terms',
        '/support',
        '/account/delete',
      };
      String blockingPaywallRedirect(String returnRoute) {
        final reason = Uri.encodeComponent(
          subscriptionState.status?.reason ??
              subscriptionState.lastEntitlementReason ??
              'trial_expired',
        );
        return '/paywall?mode=blocking&reason=$reason&return=${Uri.encodeComponent(returnRoute)}';
      }

      if (isLoggedIn && authRoutes.contains(location)) {
        if (!subscriptionState.isInitialized) {
          return '/subscription/loading?return=${Uri.encodeComponent('/home')}';
        }
        if (subscriptionState.shouldBlockCoreAccess && !authState.viewOnly) {
          return blockingPaywallRedirect('/home');
        }
        return '/home';
      }

      if (!isLoggedIn && !authRoutes.contains(location)) {
        return '/login';
      }

      if (isLoggedIn &&
          location == '/subscription/loading' &&
          subscriptionState.isInitialized) {
        final returnRoute =
            state.uri.queryParameters['return']?.trim().isNotEmpty == true
            ? state.uri.queryParameters['return']!
            : '/home';
        if (subscriptionState.shouldBlockCoreAccess && !authState.viewOnly) {
          return blockingPaywallRedirect(returnRoute);
        }
        return returnRoute;
      }

      if (isLoggedIn &&
          !subscriptionState.isInitialized &&
          !entitlementAllowedRoutes.contains(location)) {
        return '/subscription/loading?return=${Uri.encodeComponent(state.uri.toString())}';
      }

      if (isLoggedIn &&
          subscriptionState.shouldBlockCoreAccess &&
          !authState.viewOnly &&
          !entitlementAllowedRoutes.contains(location) &&
          !authRoutes.contains(location)) {
        return blockingPaywallRedirect(state.uri.toString());
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => HomeSceneScreen(
              openTasksPanelOnStart:
                  state.uri.queryParameters['panel'] == 'tasks',
              openFamilyPanelOnStart:
                  state.uri.queryParameters['panel'] == 'family',
              openShopPanelOnStart:
                  state.uri.queryParameters['panel'] == 'shop',
            ),
          ),
          GoRoute(
            path: '/tasks',
            redirect: (context, state) => '/home?panel=tasks',
          ),
          GoRoute(
            path: '/family',
            redirect: (context, state) => '/home?panel=family',
          ),
          GoRoute(
            path: '/shop',
            redirect: (context, state) => '/home?panel=shop',
          ),
          GoRoute(
            path: '/paywall',
            builder: (context, state) {
              final subscriptionState = ref.read(subscriptionProvider);
              final mode =
                  state.uri.queryParameters['mode'] == 'blocking' ||
                      subscriptionState.shouldBlockCoreAccess
                  ? PaywallMode.blocking
                  : PaywallMode.optional;
              return PaywallScreen(
                mode: mode,
                reason:
                    state.uri.queryParameters['reason'] ??
                    subscriptionState.status?.reason,
                returnRoute: state.uri.queryParameters['return'],
              );
            },
          ),
          GoRoute(
            path: '/subscription/loading',
            builder: (context, state) => const _SubscriptionLoadingScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/legal/privacy',
            builder: (context, state) =>
                const LegalInfoScreen(kind: LegalInfoKind.privacy),
          ),
          GoRoute(
            path: '/profile/legal/terms',
            builder: (context, state) =>
                const LegalInfoScreen(kind: LegalInfoKind.terms),
          ),
          GoRoute(
            path: '/support',
            builder: (context, state) =>
                const LegalInfoScreen(kind: LegalInfoKind.support),
          ),
          GoRoute(
            path: '/account/delete',
            builder: (context, state) =>
                const LegalInfoScreen(kind: LegalInfoKind.accountDelete),
          ),
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFFFDF6E3), body: child);
  }
}

class _SubscriptionLoadingScreen extends StatelessWidget {
  const _SubscriptionLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFDF6E3),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF8D6A3E)),
            SizedBox(height: 18),
            Text(
              '正在确认会员状态...',
              style: TextStyle(
                color: Color(0xFF5B4632),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/family/family_screen.dart';
import '../screens/home/home_scene_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
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
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      if (!authState.isInitialized) {
        return null;
      }

      final isLoggedIn = authState.isAuthenticated;
      final location = state.matchedLocation;
      const publicRoutes = {'/onboarding', '/login', '/register'};

      if (isLoggedIn && publicRoutes.contains(location)) {
        return '/home';
      }

      if (!isLoggedIn && !publicRoutes.contains(location)) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
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
            builder: (context, state) => const FamilyScreen(),
          ),
          GoRoute(
            path: '/shop',
            redirect: (context, state) => '/home?panel=shop',
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
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

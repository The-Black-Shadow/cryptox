import 'package:cryptox/presentation/screen/home/home_screen.dart';
import 'package:cryptox/presentation/screen/profile/profile_screen.dart';
import 'package:cryptox/presentation/screen/splash/splash_screen.dart';
import 'package:cryptox/presentation/screen/wallet/wallet_screen.dart';
import 'package:cryptox/presentation/screen/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'routes.dart';

class RoutePages {
  static final ROUTER = GoRouter(
    initialLocation: Routes.SPLASH_ROUTE,
    routes: [
      // Splash screen route (independent)
      GoRoute(
        path: Routes.SPLASH_ROUTE,
        name: Routes.SPLASH_ROUTE,
        pageBuilder: (context, state) =>
            const MaterialPage(child: SplashScreen()),
      ),

      // Shell route with BottomNav wrapper
      ShellRoute(
        builder: (context, state, child) => Wrapper(child: child),
        routes: [
          GoRoute(
            path: Routes.HOME_ROUTE,
            name: Routes.HOME_ROUTE,
            pageBuilder: (context, state) =>
                const MaterialPage(child: HomeScreen()),
          ),
          GoRoute(
            path: Routes.WALLET_ROUTE,
            name: Routes.WALLET_ROUTE,
            pageBuilder: (context, state) =>
                const MaterialPage(child: WalletScreen()),
          ),
          GoRoute(
            path: Routes.PROFILE_ROUTE,
            name: Routes.PROFILE_ROUTE,
            pageBuilder: (context, state) =>
                const MaterialPage(child: ProfileScreen()),
          ),
        ],
      ),
    ],
  );
}

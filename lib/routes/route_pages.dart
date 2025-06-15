// ignore_for_file: non_constant_identifier_names

import 'package:cryptox/data/models/news_model.dart';
import 'package:cryptox/presentation/screen/admin/admin_screen.dart';
import 'package:cryptox/presentation/screen/all_coin/allcoin_screen.dart';
import 'package:cryptox/presentation/screen/auth/signin_screen.dart';
import 'package:cryptox/presentation/screen/auth/signup_screen.dart';
import 'package:cryptox/presentation/screen/home/home_screen.dart';
import 'package:cryptox/presentation/screen/news_screen.dart/all_news_screen.dart';
import 'package:cryptox/presentation/screen/news_screen.dart/news_detail_screen.dart';
import 'package:cryptox/presentation/screen/payment/payment_screen.dart';
import 'package:cryptox/presentation/screen/profile/profile_screen.dart';
import 'package:cryptox/presentation/screen/splash/splash_screen.dart';
import 'package:cryptox/presentation/screen/wallet/wallet_screen.dart';
import 'package:cryptox/presentation/screen/welcome/welcome_screen.dart';
import 'package:cryptox/presentation/screen/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'routes.dart';

class RoutePages {
  static final ROUTER = GoRouter(
    routes: [
      // Splash screen route (independent)
      GoRoute(
        path: Routes.SPLASH_ROUTE,
        name: Routes.SPLASH_ROUTE,
        pageBuilder: (context, state) =>
            const MaterialPage(child: SplashScreen()),
      ),
      // Welcome screen route (independent)
      GoRoute(
        path: Routes.WELCOME_ROUTE,
        name: Routes.WELCOME_ROUTE,
        pageBuilder: (context, state) =>
            const MaterialPage(child: WelcomeScreen()),
      ),

      GoRoute(
        path: '/admin', // The path for the admin screen
        name: Routes.ADMIN_ROUTE,
        builder: (context, state) => const AdminScreen(),
      ),

      // Auth routes (independent)
      GoRoute(
        path: Routes.SIGNUP_ROUTE,
        name: Routes.SIGNUP_ROUTE,
        pageBuilder: (context, state) => MaterialPage(child: SignupScreen()),
      ),
      GoRoute(
        path: Routes.SIGNIN_ROUTE,
        name: Routes.SIGNIN_ROUTE,
        pageBuilder: (context, state) => MaterialPage(child: SigninScreen()),
      ),

      GoRoute(
        path: Routes.ALL_COIN_ROUTE,
        name: Routes.ALL_COIN_ROUTE,
        pageBuilder: (context, state) => MaterialPage(child: AllcoinScreen()),
      ),

      GoRoute(
        path: Routes.ALL_NEWS_ROUTE,
        name: Routes.ALL_NEWS_ROUTE,
        pageBuilder: (context, state) => MaterialPage(child: AllNewsView()),
      ),

      GoRoute(
        path: Routes.NEWS_DETAIL_ROUTE,
        name: Routes.NEWS_DETAIL_ROUTE, // Optional: name the route
        pageBuilder: (context, state) {
          // 1. Retrieve the article object from state.extra
          final article = state.extra as Datum; // Cast to your Datum model

          // 2. Use CustomTransitionPage for smoother Hero animations (recommended)
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: NewsDetailScreen(
              article: article,
            ), // <-- Pass the retrieved article here
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Example: Fade Transition (works well with Hero)
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(
              milliseconds: 300,
            ), // Standard duration
          );
        },
      ),

      // Payment route (independent)
      GoRoute(
        path: Routes.PAYMENT_ROUTE,
        name: Routes.PAYMENT_ROUTE,
        pageBuilder: (context, state) => MaterialPage(child: PaymentScreen()),
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

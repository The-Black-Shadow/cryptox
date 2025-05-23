import 'package:cryptox/routes/route_pages.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Wrapper extends StatelessWidget {
  final Widget child;
  const Wrapper({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final uri = GoRouter.of(context).routeInformationProvider.value.uri.toString();

    if (uri.startsWith(Routes.HOME_ROUTE)) return 0;
    if (uri.startsWith(Routes.WALLET_ROUTE)) return 1;
    if (uri.startsWith(Routes.PROFILE_ROUTE)) return 2;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(Routes.HOME_ROUTE);
        break;
      case 1:
        context.go(Routes.WALLET_ROUTE);
        break;
      case 2:
        context.go(Routes.PROFILE_ROUTE);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

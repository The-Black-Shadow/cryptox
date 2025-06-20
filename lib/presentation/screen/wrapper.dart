import 'package:cryptox/routes/route_pages.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Wrapper extends StatelessWidget {
  final Widget child;
  const Wrapper({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final uri = GoRouter.of(
      context,
    ).routeInformationProvider.value.uri.toString();

    if (uri.startsWith(Routes.HOME_ROUTE)) return 0;
    if (uri.startsWith(Routes.WALLET_ROUTE)) return 1;
    if (uri.startsWith(Routes.DIGITAL_NOTE_ROUTE)) return 2;
    if (uri.startsWith(Routes.PROFILE_ROUTE)) return 3;
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
        context.go(Routes.DIGITAL_NOTE_ROUTE);
        break;
      case 3:
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
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color.fromARGB(255, 241, 27, 27),
        items: const [
          BottomNavigationBarItem(
            backgroundColor: Colors.black,
            icon: Icon(Icons.home, color: Colors.white),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.black,
            icon: Icon(Icons.account_balance_wallet, color: Colors.white),
            label: 'Crypto Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note, color: Colors.white),
            label: 'Digital Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.white),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

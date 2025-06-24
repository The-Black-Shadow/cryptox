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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 4,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home,
                  label: 'Home',
                  index: 0,
                  isSelected: selectedIndex == 0,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.account_balance_wallet,
                  label: 'Wallet',
                  index: 1,
                  isSelected: selectedIndex == 1,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.receipt_long,
                  label: 'Notes',
                  index: 2,
                  isSelected: selectedIndex == 2,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.person,
                  label: 'Profile',
                  index: 3,
                  isSelected: selectedIndex == 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cryptox/logic/bloc/profile/profile_bloc.dart';
import 'package:cryptox/logic/bloc/wallet_balance/wallet_balance_bloc.dart';
import 'package:cryptox/routes/route_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      // This listener will listen for state changes from the ProfileBloc
      // while the AdminScreen is active.
      listener: (context, state) {
        if (state is LogoutSuccess) {
          // 1. Reset all other BLoCs that hold user-specific data.
          // This prevents the next user from seeing the previous user's balance.
          context.read<WalletBalanceBloc>().add(ResetWalletBalance());
          // Add resets for any other BLoCs if necessary
          // context.read<CryptoConvertBloc>().add(ResetCryptoConvert());

          // 2. Navigate to the welcome screen after a successful logout.
          // Using goNamed replaces the entire navigation stack.
          context.goNamed(Routes.WELCOME_ROUTE);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            // This button dispatches the event that the listener above will catch.
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<ProfileBloc>().add(LogoutEvent());
              },
            ),
          ],
        ),
        body: Center(
          child: Text(
            'Welcome to the Admin Dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}

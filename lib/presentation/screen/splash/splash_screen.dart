import 'package:cryptox/logic/bloc/wallet_balance/wallet_balance_bloc.dart';
import 'package:cryptox/logic/cubit/splash/splash_cubit.dart';
import 'package:cryptox/routes/route_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Start splash logic when the widget is built
    context.read<SplashCubit>().startSplash();

    return Scaffold(
      body: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) {
          if (state is SplashEnd) {
            if (state.userModel != null) {
              // User is authenticated. Tell the global WalletBalanceBloc
              // to start listening for real-time updates.
              context.read<WalletBalanceBloc>().add(LoadWalletBalance());

              // Now, navigate based on role
              if (state.userModel!.role == 'admin') {
                // Use goNamed to replace the splash screen in the navigation stack
                context.goNamed(Routes.ADMIN_ROUTE);
              } else {
                context.goNamed(Routes.HOME_ROUTE);
              }
            } else {
              // User is not authenticated
              context.goNamed(Routes.SIGNIN_ROUTE);
            }
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottiefiles/splash_lottiefiles.json', // Ensure this path is correct
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 20),
              const Text(
                'CryptoX',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pacifico',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

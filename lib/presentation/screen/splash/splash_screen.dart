import 'package:cryptox/logic/cubit/splash/splash_cubit.dart';
import 'package:cryptox/routes/route_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      body: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) {
          if (state is SplashEnd) {
            context.goNamed(Routes.HOME_ROUTE);
          }
        },
        child: Center(
          child: Text(
            'Splash Screen',
            style: TextStyle(
              fontSize: 24,
              color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    ));
  }
}

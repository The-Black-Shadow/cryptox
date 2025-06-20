import 'package:authentication_buttons/authentication_buttons.dart';
import 'package:cryptox/logic/bloc/signin/signin_bloc.dart';
import 'package:cryptox/presentation/widgets/full_width_button.dart';
import 'package:cryptox/routes/route_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 24.0),
                Column(
                  children: [
                    Text(
                      'Let\'s Get Started',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Join us and experience the future of finance.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: BlocConsumer<SigninBloc, SigninState>(
                      builder: (context, state) {
                        if (state is SigninLoading) {
                          return const CircularProgressIndicator(
                            color: Colors.white,
                          );
                        }
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AuthenticationButton(
                              authenticationMethod: AuthenticationMethod.google,
                              onPressed: () => context.read<SigninBloc>().add(
                                RequestGoogleSigninEvent(),
                              ),
                              showLoader: false,
                            ),
                            const SizedBox(height: 16.0),
                          ],
                        );
                      },
                      listener: (context, state) {
                        if (state is SigninSuccess) {
                          if (state.userModel.role == 'admin') {
                            context.goNamed(Routes.ADMIN_ROUTE);
                          } else {
                            context.goNamed(Routes.HOME_ROUTE);
                          }
                        } else if (state is SigninFailure) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(state.error)));
                        }
                      },
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(color: Colors.white54),
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.pushNamed(Routes.SIGNIN_ROUTE),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    FullWidthButton(
                      buttonText: 'Create an account',
                      onTap: () => context.pushNamed(Routes.SIGNUP_ROUTE),
                      backgroundColor: Colors.tealAccent.shade700,
                      textColor: Colors.black,
                    ),
                    const SizedBox(height: 12.0),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Text(
              'Let\'s Get Started',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          BlocConsumer<SigninBloc, SigninState>(
            builder: (context, state) {
              if (state is SigninLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuthenticationButton(
                      authenticationMethod: AuthenticationMethod.google,
                      onPressed: () => context.read<SigninBloc>().add(RequestGoogleSigninEvent()),
                      // Don't show loader here; the BLoC state handles it for the whole section
                      showLoader: false,
                    ),
                    const SizedBox(height: 16.0),
                    AuthenticationButton(
                      authenticationMethod: AuthenticationMethod.facebook,
                      onPressed: () {
                        // TODO: Implement Facebook Sign-in
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Facebook sign-in not implemented yet.')),
                        );
                      },
                      showLoader: false,
                    ),
                    const SizedBox(height: 16.0),
                    AuthenticationButton(
                      authenticationMethod: AuthenticationMethod.twitter,
                      onPressed: () {
                         // TODO: Implement Twitter Sign-in
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Twitter sign-in not implemented yet.')),
                        );
                      },
                      showLoader: false,
                    ),
                    const SizedBox(height: 16.0),
                  ],
                ),
              );
            },
            listener: (context, state) {
              if (state is SigninSuccess) {
                // --- THIS IS THE UPDATED ROUTING LOGIC ---
                if (state.userModel.role == 'admin') {
                  // If user is an admin, go to the Admin screen
                  // Using goNamed replaces the navigation stack, which is good after login
                  context.goNamed(Routes.ADMIN_ROUTE); 
                } else {
                  // Otherwise, go to the Home screen
                  context.goNamed(Routes.HOME_ROUTE);
                }
              } else if (state is SigninFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error)),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0, left: 16, right: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        context.pushNamed(Routes.SIGNIN_ROUTE);
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
                FullWidthButton(
                  buttonText: 'Create an account',
                  onTap: () {
                    context.pushNamed(Routes.SIGNUP_ROUTE);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
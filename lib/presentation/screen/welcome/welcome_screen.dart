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
          Text(
            'Let\'s Get Started',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          BlocConsumer<SigninBloc,SigninState>(builder: (context,state){
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
                  onPressed: ()=>context.read<SigninBloc>().add(RequestGoogleSigninEvent()),
                  showLoader: false,
                ),
                const SizedBox(height: 16.0),
                AuthenticationButton(
                  authenticationMethod: AuthenticationMethod.facebook,
                  onPressed: () {},
                  showLoader: false,
                ),
                const SizedBox(height: 16.0),
                AuthenticationButton(
                  authenticationMethod: AuthenticationMethod.twitter,
                  onPressed: () {},
                  showLoader: false,
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          );
          },
          listener: (context, state){
            if (state is SigninSuccess) {
              context.pushNamed(Routes.HOME_ROUTE);
            } else if (state is SigninFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          }),
          Column(
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
        ],
      ),
    );
  }
}

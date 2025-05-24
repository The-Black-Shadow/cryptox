import 'package:cryptox/logic/bloc/signup/signup_bloc.dart';
import 'package:cryptox/presentation/widgets/full_width_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //validate the form
    final formkey = GlobalKey<FormState>();
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sign Up',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 20.0),

            BlocBuilder<SignupBloc, SignupState>(
              builder: (context, state) {
                if (state is SignupInitial) {
                  return Form(
                    key: formkey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: state.usernameController,
                          decoration: InputDecoration(
                            labelText: 'User name',
                            hintText: 'Enter your User name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: state.emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: state.passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: FullWidthButton(
        buttonText: 'Sign Up',
        onTap: () {
          if (formkey.currentState!.validate()) {
            // Call the signup function from the SignupBloc
          }
        },
      ),
    );
  }
}

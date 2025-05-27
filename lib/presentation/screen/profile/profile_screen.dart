import 'package:cryptox/data/preference/local_preference.dart';
import 'package:cryptox/logic/bloc/profile/profile_bloc.dart';
import 'package:cryptox/routes/route_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = LocalPreferences.getString('userName');
    final userEmail = LocalPreferences.getString('userEmail');
    final photoUrl = LocalPreferences.getString('photoUrl');
    final phoneNumber = LocalPreferences.getString('phoneNumber');

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is LogoutSuccess) {
          context.goNamed(Routes.WELCOME_ROUTE);
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Profile'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<ProfileBloc>().add(const LogoutEvent());
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(photoUrl),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hello, $userName',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      color: Colors.white.withOpacity(0.9),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.email,
                                color: Colors.blueGrey,
                              ),
                              title: Text(userEmail),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(
                                Icons.phone,
                                color: Colors.blueGrey,
                              ),
                              title: Text(phoneNumber),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "Cryptox",
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

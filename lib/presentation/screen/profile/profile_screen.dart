import 'package:cryptox/data/models/user_model.dart';
import 'package:cryptox/logic/bloc/crypto_convert/crypto_convert_bloc.dart';
import 'package:cryptox/logic/bloc/profile/profile_bloc.dart';
import 'package:cryptox/logic/bloc/wallet_balance/wallet_balance_bloc.dart';
import 'package:cryptox/routes/route_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(FetchProfile());
  }

  void _showEditDialog(
    BuildContext context,
    String currentVal,
    String fieldKey,
    String label,
  ) {
    final controller = TextEditingController(text: currentVal);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit $label'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<ProfileBloc>().add(
                  UpdateProfile({fieldKey: controller.text}),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              context.read<ProfileBloc>().add(LogoutEvent());
            },
          ),
        ],
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          // --- THIS IS THE KEY CHANGE ---
          if (state is LogoutSuccess) {
            // Before navigating, reset all BLoCs that hold user-specific data.
            context.read<WalletBalanceBloc>().add(ResetWalletBalance());
            context.read<CryptoConvertBloc>().add(ResetCryptoConvert());

            // Now, navigate the user to the welcome screen
            context.goNamed(Routes.WELCOME_ROUTE);
          }
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Profile updated successfully!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                if (state is ProfileLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                if (state is ProfileLoaded) {
                  final UserModel user = state.user;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 32.0,
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: user.photoUrl.isNotEmpty
                                ? NetworkImage(user.photoUrl)
                                : null,
                            child: user.photoUrl.isEmpty
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Hello, ${user.userName}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 6,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.person,
                                      color: Colors.blueGrey,
                                    ),
                                    title: Text(user.userName),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _showEditDialog(
                                        context,
                                        user.userName,
                                        'user_name',
                                        'Username',
                                      ),
                                    ),
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.email,
                                      color: Colors.blueGrey,
                                    ),
                                    title: Text(user.userEmail),
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.phone,
                                      color: Colors.blueGrey,
                                    ),
                                    title: Text(user.phoneNumber),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _showEditDialog(
                                        context,
                                        user.phoneNumber,
                                        'phone_number',
                                        'Phone Number',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (state is ProfileUpdating) ...[
                            const SizedBox(height: 20),
                            const CircularProgressIndicator(),
                          ],
                          const Spacer(),
                          Text(
                            "Cryptox",
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const Center(
                  child: Text(
                    'Loading profile...',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

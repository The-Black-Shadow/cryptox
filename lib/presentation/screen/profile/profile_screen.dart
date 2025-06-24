import 'package:cryptox/data/models/user_model.dart';
import 'package:cryptox/logic/bloc/profile/profile_bloc.dart';
import 'package:cryptox/logic/bloc/wallet_balance/wallet_balance_bloc.dart';
import 'package:cryptox/logic/bloc/send_crypto/send_crypto_bloc.dart'; // Changed import
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

  Widget _buildProfileItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool editable,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF667eea), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (editable && onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  size: 16,
                  color: Color(0xFF667eea),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Profile',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.logout, color: Colors.white),
                      ),
                      onPressed: () {
                        context.read<ProfileBloc>().add(LogoutEvent());
                      },
                    ),
                  ],
                ),
              ),

              // Content Section
              Expanded(
                child: BlocListener<ProfileBloc, ProfileState>(
                  listener: (context, state) {
                    // --- THIS IS THE CORRECTED LOGIC ---
                    if (state is LogoutSuccess) {
                      // Before navigating, reset all BLoCs that hold user-specific data.
                      context.read<WalletBalanceBloc>().add(
                        ResetWalletBalance(),
                      );
                      context.read<SendCryptoBloc>().add(
                        ResetSendCrypto(),
                      ); // Dispatch correct event

                      // Now, navigate the user to the welcome screen
                      context.goNamed(Routes.SIGNIN_ROUTE);
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
                  child: BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, state) {
                      if (state is ProfileLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      if (state is ProfileLoaded) {
                        final UserModel user = state.user;
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: [
                              // Profile Avatar Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundColor: const Color(
                                        0xFF667eea,
                                      ).withOpacity(0.1),
                                      backgroundImage: user.photoUrl.isNotEmpty
                                          ? NetworkImage(user.photoUrl)
                                          : null,
                                      child: user.photoUrl.isEmpty
                                          ? const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Color(0xFF667eea),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Hello, ${user.userName}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: const Color(0xFF667eea),
                                            fontWeight: FontWeight.bold,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF667eea,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        user.role.toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFF667eea),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Profile Information Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Profile Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF667eea),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildProfileItem(
                                      context,
                                      icon: Icons.person,
                                      label: 'Username',
                                      value: user.userName,
                                      editable: true,
                                      onEdit: () => _showEditDialog(
                                        context,
                                        user.userName,
                                        'user_name',
                                        'Username',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildProfileItem(
                                      context,
                                      icon: Icons.email,
                                      label: 'Email',
                                      value: user.userEmail,
                                      editable: false,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildProfileItem(
                                      context,
                                      icon: Icons.phone,
                                      label: 'Phone Number',
                                      value: user.phoneNumber,
                                      editable: true,
                                      onEdit: () => _showEditDialog(
                                        context,
                                        user.phoneNumber,
                                        'phone_number',
                                        'Phone Number',
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (state is ProfileUpdating) ...[
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Color(0xFF667eea),
                                      ),
                                      SizedBox(width: 16),
                                      Text(
                                        'Updating profile...',
                                        style: TextStyle(
                                          color: Color(0xFF667eea),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 32),

                              // App Branding
                              Container(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.currency_bitcoin,
                                        size: 32,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'CryptoX',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      'Your Digital Finance Partner',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),
                            ],
                          ),
                        );
                      }
                      return Container(
                        alignment: Alignment.center,
                        child: const Text(
                          'Loading profile...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

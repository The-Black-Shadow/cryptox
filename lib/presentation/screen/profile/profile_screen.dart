import 'package:cryptox/data/preference/local_preference.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text(
          'Hello,${LocalPreferences.getString('userName')}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

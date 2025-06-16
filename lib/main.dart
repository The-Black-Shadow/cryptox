import 'package:cryptox/app.dart';
import 'package:cryptox/data/preference/local_preference.dart';
import 'package:cryptox/data/repositories/admin_repository.dart';
import 'package:cryptox/data/repositories/auth_repository.dart';
import 'package:cryptox/data/repositories/coin_repository.dart';
import 'package:cryptox/data/repositories/wallet_repository.dart';
import 'package:cryptox/firebase_options.dart';
import 'package:cryptox/logic/bloc/bloc_observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize dotenv to load environment variables
  await dotenv.load(fileName: ".env");
  //Initialize Stripe with  publishable key
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  // It's good practice to set the URL scheme for deep linking
  await Stripe.instance.applySettings();
  Bloc.observer = MyBlocObserver();
  // Initialize local preferences
  await LocalPreferences().init();

  // Initialize your repositories once here
  final authRepository = AuthRepository();
  final walletRepository = WalletRepository();
  final coinRepository = CoinRepository();
  final adminRepository = AdminRepository();
  runApp( MyApp(
    authRepository: authRepository,
    walletRepository: walletRepository,
    coinRepository: coinRepository,
    adminRepository: adminRepository,
  ));
}

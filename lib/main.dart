import 'package:cryptox/app.dart';
import 'package:cryptox/firebase_options.dart';
import 'package:cryptox/logic/bloc/bloc_observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  Bloc.observer = MyBlocObserver();
  runApp(const MyApp());
}

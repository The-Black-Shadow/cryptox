import 'package:cryptox/app.dart';
import 'package:cryptox/logic/bloc/bloc_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  Bloc.observer = MyBlocObserver();
  runApp(const MyApp());
}

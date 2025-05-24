import 'package:cryptox/logic/bloc/signup/signup_bloc.dart';
import 'package:cryptox/logic/cubit/splash/splash_cubit.dart';
import 'package:cryptox/routes/route_pages.dart';
import 'package:cryptox/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SplashCubit()..startSplash()),
        BlocProvider(create: (context) => SignupBloc()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, child) {
          return MaterialApp.router(
            theme: const MaterialTheme(TextTheme()).light(),
            darkTheme: const MaterialTheme(TextTheme()).dark(),
            debugShowCheckedModeBanner: false,
            routerConfig: RoutePages.ROUTER,
          );
        },
      ),
    );
  }
}

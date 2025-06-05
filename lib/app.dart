import 'package:cryptox/data/repositories/allcoin_repository.dart';
import 'package:cryptox/data/repositories/auth_repository.dart';
import 'package:cryptox/data/repositories/coin_repository.dart';
import 'package:cryptox/data/repositories/news_repository.dart';
import 'package:cryptox/data/repositories/wallet_repository.dart';
import 'package:cryptox/logic/bloc/all_coin/all_coin_bloc.dart';
import 'package:cryptox/logic/bloc/coin/coin_bloc.dart';
import 'package:cryptox/logic/bloc/news/news_bloc.dart';
import 'package:cryptox/logic/bloc/profile/profile_bloc.dart';
import 'package:cryptox/logic/bloc/signin/signin_bloc.dart';
import 'package:cryptox/logic/bloc/signup/signup_bloc.dart';
import 'package:cryptox/logic/bloc/wallet_balance/wallet_balance_bloc.dart';
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
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthRepository()),
        RepositoryProvider(create: (context) => CoinRepository()),
        RepositoryProvider(create: (context) => AllCoinRepository()),
        RepositoryProvider(create: (context) => NewsRepository()),
        RepositoryProvider(create: (context) => WalletRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => SplashCubit()..startSplash()),
          BlocProvider(create: (context) => SignupBloc()),
          BlocProvider(
            create: (context) => SigninBloc((context.read<AuthRepository>())),
          ),
          BlocProvider(
            create: (context) => ProfileBloc((context.read<AuthRepository>())),
          ),
          BlocProvider(
            create: (context) =>
                CoinBloc(coinRepository: CoinRepository())..add(LoadCoins()),
          ),
          BlocProvider(
            create: (context) => AllCoinBloc(context.read<AllCoinRepository>()),
          ),
          BlocProvider(
            create: (context) => NewsBloc(newsRepository: NewsRepository())
              ..add(const LoadAllNewsArticles(page: 1)), // API gives 20 items
          ),
          BlocProvider(
            create: (context) =>
                WalletBalanceBloc(walletRepository: WalletRepository())
                  ..add(LoadWalletBalance()),
          ),
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
      ),
    );
  }
}

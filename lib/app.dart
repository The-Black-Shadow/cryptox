import 'package:cryptox/data/repositories/admin_repository.dart';
import 'package:cryptox/data/repositories/allcoin_repository.dart';
import 'package:cryptox/data/repositories/auth_repository.dart';
import 'package:cryptox/data/repositories/coin_repository.dart';
import 'package:cryptox/data/repositories/digital_note_repository.dart';
import 'package:cryptox/data/repositories/news_repository.dart';
import 'package:cryptox/data/repositories/wallet_repository.dart';
import 'package:cryptox/logic/bloc/admin_trace/admin_trace_bloc.dart';
import 'package:cryptox/logic/bloc/all_coin/all_coin_bloc.dart';
import 'package:cryptox/logic/bloc/coin/coin_bloc.dart';
import 'package:cryptox/logic/bloc/crypto_convert/crypto_convert_bloc.dart';
import 'package:cryptox/logic/bloc/digital_note/digital_note_bloc.dart';
import 'package:cryptox/logic/bloc/send_crypto/send_crypto_bloc.dart'; // Corrected import
import 'package:cryptox/logic/bloc/news/news_bloc.dart';
import 'package:cryptox/logic/bloc/payment/payment_bloc.dart';
import 'package:cryptox/logic/bloc/profile/profile_bloc.dart';
import 'package:cryptox/logic/bloc/signin/signin_bloc.dart';
import 'package:cryptox/logic/bloc/signup/signup_bloc.dart';
import 'package:cryptox/logic/bloc/wallet_balance/wallet_balance_bloc.dart';
import 'package:cryptox/logic/cubit/splash/splash_cubit.dart';
import 'package:cryptox/routes/route_pages.dart';
import 'package:cryptox/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final WalletRepository walletRepository;
  final CoinRepository coinRepository;
  final AdminRepository adminRepository;
  const MyApp({
    super.key,
    required this.authRepository,
    required this.walletRepository,
    required this.coinRepository,
    required this.adminRepository,
  });

  @override
  Widget build(BuildContext context) {
    // --- CORRECTED PROVIDER SETUP ---

    // 1. Provide all repositories at the top level.
    return MultiRepositoryProvider(
      providers: [
        // Use RepositoryProvider.value for repositories created outside this widget.
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: walletRepository),
        RepositoryProvider.value(value: coinRepository),
        RepositoryProvider.value(value: adminRepository),

        // Use RepositoryProvider(create: ...) for repositories created here.
        RepositoryProvider(create: (context) => AllCoinRepository()),
        RepositoryProvider(create: (context) => NewsRepository()),
        RepositoryProvider(create: (context) => DigitalNoteRepository()),
        RepositoryProvider(create: (context) => DigitalNoteRepository()),
      ],
      // 2. Provide all BLoCs, ensuring they use the repositories from the context.
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                DigitalNoteBloc(digitalNoteRepository: DigitalNoteRepository()),
          ),
          BlocProvider(
            create: (context) => SplashCubit(
              context.read<AuthRepository>(),
              FirebaseAuth.instance,
            ),
          ),
          BlocProvider(
            // SignupBloc needs AuthRepository.
            create: (context) => SignupBloc(context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) => SigninBloc(context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) => ProfileBloc(context.read<AuthRepository>()),
          ),
          BlocProvider(
            // Use the globally provided CoinRepository.
            create: (context) =>
                CoinBloc(coinRepository: context.read<CoinRepository>())
                  ..add(LoadCoins()),
          ),
          BlocProvider(
            create: (context) => AllCoinBloc(context.read<AllCoinRepository>()),
          ),
          BlocProvider(
            // Use the globally provided NewsRepository.
            create: (context) =>
                NewsBloc(newsRepository: context.read<NewsRepository>())
                  ..add(const LoadAllNewsArticles(page: 1)),
          ),
          BlocProvider(
            create: (context) => WalletBalanceBloc(
              walletRepository: context.read<WalletRepository>(),
            ),
          ),
          BlocProvider(
            // Use the corrected SendCryptoBloc instead of CryptoConvertBloc.
            create: (context) => SendCryptoBloc(
              walletRepository: context.read<WalletRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) =>
                PaymentBloc(walletRepository: context.read<WalletRepository>()),
          ),
          BlocProvider(
            create: (context) => CryptoConvertBloc(
              coinRepository: coinRepository,
              walletRepository: walletRepository,
            ),
          ),
          BlocProvider(
            create: (context) => AdminTraceBloc(
              adminRepository: context.read<AdminRepository>(),
            ),
          ),
        ],
        child: BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is LogoutSuccess) {
              context.read<WalletBalanceBloc>().add(ResetWalletBalance());
              RoutePages.ROUTER.goNamed(Routes.SIGNIN_ROUTE);
            }
          },
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
      ),
    );
  }
}

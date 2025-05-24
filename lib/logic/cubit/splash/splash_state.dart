part of 'splash_cubit.dart';

sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

final class SplashInitial extends SplashState {}

final class SplashEnd extends SplashState {
  final bool isAuthenticated;

  const SplashEnd({required this.isAuthenticated});

  @override
  List<Object?> get props => [isAuthenticated];
}

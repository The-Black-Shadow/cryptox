part of 'news_bloc.dart';

sealed class NewsState extends Equatable {
  const NewsState();
  
  @override
  List<Object> get props => [];
}

final class NewsInitial extends NewsState {}
final class NewsLoading extends NewsState {}
final class NewsLoaded extends NewsState {
  final List<Datum> articles; 
  const NewsLoaded(this.articles);
  @override
  List<Object> get props => [articles];
}
final class NewsError extends NewsState {
  final String message;
  const NewsError(this.message);
  @override
  List<Object> get props => [message];
}
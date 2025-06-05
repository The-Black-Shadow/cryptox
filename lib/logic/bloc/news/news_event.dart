part of 'news_bloc.dart';

sealed class NewsEvent extends Equatable {
  const NewsEvent();

  @override
  List<Object> get props => [];
}

class LoadAllNewsArticles extends NewsEvent {
  final int page;
  const LoadAllNewsArticles({this.page = 1}); // Default to page 1

  @override
  List<Object> get props => [page];
}

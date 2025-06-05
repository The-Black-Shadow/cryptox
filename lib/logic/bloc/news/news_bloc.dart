import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/news_model.dart'; // Your Datum model
import '../../../data/repositories/news_repository.dart';

part 'news_event.dart';
part 'news_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final NewsRepository newsRepository;

  NewsBloc({required this.newsRepository}) : super(NewsInitial()) {
    on<LoadAllNewsArticles>((event, emit) async {
      emit(NewsLoading());
      try {
        final articles = await newsRepository.fetchNewsArticles(
          page: event.page,
        );
        emit(NewsLoaded(articles));
      } catch (e) {
        emit(NewsError(e.toString()));
      }
    });
  }
}

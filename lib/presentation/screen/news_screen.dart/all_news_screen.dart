import 'package:cryptox/logic/bloc/news/news_bloc.dart';
import 'package:cryptox/presentation/widgets/news_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AllNewsView extends StatelessWidget {
  const AllNewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final double cardRowHeight = 250; // Or your chosen height

    return BlocBuilder<NewsBloc, NewsState>(
      builder: (context, state) {
        if (state is NewsLoading) {
          return SizedBox(
            height: cardRowHeight,
            child: const Center(child: CircularProgressIndicator()),
          );
        } else if (state is NewsLoaded) {
          if (state.articles.isEmpty) {
            return SizedBox(
              height: cardRowHeight,
              child: const Center(child: Text('No news available.')),
            );
          }
          return Container(
            height: cardRowHeight,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.articles.length,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemBuilder: (context, index) {
                final article = state.articles[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: NewsCardWidget(
                    article: article,
                  ), // Your NewsCardWidget
                );
              },
            ),
          );
        } else if (state is NewsError) {
          return SizedBox(
            height: cardRowHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Failed to load news: ${state.message}'),
              ),
            ),
          );
        }
        return SizedBox(
          height: cardRowHeight,
          child: const Center(child: Text('Loading news...')),
        );
      },
    );
  }
}

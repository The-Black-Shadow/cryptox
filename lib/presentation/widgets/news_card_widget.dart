import 'package:flutter/material.dart';
import '../../data/models/news_model.dart'; // Your Datum model
import '../../routes/route_pages.dart'; // Your route constants
import 'package:go_router/go_router.dart';

class NewsCardWidget extends StatelessWidget {
  final Datum article;

  const NewsCardWidget({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(Routes.NEWS_DETAIL_ROUTE, extra: article);
      },
      child: Container(
        width: 280, // Adjust width as desired for horizontal scrolling
        margin: const EdgeInsets.symmetric(
          vertical: 8.0,
        ), // Removed horizontal margin, handled by ListView padding
        child: Card(
          elevation: 3.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 3, // Image part
                child: Hero(
                  tag: article.heroTagImage,
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey[200], // Placeholder color
                    child: article.thumb2X.isNotEmpty
                        ? Image.network(
                            article.thumb2X,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                                ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ),
              Expanded(
                flex: 2, // Text part
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ), // Reduces vertical padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Center content vertically
                    children: <Widget>[
                      Hero(
                        tag: article.heroTagTitle,
                        child: Material(
                          // Required for Hero text transitions
                          type: MaterialType.transparency,
                          child: Text(
                            article.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        article.description, // Small portion of description
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2, // Show only 2 lines for a snippet
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cryptox/data/models/news_model.dart';
import 'package:flutter/material.dart'; // Your Datum model
import 'package:url_launcher/url_launcher.dart'; // For opening external links
import 'package:intl/intl.dart'; // For date formatting, add to pubspec.yaml

class NewsDetailScreen extends StatelessWidget {
  final Datum article;

  const NewsDetailScreen({super.key, required this.article});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Consider showing a snackbar or dialog on failure
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'MMM dd, yyyy hh:mm a',
    ).format(article.updatedAtDateTime.toLocal());

    return Scaffold(
      body: CustomScrollView(
        // Allows for flexible scrolling content with app bar
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 250.0, // Height of the image when expanded
            floating: false,
            pinned: true, // AppBar stays visible when scrolling
            flexibleSpace: FlexibleSpaceBar(
              title: Hero(
                // Hero for title
                tag: article.heroTagTitle,
                child: Material(
                  type: MaterialType.transparency,
                  child: Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 2.0)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              centerTitle: true, // Center title in the collapsed app bar
              background: Hero(
                // Hero for image
                tag: article.heroTagImage,
                child: article.thumb2X.isNotEmpty
                    ? Image.network(
                        article.thumb2X,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      article.title, // Full title again for context if needed
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        Icon(
                          Icons.source_outlined,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          // Allow news site name to wrap if long
                          child: Text(
                            article.newsSite,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'By: ${article.author.isNotEmpty ? article.author : "N/A"}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Icon(
                          Icons.update_outlined,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Updated: $formattedDate',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Divider(),
                    const SizedBox(height: 10.0),
                    Text(
                      "Summary:", // Label for description
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      article
                          .description, // "Full" description available from API
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 24.0),
                    if (article.url.isNotEmpty)
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () => _launchURL(article.url),
                          label: const Text('Read Full Article Online'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20.0), // Some bottom padding
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

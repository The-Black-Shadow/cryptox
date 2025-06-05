import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/news_model.dart'; // Import your News and Datum models

class NewsRepository {
  NewsRepository();
  
  final String? apiKey = dotenv.env['COINGECKO_API_KEY'];

  // Fetches a list of news articles (Datum objects)
  Future<List<Datum>> fetchNewsArticles({int page = 1}) async {
    final url = Uri.parse('https://api.coingecko.com/api/v3/news?page=$page');

    try {
      final response = await http.get(url);
      debugPrint('News API Response status code: ${response.statusCode}');
      // debugPrint('News API Response body: ${response.body}'); // For detailed debugging

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = json.decode(response.body);
        // Use your News.fromJson factory
        final News newsData = News.fromJson(decodedBody);
        debugPrint('Fetched ${newsData.data.length} news articles.');
        return newsData.data; // Return the list of Datum objects
      } else {
        debugPrint('Failed to load news. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load news (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error fetching news: $e');
      throw Exception('Failed to fetch news: $e');
    }
  }
}
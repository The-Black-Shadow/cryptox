// To parse this JSON data, do
//
//     final news = newsFromJson(jsonString);

import 'dart:convert';

import 'package:equatable/equatable.dart';

News newsFromJson(String str) => News.fromJson(json.decode(str));

String newsToJson(News data) => json.encode(data.toJson());

class News extends Equatable {
  final List<Datum> data;

  const News({required this.data});

  factory News.fromJson(Map<String, dynamic> json) =>
      News(data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))));

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
  @override
  List<Object?> get props => [data];
}

class Datum {
  int id;
  String title;
  String description;
  String author;
  String url;
  // int crawledAt;
  // int createdAt;
  int updatedAt;
  String newsSite;
  String thumb2X;

  Datum({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.url,
    // required this.crawledAt,
    // required this.createdAt,
    required this.updatedAt,
    required this.newsSite,
    required this.thumb2X,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    id: json["id"] ?? 0, // Provide default if ID can be null
    title: json["title"] ?? 'No Title',
    description: json["description"] ?? 'No Description',
    author: json["author"] ?? 'Unknown Author',
    url: json["url"] ?? '',
    // crawledAt: json["crawled_at"] ?? 0,
    // createdAt: json["created_at"] ?? 0,
    updatedAt:
        json["updated_at"] ??
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Default to now if null
    newsSite: json["news_site"] ?? 'Unknown Site',
    thumb2X:
        json["thumb_2x"] ?? '', // Provide default empty string if can be null
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "description": description,
    "author": author,
    "url": url,
    // "crawled_at": crawledAt,
    // "created_at": createdAt,
    "updated_at": updatedAt,
    "news_site": newsSite,
    "thumb_2x": thumb2X,
  };

  // Helper to get DateTime object
  DateTime get updatedAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(updatedAt * 1000);

  // Hero Tags (use unique ID or URL)
  String get heroTagImage => 'newsImage_$id'; // Using ID
  String get heroTagTitle => 'newsTitle_$id'; // Using ID
}

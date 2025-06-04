import 'dart:convert';

import 'package:cryptox/data/models/coin_model.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AllCoinRepository {
  AllCoinRepository();
  final apiKey = dotenv.env['COINGECKO_API_KEY'];
  Future<List<Coin>> fetchAllCoins() async {
    final url = Uri.parse(
      'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd',
    );

    final response = await http.get(
      url,
      headers: {'x-cg-demo-api-key': apiKey ?? ''},
    );
    debugPrint('Response status code: ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      debugPrint('Fetched Allcoins: $data');
      return data.map((json) => Coin.fromJson(json)).toList();
    } else {
      throw Exception('Failed to all load coins');
    }
  }
}

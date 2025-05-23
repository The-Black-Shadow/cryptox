import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get coinGeckoApiKey => dotenv.env['COINGECKO_API_KEY'] ?? '';
  static String get stripeKey => dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  static String get myCoinSymbol => dotenv.env['MY_COIN_SYMBOL'] ?? 'X';
}

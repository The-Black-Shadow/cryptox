class Coin {
  final String id;
  final String symbol;
  final String name;
  final double currentPrice;
  final double priceChangePercentage24h;
  final String image;

  Coin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.priceChangePercentage24h,
    required this.image,
  });

  factory Coin.fromJson(Map<String, dynamic> json) => Coin(
    id: json['id'],
    symbol: json['symbol'],
    name: json['name'],
    currentPrice: json['current_price']?.toDouble() ?? 0.0,
    priceChangePercentage24h:
        json['price_change_percentage_24h']?.toDouble() ?? 0.0,
    image: json['image'] ?? '',
  );
}

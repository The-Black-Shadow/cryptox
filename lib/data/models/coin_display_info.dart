import 'package:equatable/equatable.dart';

class CoinDisplayInfo extends Equatable {
  final String firestoreKey;   // e.g., "bitcoin", "ethereum" (for CryptoBalance model)
  final String coinGeckoId;    // e.g., "bitcoin", "ethereum" (for CoinGecko API)
  final String displayName;    // e.g., "Bitcoin", "Ethereum"
  final String symbol;         // e.g., "BTC", "ETH"
  // final String? imageUrl;

  const CoinDisplayInfo({
    required this.firestoreKey,
    required this.coinGeckoId,
    required this.displayName,
    required this.symbol,
    // this.imageUrl,
  });

  @override
  List<Object?> get props => [firestoreKey, coinGeckoId, displayName, symbol];
}

// Updated list with coinGeckoId (assuming they match firestoreKey for these common coins)
// Verify these IDs against CoinGecko's actual coin list if unsure.
const List<CoinDisplayInfo> supportedCoinsDisplayInfo = [
  CoinDisplayInfo(firestoreKey: 'bitcoin', coinGeckoId: 'bitcoin', displayName: 'Bitcoin', symbol: 'BTC'),
  CoinDisplayInfo(firestoreKey: 'ethereum', coinGeckoId: 'ethereum', displayName: 'Ethereum', symbol: 'ETH'),
  CoinDisplayInfo(firestoreKey: 'bnb', coinGeckoId: 'binancecoin', displayName: 'BNB', symbol: 'BNB'), // CoinGecko ID for BNB is often 'binancecoin'
  CoinDisplayInfo(firestoreKey: 'x', coinGeckoId: 'xrp', displayName: 'X Token (XRP)', symbol: 'XRP'), // Assuming 'x' refers to XRP and its ID is 'xrp'. Adjust as needed.
];
import 'package:equatable/equatable.dart';

class CoinDisplayInfo extends Equatable {
  final String firestoreKey; // e.g., "bitcoin", "ethereum"
  final String displayName; // e.g., "Bitcoin", "Ethereum"
  final String symbol; // e.g., "BTC", "ETH"
  // final String? imageUrl; // Optional: if you have image URLs

  const CoinDisplayInfo({
    required this.firestoreKey,
    required this.displayName,
    required this.symbol,
    // this.imageUrl,
  });

  @override
  List<Object?> get props => [firestoreKey, displayName, symbol];
}

// Predefined list of supported coins that match your CryptoBalance model fields
// This list determines what's shown in dropdowns and how balances are accessed.
const List<CoinDisplayInfo> supportedCoinsDisplayInfo = [
  CoinDisplayInfo(
    firestoreKey: 'bitcoin',
    displayName: 'Bitcoin',
    symbol: 'BTC',
  ),
  CoinDisplayInfo(
    firestoreKey: 'ethereum',
    displayName: 'Ethereum',
    symbol: 'ETH',
  ),
  CoinDisplayInfo(firestoreKey: 'bnb', displayName: 'BNB', symbol: 'BNB'),
  CoinDisplayInfo(
    firestoreKey: 'x',
    displayName: 'X Token',
    symbol: 'X',
  ), // Adjust display name/symbol for 'x' as needed
];

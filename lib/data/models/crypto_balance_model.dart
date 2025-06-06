import 'dart:convert';
import 'package:equatable/equatable.dart'; // For good practice, add to pubspec if not already there

// Helper functions remain the same
CryptoBalance cryptoBalanceFromJson(String str) =>
    CryptoBalance.fromJson(json.decode(str));
String cryptoBalanceToJson(CryptoBalance data) => json.encode(data.toJson());

class CryptoBalance extends Equatable {
  // Extend Equatable for value comparison
  final double bitcoin; // Changed to double
  final double ethereum; // Changed to double
  final double bnb; // Changed to double
  final double x; // Changed to double (assuming 'x' is also a balance)
  final double tether;

  const CryptoBalance({
    // Added const
    required this.bitcoin,
    required this.ethereum,
    required this.bnb,
    required this.x,
    required this.tether,
  });

  factory CryptoBalance.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse a value to double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0; // Default fallback
    }

    return CryptoBalance(
      bitcoin: parseDouble(json["bitcoin"]),
      ethereum: parseDouble(json["ethereum"]),
      bnb: parseDouble(json["bnb"]),
      x: parseDouble(json["x"]),
      tether: parseDouble(json["tether"]), // Added tether
    );
  }

  Map<String, dynamic> toJson() => {
    "bitcoin": bitcoin, // Will now be a double
    "ethereum": ethereum, // Will now be a double
    "bnb": bnb, // Will now be a double
    "x": x, // Will now be a double
    "tether": tether, // Added tether
  };

  @override
  List<Object?> get props => [bitcoin, ethereum, bnb, x]; // For Equatable
}

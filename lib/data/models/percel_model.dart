import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ParcelModel extends Equatable {
  final String parcelId;
  final double amount;
  final String receivedFromUserId;
  final String originTransactionId;
  final Timestamp receivedAt;

  const ParcelModel({
    required this.parcelId,
    required this.amount,
    required this.receivedFromUserId,
    required this.originTransactionId,
    required this.receivedAt,
  });

  factory ParcelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParcelModel(
      parcelId: doc.id,
      amount: (data['amount'] as num).toDouble(),
      receivedFromUserId: data['receivedFromUserId'] ?? '',
      originTransactionId: data['originTransactionId'] ?? '',
      receivedAt: data['receivedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'receivedFromUserId': receivedFromUserId,
      'originTransactionId': originTransactionId,
      'receivedAt': receivedAt,
    };
  }

  @override
  List<Object?> get props => [parcelId, amount, receivedAt];
}
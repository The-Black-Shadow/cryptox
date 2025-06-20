import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a single transaction record from the 'digital_note_transactions' ledger.
class DigitalNoteTransactionModel extends Equatable {
  final String transactionId;
  final String senderId;
  final String senderEmail;
  final String recipientId;
  final String recipientEmail;
  final double totalSentAmount;
  final Timestamp timestamp;

  const DigitalNoteTransactionModel({
    required this.transactionId,
    required this.senderId,
    required this.senderEmail,
    required this.recipientId,
    required this.recipientEmail,
    required this.totalSentAmount,
    required this.timestamp,
  });

  factory DigitalNoteTransactionModel.fromJson(Map<String, dynamic> json) {
    return DigitalNoteTransactionModel(
      transactionId: json['transactionId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderEmail: json['senderEmail'] ?? 'N/A',
      recipientId: json['recipientId'] ?? '',
      recipientEmail: json['recipientEmail'] ?? 'N/A',
      totalSentAmount: (json['totalSentAmount'] as num? ?? 0).toDouble(),
      timestamp: json['timestamp'] as Timestamp,
    );
  }

  @override
  List<Object?> get props => [transactionId];
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class TransactionRecordModel extends Equatable {
  final String transactionId;
  final String status;
  final String transactionType;
  final Timestamp timestamp;
  final String coinType;
  final double totalAmount;
  final String fromUserId;
  final String fromUserEmail;
  final String toUserId;
  final String toUserEmail;
  final List<String> inputParcelIds; // For efficient querying
  final List<Map<String, dynamic>> inputs;
  final List<Map<String, dynamic>> outputs;

  const TransactionRecordModel({
    required this.transactionId,
    required this.status,
    required this.transactionType,
    required this.timestamp,
    required this.coinType,
    required this.totalAmount,
    required this.fromUserId,
    required this.fromUserEmail,
    required this.toUserId,
    required this.toUserEmail,
    required this.inputParcelIds,
    required this.inputs,
    required this.outputs,
  });

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'status': status,
      'transactionType': transactionType,
      'timestamp': timestamp,
      'coinType': coinType,
      'totalAmount': totalAmount,
      'fromUserId': fromUserId,
      'fromUserEmail': fromUserEmail,
      'toUserId': toUserId,
      'toUserEmail': toUserEmail,
      'inputParcelIds': inputParcelIds,
      'inputs': inputs,
      'outputs': outputs,
    };
  }

  factory TransactionRecordModel.fromJson(Map<String, dynamic> json) {
    return TransactionRecordModel(
      transactionId: json['transactionId'] ?? '',
      status: json['status'] ?? 'unknown',
      transactionType: json['transactionType'] ?? 'send',
      timestamp: json['timestamp'] as Timestamp,
      coinType: json['coinType'] ?? '',
      totalAmount: (json['totalAmount'] as num? ?? 0).toDouble(),
      fromUserId: json['fromUserId'] ?? '',
      fromUserEmail: json['fromUserEmail'] ?? 'N/A',
      toUserId: json['toUserId'] ?? '',
      toUserEmail: json['toUserEmail'] ?? 'N/A',
      inputParcelIds: List<String>.from(json['inputParcelIds'] ?? []),
      inputs: List<Map<String, dynamic>>.from(json['inputs'] ?? []),
      outputs: List<Map<String, dynamic>>.from(json['outputs'] ?? []),
    );
  }

  @override
  List<Object?> get props => [transactionId];
}
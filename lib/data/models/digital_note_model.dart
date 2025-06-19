import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class DigitalNoteModel extends Equatable {
  final String noteId;
  final String serialNumber;
  final double denomination;
  final String ownerUserId;
  final String status;
  final Map<String, dynamic> originatorInfo;
  final List<Map<String, dynamic>> history;

  const DigitalNoteModel({
    required this.noteId,
    required this.serialNumber,
    required this.denomination,
    required this.ownerUserId,
    required this.status,
    required this.originatorInfo,
    required this.history,
  });

  factory DigitalNoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DigitalNoteModel(
      noteId: doc.id,
      serialNumber: data['serialNumber'] ?? '',
      denomination: (data['denomination'] as num? ?? 0).toDouble(),
      ownerUserId: data['ownerUserId'] ?? '',
      status: data['status'] ?? 'unknown',
      originatorInfo: Map<String, dynamic>.from(data['originatorInfo'] ?? {}),
      history: List<Map<String, dynamic>>.from(data['history'] ?? []),
    );
  }

  // --- ADDED THIS METHOD ---
  // This method converts the Dart object into a Map that can be saved to Firestore.
  Map<String, dynamic> toJson() {
    return {
      'serialNumber': serialNumber,
      'denomination': denomination,
      'ownerUserId': ownerUserId,
      'status': status,
      'originatorInfo': originatorInfo,
      'history': history,
    };
  }

  // Helper to get the email of the user who last sent this note
  String get receivedFromEmail {
    if (history.isEmpty) return 'System Deposit';
    if (originatorInfo['adminEmail'] != null) {
      return 'Admin Deposit';
    }
    return history.last['fromUserEmail'] ?? 'Unknown Sender';
  }

  @override
  List<Object?> get props => [
    noteId,
    serialNumber,
    denomination,
    ownerUserId,
    status,
  ];
}

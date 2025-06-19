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

  /// Correctly determines the last sender of the note.
  String get receivedFromEmail {
    if (history.isEmpty) {
      return 'System Origin';
    }

    final lastEvent = history.last;
    final fromUserId = lastEvent['fromUserId'];

    if (fromUserId == 'deposit_system') {
      return originatorInfo['adminEmail'] as String? ?? 'Admin Deposit';
    }
    if (fromUserId == ownerUserId) {
      return 'Change from a previous transaction';
    }

    return lastEvent['fromUserEmail'] as String? ?? 'An Anonymous User';
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

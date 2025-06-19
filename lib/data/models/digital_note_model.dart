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

  // --- THIS IS THE CORRECTED LOGIC ---
  /// Helper to get the email of the user who last sent this note.
  String get receivedFromEmail {
    if (history.isEmpty) {
      return 'System'; // Should not happen with new logic, but a safe fallback.
    }

    // Get the most recent event from the note's history.
    final lastEvent = history.last;
    final fromUserId = lastEvent['fromUserId'];

    // Check for special cases first.
    if (fromUserId == 'deposit_system') {
      return 'Admin Deposit';
    }
    // If the note was sent from the owner to themselves, it's "change".
    if (fromUserId == ownerUserId) {
      return 'Change from transaction';
    }

    // Otherwise, return the email of the sender from the last transaction.
    return lastEvent['fromUserEmail'] ?? 'Unknown User';
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

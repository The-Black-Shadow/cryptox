import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptox/data/models/transaction_record_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<TransactionRecordModel>> fetchRecentTransactions({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => TransactionRecordModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print("Error fetching recent transactions: $e");
      throw Exception("Could not load recent transactions.");
    }
  }

  Future<TransactionRecordModel?> traceTransactionById(String transactionId) async {
    try {
      final docSnapshot = await _firestore
          .collection('transactions')
          .doc(transactionId.trim())
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return TransactionRecordModel.fromJson(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      print("Error tracing transaction by ID: $e");
      throw Exception("Could not find transaction.");
    }
  }
  
  Future<TransactionRecordModel?> findTransactionByInputParcel(String parcelId) async {
    try {
      // --- THIS IS THE CORRECTED QUERY ---
      // The operator is now a named parameter: `arrayContains`
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('inputParcelIds', arrayContains: parcelId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return TransactionRecordModel.fromJson(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print("Error finding transaction by input parcel: $e");
      throw Exception("Could not trace parcel forward.");
    }
  }
}
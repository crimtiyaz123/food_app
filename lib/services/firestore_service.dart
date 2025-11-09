import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService<T> {
  final String collectionPath;
  final T Function(Map<String, dynamic> data, String documentId) fromMap;

  FirestoreService({required this.collectionPath, required this.fromMap});

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create / Add document
  Future<void> addDocument(Map<String, dynamic> data, {String? docId}) async {
    try {
      if (docId != null) {
        await _db.collection(collectionPath).doc(docId).set(data);
      } else {
        await _db.collection(collectionPath).add(data);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Read all documents
  Stream<List<T>> getDocuments() {
    return _db.collection(collectionPath).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Read single document
  Future<T?> getDocument(String docId) async {
    try {
      final doc = await _db.collection(collectionPath).doc(docId).get();
      if (doc.exists) {
        return fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update document
  Future<void> updateDocument(String docId, Map<String, dynamic> data) async {
    try {
      await _db.collection(collectionPath).doc(docId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Delete document
  Future<void> deleteDocument(String docId) async {
    try {
      await _db.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      rethrow;
    }
  }
}

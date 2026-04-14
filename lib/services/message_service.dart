import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class MessageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'messages';
  static const String _reportedCollection = 'messages_pending_review_reported_collection';
  static const String _trackedCollection = 'tracked_pigeons';

  // saves it to firestore
  Future<String> saveMessage(Message message) async {
    try {
      final data = message.toJson();
      
      data['created_at'] = FieldValue.serverTimestamp();

      final docRef = await _db.collection(_collection).add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save message: $e');
    }
  }

  // updates a message's health and hops
  // this is definitely something we should move to the backend eventually
  // like it should be handled automatically on the backend instead of updated from here
  Future<void> updateMessage(String messageId, int health, int hops) async {
    try {
      await _db.collection(_collection).doc(messageId).update({
        'health': health,
        'hops': hops,
      });
    } catch (e) {
      throw Exception('Failed to update message: $e');
    }
  }

  // deletes a message when health drops to 0
  // this is also something we should move to the backend API eventually
  Future<void> deleteMessage(String messageId) async {
    try {
      await _db.collection(_collection).doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<void> reportMessage({
    required String messageId,
    required String reportedByRoostId,
  }) async {
    try {
      final originalRef = _db.collection(_collection).doc(messageId);
      final reportedRef = _db.collection(_reportedCollection).doc(messageId);

      final snapshot = await originalRef.get();

      if (!snapshot.exists) {
        throw Exception('Message does not exist.');
      }

      final data = snapshot.data()!;

      final batch = _db.batch();

      batch.set(reportedRef, {
        ...data,
        'original_message_id': messageId,
        'reported_by_roost_id': reportedByRoostId,
        'reported_at': FieldValue.serverTimestamp(),
        'moved_from': _collection,
      });

      batch.delete(originalRef);

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to report message: $e');
    }
  }


  Future<int> getTrackedCount(String trackedByRoostId) async {
    try {
      final snapshot = await _db
          .collection(_trackedCollection)
          .where('tracked_by_roost_id', isEqualTo: trackedByRoostId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get tracked pigeon count: $e');
    }
  }

  Future<void> trackMessage({
    required String messageId,
    required String trackedByRoostId,
  }) async {
    try {
      final trackedRef = _db
          .collection(_trackedCollection)
          .doc('${trackedByRoostId}_$messageId');

      final existing = await trackedRef.get();
      if (existing.exists) {
        return;
      }

      final trackedCount = await getTrackedCount(trackedByRoostId);
      if (trackedCount >= 3) {
        throw Exception('You can only track up to 3 pigeons at a time.');
      }

      await trackedRef.set({
        'message_id': messageId,
        'tracked_by_roost_id': trackedByRoostId,
        'tracked_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to track pigeon: $e');
    }
  }

  Future<void> untrackMessage({
    required String messageId,
    required String trackedByRoostId,
  }) async {
    try {
      await _db
          .collection(_trackedCollection)
          .doc('${trackedByRoostId}_$messageId')
          .delete();
    } catch (e) {
      throw Exception('Failed to untrack pigeon: $e');
    }
  }


}

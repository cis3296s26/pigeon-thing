import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class MessageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'messages';

  // saves it to firestore
  Future<String> saveMessage(Message message) async {
    try {
      final docRef = await _db.collection(_collection).add(message.toJson());
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
}

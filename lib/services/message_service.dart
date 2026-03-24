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
}

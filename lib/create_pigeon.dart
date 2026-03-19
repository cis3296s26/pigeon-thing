import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreatePigeon extends StatefulWidget {
  const CreatePigeon({super.key});

  @override
  State<CreatePigeon> createState() => _CreatePigeonState();
}

class _CreatePigeonState extends State<CreatePigeon> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    print('1: send pressed');
    print('2: before firestore add');

    try {
      await FirebaseFirestore.instance
          .collection('messages')
          .add({
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 10));

      print('3: firestore add completed');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message uploaded.')),
      );
    } catch (e) {
      print('ERROR: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      print('4: finally block hit');

      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
  }
}

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create and Customize Your Pigeon Here!'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter your pigeon message',
                hintText: 'Type a message to upload to Firebase',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSending ? null : _sendMessage,
              child: Text(_isSending ? 'Sending...' : 'Send'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
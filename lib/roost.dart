import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Roost extends StatefulWidget {
  const Roost({super.key});

  @override
  State<Roost> createState() => _RoostState();
}

class _RoostState extends State<Roost> {

  String? loadedMessage;
  bool isLoading = false;

  Future<void> _loadEarliestMessage() async {
    setState(() {
      isLoading = true;
    });

    print('R1: load pressed');
    print('R2: before firestore read');

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      print('R3: firestore read completed');

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          loadedMessage = 'No messages found.';
        });
      } else {
        final data = querySnapshot.docs.first.data();
        setState(() {
          loadedMessage = data['text'] ?? 'Message was empty.';
        });
      }
    } catch (e) {
      print('ROOST ERROR: $e');
      setState(() {
        loadedMessage = 'Error loading message: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
      print('R4: finally hit');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roost'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              loadedMessage ?? 'No message loaded yet.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isLoading ? null : _loadEarliestMessage,
              child: Text(isLoading ? 'Loading...' : 'Load Message'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
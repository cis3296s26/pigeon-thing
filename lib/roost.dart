import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Roost extends StatelessWidget {
  final List<String> notifications = List.generate(40, (i) => "Notification ${i + 1}: Pigeon In Roost");

  Roost({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roost')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return Text(notifications[index]);
                },
              ),
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

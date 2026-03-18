import 'package:flutter/material.dart';

class CreatePigeon extends StatelessWidget {
  const CreatePigeon({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create and Customize Your Pigeon Here!')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // go back
          },
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}

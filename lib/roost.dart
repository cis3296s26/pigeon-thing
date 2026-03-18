import 'package:flutter/material.dart';

class Roost extends StatelessWidget {
  const Roost({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second Page')),
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

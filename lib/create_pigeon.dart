import 'package:flutter/material.dart';
import 'services/message_service.dart';
import 'services/roost_service.dart';
import 'models/message.dart';

class CreatePigeon extends StatefulWidget {
  const CreatePigeon({super.key});

  @override
  State<CreatePigeon> createState() => _CreatePigeonState();
}

class _CreatePigeonState extends State<CreatePigeon> {
  final TextEditingController _messageController = TextEditingController();
  final MessageService _messageService = MessageService();
  final RoostService _roostService = RoostService.getInstance();
  bool _isSending = false;

  int _headIndex = 0;
  int _torsoIndex = 0;
  int _legsIndex = 0;

  final List<String> heads = ['assets/heads/Head10.png','assets/heads/Head20.png','assets/heads/Head30.png','assets/heads/Head40.png'];
  final List<String> torsos = ['assets/Torsos/Body10.png','assets/Torsos/Body20.png'];
  final List<String> legs = ['assets/Legs/Feet10.png', 'assets/Legs/Feet20.png', 'assets/Legs/Feet30.png'];

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();

    if (messageText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a message')));
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // get the roost ID from local storage
      final roostId = await _roostService.getRoostId();

      final message = Message.create(
        body: _torsoIndex,
        head: _headIndex,
        legs: _legsIndex,
        message: messageText,
        originRoostId: roostId,
      );

      await _messageService.saveMessage(message);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pigeon released into the world!')),
      );

      // it would be cool to have a little animation play or something

      // clear
      _messageController.clear();
      setState(() {
        _headIndex = 0;
        _torsoIndex = 0;
        _legsIndex = 0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send pigeon: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Widget piecesSelector({
    required String label,
    required List<String> items,
    required int currentIndex,
    required Function(int) onChanged,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 18)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_left),
              onPressed: () {
                int newIndex = (currentIndex - 1 + items.length) % items.length;
                onChanged(newIndex);
              },
            ),
            Image.asset(items[currentIndex], width: 100, height: 100, errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.error);
            },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_right),
              onPressed: () {
                int newIndex = (currentIndex + 1) % items.length;
                onChanged(newIndex);
              },
            ),
          ],
        ),
      ],
    );
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('Preview', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              SizedBox(
                height: 325,
                child: 
                Stack(
                  children: [
                    // Torso (center anchor)
                    Center(
                      child: Image.asset(
                        torsos[_torsoIndex],
                        height: 134,
                      ),
                    ),

                    // Head (move up)
                    Positioned(
                      top: 5,
                      left: 82.4,
                      right: 0,
                      child: Center(
                        child: Image.asset(
                          heads[_headIndex],
                          height: 102,
                        ),
                      ),
                    ),

                    // Legs (move down)
                    Positioned(
                      bottom: 86.3,
                      left: 0,
                      right: .6,
                      child: Center(
                        child: Image.asset(
                          legs[_legsIndex],
                          height: 50,
                        ),
                      ),
                    ),
                  ],
                )
              ),
              const SizedBox(height: 15),
              piecesSelector(
                label: 'Head',
                items: heads,
                currentIndex: _headIndex,
                onChanged: (i) => setState(() => _headIndex = i),
              ),
              piecesSelector(
                label: 'Torso',
                items: torsos,
                currentIndex: _torsoIndex,
                onChanged: (i) => setState(() => _torsoIndex = i),
              ),
              piecesSelector(
                label: 'Legs',
                items: legs,
                currentIndex: _legsIndex,
                onChanged: (i) => setState(() => _legsIndex = i),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Message for your pigeon',
                  hintText: 'What should your pigeon say?',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSending ? null : _sendMessage,
                child: Text(_isSending ? 'Releasing...' : 'Release Pigeon'),
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
      ),
    );
  }
}

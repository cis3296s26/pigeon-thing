import 'package:flutter/material.dart';
import 'services/message_service.dart';
import 'services/roost_service.dart';
import 'models/message.dart';
import 'package:confetti/confetti.dart';
import 'widgets/recolor_image.dart';
import 'widgets/app_layout.dart';

class CreatePigeon extends StatefulWidget {
  const CreatePigeon({super.key});

  @override
  State<CreatePigeon> createState() => _CreatePigeonState();
}

class _CreatePigeonState extends State<CreatePigeon> {
  final TextEditingController _messageController = TextEditingController();
  final MessageService _messageService = MessageService();
  final RoostService _roostService = RoostService.getInstance();

  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;
  bool _trackThisPigeon = false;

  int _headIndex = 0;
  int _torsoIndex = 0;
  int _legsIndex = 0;


  Color _pigeonColor = Colors.grey;

  late ConfettiController _confettiController;

  final List<String> heads = [
    'assets/heads/Head10.png',
    'assets/heads/Head20.png',
    'assets/heads/Head30.png',
    'assets/heads/Head40.png'
  ];

  final List<String> torsos = [
    'assets/Torsos/Body10.png',
    'assets/Torsos/Body20.png'
  ];

  final List<String> legs = [
    'assets/Legs/Feet10.png',
    'assets/Legs/Feet20.png',
    'assets/Legs/Feet30.png'
  ];

  @override
  void initState() {
    super.initState();

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });

  }

  @override
  void dispose() {
    _messageController.dispose();
    _confettiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();

    if (messageText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final roostId = await _roostService.getRoostId();

      final message = Message.create(
        body: _torsoIndex,
        head: _headIndex,
        legs: _legsIndex,
        message: messageText,
        originRoostId: roostId,
        color: _pigeonColor.value,
      );

      await _messageService.saveMessage(message);

      _confettiController.play();

      _messageController.clear();

      setState(() {
        _headIndex = 0;
        _torsoIndex = 0;
        _legsIndex = 0;
        _trackThisPigeon = false;
        _pigeonColor = Colors.grey; // 🔥 reset color (optional)
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      setState(() => _isSending = false);
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
                int newIndex =
                    (currentIndex - 1 + items.length) % items.length;
                onChanged(newIndex);
              },
            ),
            Image.asset(items[currentIndex], width: 100, height: 100),
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

  Widget _colorPicker(Color current, Function(Color) onSelected) {
    final colors = [
      Colors.grey,
      const Color.fromARGB(255, 141, 182, 216),
      const Color.fromARGB(255, 121, 185, 123),
      const Color.fromARGB(255, 149, 85, 80),
      const Color.fromARGB(255, 143, 90, 152),
      const Color.fromARGB(255, 99, 75, 40),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: colors.map((c) {
        return GestureDetector(
          onTap: () => onSelected(c),
          child: Container(
            margin: const EdgeInsets.all(4),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: current == c ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: Stack(
        children: [

          Padding(
            padding: const EdgeInsets.only(top: 360),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
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
                  const Text('Pigeon Color'),

                  _colorPicker(
                    _pigeonColor,
                    (c) => setState(() => _pigeonColor = c),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Message',
                    ),
                  ),

                  ElevatedButton(
                    onPressed: _isSending ? null : _sendMessage,
                    child: Text(
                        _isSending ? 'Releasing...' : 'Release Pigeon'),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),

          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: AbsorbPointer(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Create Pigeon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(
                    height: 325,
                    child: Stack(
                      children: [
                        Center(
                          child: RecolorImage(
                            key: ValueKey(torsos[_torsoIndex]),
                            assetPath: torsos[_torsoIndex],
                            color: _pigeonColor,
                            height: 134,
                          ),
                        ),
                        Positioned(
                          top: 5,
                          left: 82.4,
                          right: 0,
                          child: Center(
                            child: RecolorImage(
                              key: ValueKey(heads[_headIndex]),
                              assetPath: heads[_headIndex],
                              color: _pigeonColor,
                              height: 102,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 86.3,
                          left: 0,
                          right: .6,
                          child: Center(
                            child: RecolorImage(
                              key: ValueKey(legs[_legsIndex]),
                              assetPath: legs[_legsIndex],
                              color: _pigeonColor,
                              height: 50,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
          ),
          
          Positioned(
            top: 10,
            left: 10,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

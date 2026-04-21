import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'services/message_service.dart';
import 'services/roost_service.dart';
import 'widgets/pigeon.dart';
import 'widgets/app_layout.dart';

class Roost extends StatefulWidget {
  String deviceId;

  Roost({super.key, required this.deviceId});

  @override
  State<Roost> createState() => _RoostState();
}

class _RoostState extends State<Roost> {
  String? loadedMessage;
  String? loadedHead;
  String? loadedBody;
  String? loadedLegs;
  int? loadedHealth;
  int? loadedHops;
  String? loadedOriginRoostId;
  String? loadedMessageId;
  int? loadedColor;

  bool isLoading = false;
  bool isTracked = false;

  @override
  void initState() {
    super.initState();
    _loadRandomEligibleMessage();
  }

  final List<String> heads = [
    'assets/heads/Head10.png',
    'assets/heads/Head20.png',
    'assets/heads/Head30.png',
    'assets/heads/Head40.png',
  ];

  final List<String> torsos = [
    'assets/Torsos/Body10.png',
    'assets/Torsos/Body20.png',
  ];

  final List<String> legs = [
    'assets/Legs/Feet10.png',
    'assets/Legs/Feet20.png',
    'assets/Legs/Feet30.png',
  ];

  final List<String> hearts = [
    'assets/Hearts/39.png',
    'assets/Hearts/38.png',
    'assets/Hearts/37.png',
    'assets/Hearts/36.png',
    'assets/Hearts/35.png',
    'assets/Hearts/34.png',
    'assets/Hearts/33.png',
    'assets/Hearts/32.png',
    'assets/Hearts/31.png',
    'assets/Hearts/30.png',
    'assets/Hearts/29.png',
    'assets/Hearts/28.png',
    'assets/Hearts/27.png',
    'assets/Hearts/26.png',
    'assets/Hearts/25.png',
    'assets/Hearts/24.png',
    'assets/Hearts/23.png',
    'assets/Hearts/22.png',
    'assets/Hearts/21.png',
    'assets/Hearts/20.png',
    'assets/Hearts/19.png',
    'assets/Hearts/18.png',
    'assets/Hearts/17.png',
    'assets/Hearts/16.png',
    'assets/Hearts/15.png',
    'assets/Hearts/14.png',
    'assets/Hearts/13.png',
    'assets/Hearts/12.png',
    'assets/Hearts/11.png',
    'assets/Hearts/10.png',
  ];

  final RoostService _roostService = RoostService.getInstance();
  final MessageService _messageService = MessageService();

  Future<void> _loadRandomEligibleMessage() async {
    final canRequest = await _roostService.canRequestNewPigeon();
    if (!canRequest) {
      setState(() {
        loadedMessage = null;
        loadedHead = null;
        loadedBody = null;
        loadedLegs = null;
        loadedHealth = null;
        loadedHops = null;
        loadedOriginRoostId = null;
        loadedMessageId = null;
        loadedColor = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      loadedMessage = null;
      loadedHead = null;
      loadedBody = null;
      loadedLegs = null;
      loadedHealth = null;
      loadedHops = null;
      loadedOriginRoostId = null;
      loadedMessageId = null;
      loadedColor = null;
    });

    final roostId = await _roostService.getRoostId();

    final trackedSnapshot = await FirebaseFirestore.instance
        .collection('tracked_pigeons')
        .where('tracked_by_roost_id', isEqualTo: roostId)
        .where('message_id', isEqualTo: loadedMessageId)
        .get();

    setState(() {
      isTracked = trackedSnapshot.docs.isNotEmpty;
    });

    widget.deviceId = await _roostService.getRoostId();

    final snapshot =
        await FirebaseFirestore.instance.collection('messages').get();

    final docs = snapshot.docs;
    docs.shuffle(Random());

    QueryDocumentSnapshot<Map<String, dynamic>>? selectedDoc;

    String? selectedOrigin;

    for (final doc in docs) {
      final data = doc.data();
      final origin = (data['origin_roost_id'] ?? '').toString();

      if (origin.isEmpty || origin == widget.deviceId) continue;

      final travelLogSnapshot = await FirebaseFirestore.instance
          .collection('travel_logs')
          .where('message_id', isEqualTo: doc.id)
          .where('destination_roost_id', isEqualTo: widget.deviceId)
          .limit(1)
          .get();

      if (travelLogSnapshot.docs.isNotEmpty) continue;

      selectedDoc = doc;
      selectedOrigin = origin;
      break;
    }

    if (selectedDoc == null) return;

    final data = selectedDoc.data();

    setState(() {
      loadedMessage = data['message'];
      loadedHead = data['head'].toString();
      loadedBody = data['body'].toString();
      loadedLegs = data['legs'].toString();
      loadedHealth = data['health'] ?? 10;
      loadedHops = data['hops'] ?? 0;
      loadedMessageId = selectedDoc!.id;
      loadedColor = data['color'] ?? 0xFF808080;
    });

    await FirebaseFirestore.instance.collection('travel_logs').add({
      'message_id': selectedDoc.id,
      'source_roost_id': selectedOrigin,
      'destination_roost_id': widget.deviceId,
      'delivered_at': FieldValue.serverTimestamp(),
    });

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _untrackPigeon() async {
    if (loadedMessageId == null) return;

    final roostId = await _roostService.getRoostId();

    final snapshot = await FirebaseFirestore.instance
        .collection('tracked_pigeons')
        .where('roost_id', isEqualTo: roostId)
        .where('message_id', isEqualTo: loadedMessageId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _trackPigeon() async {
    if (loadedMessageId == null) return;

    final roostId = await _roostService.getRoostId();

    final snapshot = await FirebaseFirestore.instance
        .collection('tracked_pigeons')
        .where('tracked_by_roost_id', isEqualTo: roostId)
        .get();

    if (snapshot.docs.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only track 5 pigeons')),
      );
      return;
    }

    final alreadyTracked = snapshot.docs.any(
      (doc) => doc['message_id'] == loadedMessageId,
    );

    if (alreadyTracked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already tracking this pigeon')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('tracked_pigeons').add({
      'message_id': loadedMessageId,
      'tracked_by_roost_id': roostId,
      'tracked_at': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pigeon tracked')),
    );
  }

  Future<void> _shooPigeon() async {
    if (loadedMessageId == null) return;

    final newHealth = ((loadedHealth ?? 10) - 3);
    final newHops = (loadedHops ?? 0) + 1;

    if (newHealth <= 0) {
      await _messageService.deleteMessage(loadedMessageId!);
    } else {
      await _messageService.updateMessage(
        loadedMessageId!,
        newHealth.clamp(0, 30),
        newHops,
      );
    }

    await _loadRandomEligibleMessage();
  }


  Future<void> _feedPigeon() async {
    if (loadedMessageId == null) return;

    final newHealth = ((loadedHealth ?? 10) + 3).clamp(0, 30);
    final newHops = (loadedHops ?? 0) + 1;

    setState(() {
      loadedHealth = newHealth;
      loadedHops = newHops;
    });

    await Future.delayed(const Duration(seconds: 2));

    await _messageService.updateMessage(
      loadedMessageId!,
      newHealth,
      newHops,
    );

    await _loadRandomEligibleMessage();
  }

  Future<void> _harmPigeon() async {
    if (loadedMessageId == null) return;

    final newHealth = ((loadedHealth ?? 10) - 6);
    final newHops = (loadedHops ?? 0) + 1;

    setState(() {
      loadedHealth = newHealth.clamp(0, 30);
      loadedHops = newHops;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (newHealth <= 0) {
      await _messageService.deleteMessage(loadedMessageId!);
    } else {
      await _messageService.updateMessage(
        loadedMessageId!,
        newHealth,
        newHops,
      );
    }

    await _loadRandomEligibleMessage();
  }

  Future<void> _reportContent() async {
    if (loadedMessageId == null) return;

    final roostId = await _roostService.getRoostId();

    await _messageService.reportMessage(
      messageId: loadedMessageId!,
      reportedByRoostId: roostId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message reported')),
    );
  }

  @override
  Widget build(BuildContext context) {
    int? headIdx = int.tryParse(loadedHead ?? '');
    int? bodyIdx = int.tryParse(loadedBody ?? '');
    int? legsIdx = int.tryParse(loadedLegs ?? '');

    int? healthIdx =
        loadedHealth != null ? (loadedHealth! - 1).clamp(0, hearts.length - 1) : null;

    return AppLayout(
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loadedBody != null)
                  Text('Hops: ${loadedHops ?? 0}'),

                const SizedBox(height: 20),

                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (bodyIdx == null)
                        Image.asset('assets/misc/nest.png', height: 240)
                      else
                        PigeonWidget(
                          head: headIdx ?? 0,
                          body: bodyIdx ?? 0,
                          legs: legsIdx ?? 0,
                          color: loadedColor ?? 0xFF808080,
                        ),

                      Positioned(
                        left: 0,
                        right: 0,
                        top: 90,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            Row(
                              children: [
                                if (loadedBody != null) ...[
                                  GestureDetector(
                                    onTap: (loadedMessageId == null) ? null : _reportContent,
                                    child: Column(
                                      children: [
                                        const Text('Report', style: TextStyle(color: Colors.orange)),
                                        const SizedBox(height: 6),
                                        const Icon(Icons.flag, size: 36, color: Colors.orange),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  GestureDetector(
                                    onTap: (loadedMessageId == null) ? null : _harmPigeon,
                                    child: Column(
                                      children: [
                                        const Text('Harm'),
                                        const SizedBox(height: 6),
                                        Image.asset('assets/Backgrounds/Rocks.png', width: 52),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            Row(
                              children: [
                                if (loadedBody != null) ...[
                                  GestureDetector(
                                    onTap: (loadedMessageId == null) ? null : _feedPigeon,
                                    child: Column(
                                      children: [
                                        const Text('Feed'),
                                        const SizedBox(height: 6),
                                        Image.asset('assets/Backgrounds/Feed.png', width: 52),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  Column(
                                    children: [
                                      const Text('Track'),
                                      Switch(
                                        value: isTracked,
                                        onChanged: (value) async {
                                          if (loadedMessageId == null) return;

                                          if (value) {
                                            await _trackPigeon();
                                          } else {
                                            await _untrackPigeon();
                                          }

                                          setState(() {
                                            isTracked = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                if (healthIdx != null)
                  Image.asset(hearts[healthIdx], width: 200),

                const SizedBox(height: 20),

                if (loadedBody != null)
                  ElevatedButton(
                    onPressed: (loadedMessageId == null) ? null : _shooPigeon,
                    child: const Text('Shoo'),
                  ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Text(
                    loadedMessage ?? 'No pigeons currently in roost.',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
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
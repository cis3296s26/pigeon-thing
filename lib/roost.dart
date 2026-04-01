import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'services/message_service.dart';
import 'services/roost_service.dart';

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
  bool isLoading = false;
  

  final List<String> heads = ['assets/heads/Head10.png','assets/heads/Head20.png','assets/heads/Head30.png','assets/heads/Head40.png'];
  final List<String> torsos = ['assets/Torsos/Body10.png','assets/Torsos/Body20.png'];
  final List<String> legs = ['assets/Legs/Feet10.png', 'assets/Legs/Feet20.png', 'assets/Legs/Feet30.png'];

  final RoostService _roostService = RoostService.getInstance();
  final MessageService _messageService = MessageService();

  Future<void> _loadRandomEligibleMessage() async {
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
    });

    widget.deviceId = await _roostService.getRoostId();

    print('R1: load pressed');
    print('R2: current deviceId = ${widget.deviceId}');

    try {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .get()
          .timeout(const Duration(seconds: 10));

      print('R3: fetched messages');

      if (messagesSnapshot.docs.isEmpty) {
        setState(() {
          loadedMessage = 'No messages found.';
        });
        return;
      }

      final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
        messagesSnapshot.docs,
      );

      docs.shuffle(Random());

      QueryDocumentSnapshot<Map<String, dynamic>>? selectedDoc;
      String? selectedOriginRoostId;

      for (final doc in docs) {
        final data = doc.data();

        final String originRoostId = (data['origin_roost_id'] ?? '')
            .toString()
            .trim();

        print('R4: checking doc ${doc.id}');
        print('R5: original_roost_id = $originRoostId');

        // Skip if missing/empty
        if (originRoostId.isEmpty) {
          print('R6: skipped - original_roost_id missing');
          continue;
        }

        // Skip if same device
        if (originRoostId == widget.deviceId) {
          print('R7: skipped - original_roost_id matches current device');
          continue;
        }

        // Skip if this source -> destination route already exists
        final travelLogSnapshot = await FirebaseFirestore.instance
            .collection('travel_logs')
            .where('message_id', isEqualTo: doc.id)
            .where('destination_roost_id', isEqualTo: widget.deviceId)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));

        final bool messageAlreadySeenByThisDevice =
            travelLogSnapshot.docs.isNotEmpty;

        print(
          'R8: messageAlreadySeenByThisDevice = $messageAlreadySeenByThisDevice',
        );

        if (messageAlreadySeenByThisDevice) {
          print('R9: skipped - this device already saw this message');
          continue;
        }

        selectedDoc = doc;
        selectedOriginRoostId = originRoostId;
        print('R10: selected doc ${doc.id}');
        break;
      }

      if (selectedDoc == null || selectedOriginRoostId == null) {
        setState(() {
          loadedMessage = 'No eligible messages found.';
          loadedHead = null;
          loadedBody = null;
          loadedLegs = null;
          loadedHealth = null;
          loadedHops = null;
          loadedOriginRoostId = null;
          loadedMessageId = null;
        });
        return;
      }

      final selectedData = selectedDoc.data();

      setState(() {
        loadedMessage = (selectedData['message'] ?? 'Message was empty.')
            .toString();

        loadedHead = (selectedData['head'] ?? '').toString();
        loadedBody = (selectedData['body'] ?? '').toString();
        loadedLegs = (selectedData['legs'] ?? '').toString();
        loadedHealth =
            int.tryParse((selectedData['health'] ?? '0').toString()) ?? 10;
        loadedHops =
            int.tryParse((selectedData['hops'] ?? '0').toString()) ?? 0;
        loadedOriginRoostId = (selectedData['origin_roost_id'] ?? '')
            .toString();
        loadedMessageId = selectedDoc?.id;
      });

      await FirebaseFirestore.instance
          .collection('travel_logs')
          .add({
            'message_id': selectedDoc.id,
            'source_roost_id': selectedOriginRoostId,
            'destination_roost_id': widget.deviceId,
            'delivered_at': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 10));

      print('R11: travel log written for ${selectedDoc.id}');
    } catch (e) {
      print('ROOST ERROR: $e');

      setState(() {
        loadedMessage = 'Error loading message: $e';
        loadedHead = null;
        loadedBody = null;
        loadedLegs = null;
        loadedHealth = null;
        loadedHops = null;
        loadedOriginRoostId = null;
        loadedMessageId = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      print('R12: finally hit');
    }
  }

  Future<void> _feedPigeon() async {
    if (loadedMessageId == null || loadedHealth == null || loadedHops == null)
      return;

    setState(() {
      loadedHealth = loadedHealth! + 2;
    });

    try {
      await _messageService.updateMessage(
        loadedMessageId!,
        loadedHealth!,
        loadedHops!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pigeon fed! It gained health and a hop.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error feeding pigeon: $e')));
    }
  }

  Future<void> _harmPigeon() async {
    if (loadedMessageId == null || loadedHealth == null) return;

    setState(() {
      loadedHealth = (loadedHealth! - 3).clamp(0, 100);
    });

    try {
      if (loadedHealth! <= 0) {
        await _messageService.deleteMessage(loadedMessageId!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pigeon died! It's gone now.")),
        );

        await _loadRandomEligibleMessage();
      } else {
        await _messageService.updateMessage(
          loadedMessageId!,
          loadedHealth!,
          loadedHops ?? 0,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pigeon harmed! It lost health.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error harming pigeon: $e')));
    }
  }

  Future<void> _shooPigeon() async {
    await _loadRandomEligibleMessage();
  }

  Future<void> _reportContent() async {
    if (loadedMessageId == null) return;

    try {
      final roostId = await _roostService.getRoostId();

      await _messageService.reportMessage(
        messageId: loadedMessageId!,
        reportedByRoostId: roostId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message reported for review.')),
      );

      setState(() {
        loadedMessage = 'Message reported and moved for review.';
        loadedHead = null;
        loadedBody = null;
        loadedLegs = null;
        loadedHealth = null;
        loadedHops = null;
        loadedOriginRoostId = null;
        loadedMessageId = null;
      });

      await _loadRandomEligibleMessage();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reporting message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int? headIdx = loadedHead != null ? int.tryParse(loadedHead!)?.clamp(0, heads.length - 1) : null;
    int? bodyIdx = loadedBody != null ? int.tryParse(loadedBody!)?.clamp(0, torsos.length - 1) : null;
    int? legsIdx = loadedLegs != null ? int.tryParse(loadedLegs!)?.clamp(0, legs.length - 1) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Roost')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Device ID: ${widget.deviceId}',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // HARM
                  if (loadedMessageId != null)
                    GestureDetector(
                      onTap: _harmPigeon,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Harm', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Image.asset('Backgrounds/Rocks.png', width: 60),
                        ],
                      ),
                    ),

                  const SizedBox(width: 10),

                  Flexible(
                    child: 
                    SizedBox(
                      width: 220,
                      height: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          if (bodyIdx == null)
                            Center(
                              child: Image.asset(
                                'Backgrounds/question_mark.png',
                                height: 100,
                              ),
                            )
                          else ...[
                            Positioned(
                              bottom: 9,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Image.asset(
                                  torsos[bodyIdx],
                                  height: 134,
                                ),
                              ),
                            ),

                            if (headIdx != null)
                              Positioned(
                                top: 6,
                                left: 82.4,
                                right: 0,
                                child: Center(
                                  child: Image.asset(
                                    heads[headIdx],
                                    height: 102,
                                  ),
                                ),
                              ),
                            if (legsIdx != null)
                              Positioned(
                                bottom: 0.5,
                                left: 0,
                                right: .6,
                                child: Center(
                                  child: Image.asset(
                                    legs[legsIdx],
                                    height: 50,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  if (loadedMessageId != null)
                    GestureDetector(
                      onTap: _feedPigeon,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Feed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Image.asset(
                            'Backgrounds/Feed.png',
                            width: 60,
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  loadedMessage ?? 'No message loaded yet.',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _loadRandomEligibleMessage,
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
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roost')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Device ID: ${widget.deviceId}',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                loadedMessage ?? 'No message loaded yet.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Origin Roost ID: ${loadedOriginRoostId ?? '-'}\n'
                'Head: ${loadedHead ?? '-'}\n'
                'Body: ${loadedBody ?? '-'}\n'
                'Legs: ${loadedLegs ?? '-'}\n'
                'Health: ${loadedHealth ?? '-'}\n'
                'Hops: ${loadedHops ?? '-'}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (loadedMessageId != null)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _feedPigeon,
                          child: const Text('🍽️ Feed'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _harmPigeon,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text(
                            '⚔️ Harm',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _shooPigeon,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: const Text(
                            '🚪 Shoo',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
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

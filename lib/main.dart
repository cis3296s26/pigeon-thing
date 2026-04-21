import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'roost.dart';
import 'create_pigeon.dart';
import 'services/roost_service.dart';
import 'widgets/pigeon.dart';
import 'widgets/recolor_image.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

/*void main() {
  runApp(const MyApp());
}*/
// initializing firebase
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await RoostService.getInstance().init();

  print('Firebase initialized - Debug');

  // PLATFORM-SPECIFIC notification permissions
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosMacSettings =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
    iOS: iosMacSettings,
    macOS: iosMacSettings,
  );

  await notificationsPlugin.initialize(
    settings: settings,
  );

  await notificationsPlugin
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.requestNotificationsPermission();

  await notificationsPlugin.periodicallyShow(
    id: 0,
    title: 'Time to grab a pigeon! 🐦',
    body: 'A new pigeon is ready in your roost.',
    repeatInterval: RepeatInterval.hourly,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'pigeon_channel',
        'Pigeon Alerts',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );

  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? device_id;
  String selectedView = 'top';

  @override
  void initState() {
    super.initState();
    loadDeviceId();
  }

  Future<void> loadDeviceId() async {
    final id = await RoostService.getInstance().getRoostId();
    setState(() {
      device_id = id;
    });
  }

  Future<void> _untrackPigeon(String messageId) async {
    final roostId = await RoostService.getInstance().getRoostId();

    final snapshot = await FirebaseFirestore.instance
        .collection('tracked_pigeons')
        .where('tracked_by_roost_id', isEqualTo: roostId)
        .where('message_id', isEqualTo: messageId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Stream<QuerySnapshot> getPigeonStream() {
    if (selectedView == 'tracked') {
      return FirebaseFirestore.instance
          .collection('tracked_pigeons')
          .where('tracked_by_roost_id', isEqualTo: device_id)
          .limit(10)
          .snapshots();
    } else if (selectedView == 'yours') {
      return FirebaseFirestore.instance
          .collection('messages')
          .where('origin_roost_id', isEqualTo: device_id)
          .limit(10)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('messages')
          .orderBy('hops', descending: true)
          .limit(10)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (device_id == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
        appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90,

        shape: const Border(
          bottom: BorderSide(
            color: Colors.black,
            width: 0.5,
          ),
        ),
        
        titleSpacing: 0,
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              alignment: Alignment.center,
              child: Image.asset(
                'assets/logo.png',
                height: 120,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  const Text(
                    'Pigeon Messages',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 50),

                  Container(
                    width: 340,
                    height: 420,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: buildPigeonList(),
                          ),
                        ),
                        const Divider(height: 1),
                        buildBottomTabs(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Roost(deviceId: device_id!),
                            ),
                          );
                        },
                        child: const Text('Go to Roost'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreatePigeon(),
                            ),
                          );
                        },
                        child: const Text('Create Pigeon!'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
  );
}

  Widget buildPigeonList() {
    return StreamBuilder<QuerySnapshot>(
      stream: getPigeonStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No Pigeons"));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            if (selectedView == 'tracked') {
              final trackedDoc = docs[index];
              final String messageId = trackedDoc['message_id'];
              return buildTrackedItem(messageId);
            } else {
              final data = docs[index].data() as Map<String, dynamic>;
              return buildPigeonTile(data);
            }
          },
        );
      },
    );
  }

  Widget buildTrackedItem(String messageId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .doc(messageId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (!snapshot.data!.exists) {
          return const SizedBox(
            height: 80,
            child: Center(child: Text("Missing pigeon")),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        return buildPigeonTile(data, isTracked: true, messageId: messageId,);
      },
    );
  }

  Widget buildPigeonTile(Map<String, dynamic> data, {bool isTracked = false, String? messageId}) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          PigeonWidget(
            head: data['head'] ?? 0,
            body: data['body'] ?? 0,
            legs: data['legs'] ?? 0,
            color: data['color'] ?? 0xFF808080,
            scale: 0.2,
          ),

          const SizedBox(width: 10),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${data['hops'] ?? 0}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text("Hops"),
            ],
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              data['message'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          if (isTracked && messageId != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _untrackPigeon(messageId);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.visibility,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      )
    );
  }

  Widget buildBottomTabs() {
    return Row(
      children: [
        _segment("Top", "top"),
        Container(width: 1, height: 40, color: Colors.grey[400]),
        _segment("My Pigeons", "yours"),
        Container(width: 1, height: 40, color: Colors.grey[400]),
        _segment("Tracked", "tracked"),
      ],
    );
  }

  Widget _segment(String label, String value) {
    final isSelected = selectedView == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedView = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurple : Colors.transparent,
            borderRadius: BorderRadius.only(
              bottomLeft:
                  value == "top" ? const Radius.circular(16) : Radius.zero,
              bottomRight:
                  value == "tracked" ? const Radius.circular(16) : Radius.zero,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
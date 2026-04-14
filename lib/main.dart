import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'roost.dart';
import 'create_pigeon.dart';
import 'services/roost_service.dart';
import 'widgets/pigeon.dart';
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

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String? device_id;

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
    loadDeviceId();
  }

  Future<void> loadDeviceId() async {
    final id = await RoostService.getInstance().getRoostId();
    setState(() {
      device_id = id;
    });
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (device_id == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tracked Pigeons'),

            const SizedBox(height: 20),

            Container(
              width: 320,
              height: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                  .collection('tracked_pigeons')
                  .where('tracked_by_roost_id', isEqualTo: device_id)
                  .limit(3)
                  .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No Tracked Pigeons Yet"));
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    /*itemBuilder: (context, index) {
                      final msg = docs[index];

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
                              head: msg['head'] ?? 0,
                              body: msg['body'] ?? 0,
                              legs: msg['legs'] ?? 0,
                              scale: 0.2,
                            ),

                            const SizedBox(width: 10),

                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${msg['hops'] ?? 0}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Hops",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                msg['message'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    },*/
                    itemBuilder: (context, index) {
                      final trackedDoc = docs[index];
                      final String messageId = trackedDoc['message_id'];

                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('messages')
                            .doc(messageId)
                            .snapshots(),
                        builder: (context, messageSnapshot) {
                          if (messageSnapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }

                          if (!messageSnapshot.hasData || !messageSnapshot.data!.exists) {
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
                                  const Expanded(
                                    child: Text(
                                      'Tracked pigeon no longer exists.',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.gps_fixed, color: Colors.red),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('tracked_pigeons')
                                          .doc('${device_id}_$messageId')
                                          .delete();
                                    },
                                  ),
                                ],
                              ),
                            );
                          }

                          final data = messageSnapshot.data!.data() as Map<String, dynamic>;

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
                                  scale: 0.2,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${data['hops'] ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      "Hops",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    data['message'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.gps_fixed, color: Colors.green),
                                  tooltip: 'Untrack',
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('tracked_pigeons')
                                        .doc('${device_id}_$messageId')
                                        .delete();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
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
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

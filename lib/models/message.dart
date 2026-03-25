class Message {
  final int body;
  final int head;
  final int health;
  final int hops;
  final int legs;
  final String message;
  final String originRoostId;
  final DateTime? createdAt;
  final String? id;

  Message({
    required this.body,
    required this.head,
    required this.health,
    required this.hops,
    required this.legs,
    required this.message,
    required this.originRoostId,
    this.createdAt,
    this.id,
  });

  /// Creates a new message with initial values
  factory Message.create({
    required int body,
    required int head,
    required int legs,
    required String message,
    String originRoostId = '',
  }) {
    return Message(
      body: body,
      head: head,
      health: 10, // Starting health
      hops: 0,
      legs: legs,
      message: message,
      originRoostId: originRoostId,
      createdAt: DateTime.now(),
    );
  }

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'body': body,
      'head': head,
      'health': health,
      'hops': hops,
      'legs': legs,
      'message': message,
      'origin_roost_id': originRoostId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Create from Firestore JSON
  factory Message.fromJson(Map<String, dynamic> json, String id) {
    return Message(
      body: json['body'] ?? 0,
      head: json['head'] ?? 0,
      health: json['health'] ?? 10,
      hops: json['hops'] ?? 0,
      legs: json['legs'] ?? 0,
      message: json['message'] ?? '',
      originRoostId: json['origin_roost_id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      id: id,
    );
  }
}

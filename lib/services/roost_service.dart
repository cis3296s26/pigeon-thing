import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class RoostService {
  static const String _roostIdKey = 'roost_id';
  static const String _lastPigeonRequestKey = 'last_pigeon_request_time';
  late SharedPreferences _prefs;
  String? _cachedRoostId;
  static RoostService? _instance;

  RoostService._();

  static RoostService getInstance() {
    _instance ??= RoostService._();
    return _instance!;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // get or create the user's roost ID
  Future<String> getRoostId() async {
    // return cached ID if it's available
    if (_cachedRoostId != null) {
      return _cachedRoostId!;
    }

    // try to get existing ID from storage
    String? storedId = _prefs.getString(_roostIdKey);

    if (storedId != null) {
      _cachedRoostId = storedId;
      return storedId;
    }

    // generate a new ID if one doesn't exist
    const uuid = Uuid();
    final newId = uuid.v4();
    await _prefs.setString(_roostIdKey, newId);
    _cachedRoostId = newId;
    return newId;
  }

  // check if user can request a new pigeon (rate limited to 1 per hour)
  Future<bool> canRequestNewPigeon() async {
    final lastRequestTime = _prefs.getInt(_lastPigeonRequestKey);

    if (lastRequestTime == null) {
      return true; // First request, always allowed
    }

    final lastRequest = DateTime.fromMillisecondsSinceEpoch(lastRequestTime);
    final now = DateTime.now();
    final difference = now.difference(lastRequest);

    return difference.inHours >= 1;
  }

  // get minutes remaining until next pigeon can be requested
  Future<int> getMinutesUntilNextRequest() async {
    final lastRequestTime = _prefs.getInt(_lastPigeonRequestKey);

    if (lastRequestTime == null) {
      return 0; // Can request now
    }

    final lastRequest = DateTime.fromMillisecondsSinceEpoch(lastRequestTime);
    final now = DateTime.now();
    final difference = now.difference(lastRequest);
    final minutesElapsed = difference.inMinutes;
    final minuteRemaining = 60 - minutesElapsed;

    return minuteRemaining > 0 ? minuteRemaining : 0;
  }

  // record that a pigeon was requested
  Future<void> recordPigeonRequest() async {
    await _prefs.setInt(
      _lastPigeonRequestKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class RoostService {
  static const String _roostIdKey = 'roost_id';
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
}

import 'package:result_dart/result_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

/// A wrapper around [SharedPreferences] for simple key-value persistence.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late final SharedPreferences _prefs;

  AsyncAppResult<Unit> init() {
    return runTask(() async {
      _prefs = await SharedPreferences.getInstance();
      AppLogger.info('StorageService (SharedPreferences) initialized');
      return unit;
    });
  }

  // --- SETTERS ---

  AsyncAppResult<bool> setString(String key, String value) =>
      runTask(() => _prefs.setString(key, value));

  AsyncAppResult<bool> setBool(String key, bool value) =>
      runTask(() => _prefs.setBool(key, value));

  AsyncAppResult<bool> setInt(String key, int value) =>
      runTask(() => _prefs.setInt(key, value));

  AsyncAppResult<bool> setDouble(String key, double value) =>
      runTask(() => _prefs.setDouble(key, value));

  AsyncAppResult<bool> setStringList(String key, List<String> value) =>
      runTask(() => _prefs.setStringList(key, value));

  // --- GETTERS ---

  String? getString(String key) => _prefs.getString(key);
  bool? getBool(String key) => _prefs.getBool(key);
  int? getInt(String key) => _prefs.getInt(key);
  double? getDouble(String key) => _prefs.getDouble(key);
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  // --- COMMON ---

  bool containsKey(String key) => _prefs.containsKey(key);

  AsyncAppResult<bool> remove(String key) => runTask(() => _prefs.remove(key));

  AsyncAppResult<bool> clear() => runTask(() => _prefs.clear());
}

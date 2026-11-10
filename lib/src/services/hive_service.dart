import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:result_dart/result_dart.dart';

import '../utils/utils.dart';

/// A robust [Hive] storage service for local NoSQL persistence.
class HiveService {
  HiveService._();
  static final HiveService instance = HiveService._();

  /// Initialize Hive and open a default box.
  AsyncAppResult<Unit> init() {
    return runTask(() async {
      await Hive.initFlutter();
      await Hive.openBox<dynamic>('app_box');
      AppLogger.info('Hive initialized');
      return unit;
    });
  }

  /// Get data from the default box. Returns [defaultValue] on any failure.
  T? get<T>(String key, {T? defaultValue}) {
    try {
      final box = Hive.box<dynamic>('app_box');
      return box.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      AppLogger.error('Hive get error', e);
      return defaultValue;
    }
  }

  /// Put data into the default box.
  AsyncAppResult<Unit> put(String key, dynamic value) {
    return runTask(() async {
      final box = Hive.box<dynamic>('app_box');
      await box.put(key, value);
      return unit;
    });
  }

  /// Delete data from the default box.
  AsyncAppResult<Unit> delete(String key) {
    return runTask(() async {
      final box = Hive.box<dynamic>('app_box');
      await box.delete(key);
      return unit;
    });
  }

  /// Clear all data from the default box.
  AsyncAppResult<Unit> clear() {
    return runTask(() async {
      final box = Hive.box<dynamic>('app_box');
      await box.clear();
      return unit;
    });
  }

  /// Open a custom box for specialized storage.
  AsyncAppResult<Box<T>> openCustomBox<T>(String name) {
    return runTask(() async => Hive.openBox<T>(name));
  }
}

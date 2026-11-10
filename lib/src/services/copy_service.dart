import 'package:flutter/services.dart';
import 'package:result_dart/result_dart.dart';

import '../utils/utils.dart';

/// A service to handle clipboard operations.
class CopyService {
  CopyService._();
  static final CopyService instance = CopyService._();

  /// Copy text to the system clipboard.
  AsyncAppResult<Unit> copy(String text) {
    return runTask(() async {
      await Clipboard.setData(ClipboardData(text: text));
      AppLogger.info('Text copied to clipboard');
      return unit;
    });
  }
}

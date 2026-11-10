import 'package:flutter/foundation.dart';
import 'package:talker/talker.dart';

/// Shared [Talker] instance used for HTTP logging (via `talker_dio_logger`).
///
/// ANSI colors are disabled on web so the output stays readable in the browser
/// DevTools console; native targets keep colored output.
final Talker appTalker = Talker(
  logger: TalkerLogger(
    settings: TalkerLoggerSettings(
      enableColors: !kIsWeb,
    ),
  ),
);

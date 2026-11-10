import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// App-wide logger built on the `logger` package.
///
/// Output goes through `print`/`developer.log`, so logs are visible in the
/// terminal AND in the browser DevTools console for Flutter web. ANSI colors
/// are disabled on web (they would render as escape garbage in the console).
final Logger _logger = Logger(
  filter: _AppLogFilter(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 100,
    colors: !kIsWeb,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

/// Logs everything in debug; only warnings and above in profile/release.
class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    const threshold = kReleaseMode ? Level.warning : Level.trace;
    return event.level.index >= threshold.index;
  }
}

class AppLogger {
  AppLogger._();

  /// Underlying [Logger] for advanced use.
  static Logger get instance => _logger;

  static void debug(String message) => _logger.d(message);

  static void info(String message) => _logger.i(message);

  static void success(String message) => _logger.i('✅ $message');

  static void warning(String message) => _logger.w(message);

  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}

// Global helper functions.
void logInfo(String msg) => AppLogger.info(msg);
void logSuccess(String msg) => AppLogger.success(msg);
void logWarning(String msg) => AppLogger.warning(msg);
void logError(String msg) => AppLogger.error(msg);

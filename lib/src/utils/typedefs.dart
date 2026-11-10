import 'package:result_dart/result_dart.dart';
import 'failure.dart';

/// Standard Result alias used across the app. Success payload must extend
/// [Object]; failures are always an [AppFailure] subtype.
typedef AppResult<S extends Object> = ResultDart<S, AppFailure>;

/// Future-returning Result (the common case for async domain/data calls).
typedef AsyncAppResult<S extends Object> = Future<AppResult<S>>;

/// Stream of Results (reserved for reactive sources).
typedef StreamAppResult<S extends Object> = Stream<AppResult<S>>;

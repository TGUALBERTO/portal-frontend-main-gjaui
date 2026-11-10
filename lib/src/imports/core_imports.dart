// Flutter SDK
export 'package:flutter/cupertino.dart' hide RefreshCallback;
export 'package:flutter/foundation.dart';
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';
export 'package:flutter_native_splash/flutter_native_splash.dart';

// Project Core — everything exported through shared.dart (theme, extensions,
// utils, widgets, enums) plus routing and services.
export '../config/app_config.dart';
export '../features/auth/presentation/screens/login_screen.dart';
export '../features/home/presentation/screens/home_page.dart';
export '../routing/app_router.dart';
export '../routing/app_routes.dart';
export '../routing/global_navigator.dart';
export '../services/services.dart';
export '../shared/shared.dart';

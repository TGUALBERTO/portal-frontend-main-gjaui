import 'package:flutter/material.dart';
import 'package:gjamobile/src/di/app_injector.dart';

// import '../helpers/loader.dart';
// import '../helpers/messages.dart';

abstract class BaseState<T extends StatefulWidget, C extends Object> extends State<T> {
  // with Loader, Messages {
  late final C controller;

  @override
  void initState() {
    super.initState();
    controller = AppInjector.get<C>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onReady();
    });
  }

  void onReady() {}
}

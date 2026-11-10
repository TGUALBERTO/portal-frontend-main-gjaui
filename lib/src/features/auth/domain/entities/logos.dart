import 'package:flutter/material.dart';

enum Logos {
  nel(path: 'assets/logos/nel.png', bg: Colors.grey),
  cocacola(path: 'assets/logos/coca-cola.png', bg: Colors.red),
  vitamedic(path: 'assets/logos/vitamedic.png', bg: Colors.grey);

  final String path;
  final Color bg;
  const Logos({required this.path, required this.bg});
}
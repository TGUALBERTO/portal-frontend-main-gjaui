import 'package:flutter/material.dart' show Material, MaterialApp;
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';

void main() {
  testWidgets('a galeria inicializa sem ancestrais Material', (tester) async {
    await tester.pumpWidget(const GjaGalleryApp());

    expect(find.text(GjaGalleryApp.title), findsOneWidget);
    expect(find.byType(MaterialApp), findsNothing);
    expect(find.byType(Material), findsNothing);
  });
}

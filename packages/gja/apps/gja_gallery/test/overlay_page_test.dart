import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/overlay_page.dart';

void main() {
  testWidgets('Testes e documentação das sobreposições — Página na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(OverlayPage.title));
    await tester.pumpAndSettle();

    // Modal dispensável, fechado com Esc.
    await tester.tap(find.text('Abrir modal'));
    await tester.pumpAndSettle();
    expect(find.text('Enviar pedido?'), findsOneWidget);
    // Como no sap.m.Dialog, um toque na camada de bloqueio não fecha.
    await tester.tapAt(const Offset(5, 990));
    await tester.pumpAndSettle();
    expect(find.text('Enviar pedido?'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Enviar pedido?'), findsNothing);
    expect(find.text('Resultado: dispensado'), findsOneWidget);

    // Modal obrigatório: Esc não fecha; "Concluir" fecha.
    await tester.tap(find.text('Abrir modal obrigatório'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Leia antes de continuar'), findsOneWidget);
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
    expect(find.text('Leia antes de continuar'), findsNothing);

    // Sobreposição ancorada, fechada com um toque fora.
    await tester.tap(find.text('Abrir popover'));
    await tester.pumpAndSettle();
    expect(find.byKey(OverlayPage.popoverKey), findsOneWidget);
    await tester.tapAt(const Offset(5, 990));
    await tester.pumpAndSettle();
    expect(find.byKey(OverlayPage.popoverKey), findsNothing);
    expect(find.text('Abrir popover'), findsOneWidget);
  });
}

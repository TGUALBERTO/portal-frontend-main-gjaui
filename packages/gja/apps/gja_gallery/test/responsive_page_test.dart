import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/responsive_page.dart';

String _text(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

void main() {
  testWidgets('Testes e documentação da responsividade — Página na galeria', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GjaGalleryApp());

    await tester.tap(find.text(ResponsivePage.title));
    await tester.pumpAndSettle();

    expect(_text(tester, ResponsivePage.screenKey), 'Classe da tela: large');
    expect(find.text('Colunas pela tela: 3'), findsOneWidget);
    expect(
      _text(tester, ResponsivePage.panelKey),
      startsWith('Classe do painel: small'),
    );
    expect(find.textContaining('Densidade recomendada: '), findsOneWidget);

    tester.view.physicalSize = const Size(500, 1400);
    await tester.pumpAndSettle();

    expect(_text(tester, ResponsivePage.screenKey), 'Classe da tela: small');
    expect(find.text('Colunas pela tela: 1'), findsOneWidget);
  });
}

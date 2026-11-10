import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_button_page.dart';
import 'package:gja_ui/gja_ui.dart';

import 'support/navigation.dart';

void main() {
  testWidgets(
    '[Documentação] Exemplos mínimos — Página GjaButton na galeria',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GjaGalleryApp());

      await openGalleryPage(tester, GjaButtonPage.title);

      final types = tester
          .widgetList<GjaButton>(find.byType(GjaButton))
          .map((b) => b.type)
          .toSet();
      expect(types, GjaButtonType.values.toSet());
      GjaButton send() =>
          tester.widget<GjaButton>(find.byKey(GjaButtonPage.sendKey));
      expect(send().busy, isFalse);

      await tester.tap(find.byKey(GjaButtonPage.sendKey));
      await tester.pump();
      expect(send().busy, isTrue);

      // Sai do estado ocupado para parar a animação do indicador.
      await tester.tap(find.text('Concluir envio'));
      await tester.pumpAndSettle();
      expect(send().busy, isFalse);

      // O primeiro botão da barra de ícones recebe o foco por Tab e mostra a
      // dica.
      final (_, tooltip) = GjaButtonPage.actions.first;
      expect(find.text(tooltip), findsNothing);
      String? focusedTooltip() => FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<GjaButton>()
          ?.tooltip;
      for (var i = 0; i < 20 && focusedTooltip() != tooltip; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(focusedTooltip(), tooltip);
      expect(find.text(tooltip), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

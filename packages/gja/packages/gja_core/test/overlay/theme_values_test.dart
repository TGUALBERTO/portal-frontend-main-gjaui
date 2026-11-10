import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// App com [theme] publicado acima das rotas.
Future<void> _pumpApp(WidgetTester tester, GjaThemeData theme, Widget home) {
  return tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      builder: (context, child) => GjaThemeScope(data: theme, child: child!),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
      home: home,
    ),
  );
}

void main() {
  group('Valores do tema ativo nas sobreposições', () {
    testWidgets(
      'Valores do tema ativo nas sobreposições — Camada no tema escuro',
      (tester) async {
        late BuildContext screen;
        final dark = GjaThemeData.dark();
        await _pumpApp(
          tester,
          dark,
          Builder(
            builder: (context) {
              screen = context;
              return const SizedBox.expand();
            },
          ),
        );
        unawaited(
          GjaModal.show<void>(screen, builder: (_) => const Text('modal')),
        );
        await tester.pumpAndSettle();
        final barrier = tester.widget<ModalBarrier>(
          find.byType(ModalBarrier).last,
        );
        expect(barrier.color, dark.colors.blockLayer);
        expect(barrier.color, isNot(GjaThemeData.light().colors.blockLayer));
      },
    );

    testWidgets(
      'Valores do tema ativo nas sobreposições — Espaçamentos da densidade compacta',
      (tester) async {
        final compact = GjaThemeData.light(density: GjaDensity.compact);
        final controller = GjaAnchoredOverlayController();
        addTearDown(controller.dispose);
        await _pumpApp(
          tester,
          compact,
          Stack(
            children: [
              Positioned(
                left: 50,
                top: 20,
                child: GjaAnchoredOverlay(
                  controller: controller,
                  focusOnShow: false,
                  overlayBuilder: (_) => const SizedBox(
                    key: Key('content'),
                    width: 120,
                    height: 80,
                  ),
                  child: const SizedBox(
                    key: Key('anchor'),
                    width: 100,
                    height: 40,
                  ),
                ),
              ),
            ],
          ),
        );
        controller.show();
        await tester.pumpAndSettle();
        final anchor = tester.getRect(find.byKey(const Key('anchor')));
        final content = tester.getRect(find.byKey(const Key('content')));
        expect(content.top, anchor.bottom + compact.spacing.xs);
      },
    );
  });
}

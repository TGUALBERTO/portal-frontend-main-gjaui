import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';

const _anchorKey = Key('anchor');
const _contentKey = Key('content');

/// App de 800×600 com o [home] abaixo do `Navigator`.
Future<void> _pumpApp(WidgetTester tester, Widget home) {
  return tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
      home: home,
    ),
  );
}

/// Âncora de 100×40 com a sobreposição; o conteúdo tem [contentSize].
Widget _anchored(
  GjaAnchoredOverlayController controller, {
  GjaPlacement placement = GjaPlacement.bottom,
  GjaOverlayAlignment alignment = GjaOverlayAlignment.start,
  Size contentSize = const Size(120, 80),
  double? margin,
  bool focusOnShow = true,
  FocusNode? anchorFocus,
  VoidCallback? onDismiss,
  VoidCallback? onAnchorTap,
  WidgetBuilder? contentBuilder,
}) {
  return GjaAnchoredOverlay(
    controller: controller,
    placement: placement,
    alignment: alignment,
    gap: 4,
    margin: margin,
    focusOnShow: focusOnShow,
    onDismiss: onDismiss,
    overlayBuilder:
        contentBuilder ??
        (_) => SizedBox.fromSize(key: _contentKey, size: contentSize),
    child: GestureDetector(
      onTap: onAnchorTap,
      child: Focus(
        focusNode: anchorFocus,
        child: const SizedBox(key: _anchorKey, width: 100, height: 40),
      ),
    ),
  );
}

Widget _at(Offset position, Widget child, {TextDirection? textDirection}) {
  Widget stack = Stack(
    children: [Positioned(left: position.dx, top: position.dy, child: child)],
  );
  if (textDirection != null) {
    stack = Directionality(textDirection: textDirection, child: stack);
  }
  return stack;
}

void main() {
  late GjaAnchoredOverlayController controller;

  setUp(() => controller = GjaAnchoredOverlayController());
  tearDown(() => controller.dispose());

  Future<void> show(WidgetTester tester) async {
    controller.show();
    await tester.pumpAndSettle();
  }

  group('Posição efetiva da sobreposição ancorada', () {
    Widget probe(List<GjaPlacement?> seen) => Builder(
      builder: (context) {
        seen.add(GjaAnchoredOverlay.placementOf(context));
        return const SizedBox(key: _contentKey, width: 120, height: 80);
      },
    );

    testWidgets(
      'Posição efetiva da sobreposição ancorada — Posição informada após a inversão',
      (tester) async {
        final seen = <GjaPlacement?>[];
        await _pumpApp(
          tester,
          _at(
            const Offset(50, 540),
            _anchored(controller, contentBuilder: (_) => probe(seen)),
          ),
        );
        await show(tester);
        expect(seen.last, GjaPlacement.top);
      },
    );

    testWidgets(
      'Posição efetiva da sobreposição ancorada — Posição sem inversão',
      (tester) async {
        final seen = <GjaPlacement?>[];
        await _pumpApp(
          tester,
          _at(
            const Offset(50, 20),
            _anchored(controller, contentBuilder: (_) => probe(seen)),
          ),
        );
        await show(tester);
        expect(seen.last, GjaPlacement.bottom);
      },
    );
  });

  group('Sobreposição ancorada', () {
    testWidgets('Sobreposição ancorada — Posição preferida', (tester) async {
      await _pumpApp(tester, _at(const Offset(50, 20), _anchored(controller)));
      await show(tester);
      final anchor = tester.getRect(find.byKey(_anchorKey));
      final content = tester.getRect(find.byKey(_contentKey));
      expect(content.top, anchor.bottom + 4);
      expect(content.left, anchor.left);
    });

    testWidgets('Sobreposição ancorada — Inversão por falta de espaço', (
      tester,
    ) async {
      await _pumpApp(tester, _at(const Offset(50, 540), _anchored(controller)));
      await show(tester);
      final anchor = tester.getRect(find.byKey(_anchorKey));
      final content = tester.getRect(find.byKey(_contentKey));
      expect(content.bottom, anchor.top - 4);
    });

    testWidgets('Sobreposição ancorada — Dentro da tela', (tester) async {
      await _pumpApp(
        tester,
        _at(
          const Offset(690, 20),
          _anchored(controller, margin: 8, contentSize: const Size(200, 80)),
        ),
      );
      await show(tester);
      final content = tester.getRect(find.byKey(_contentKey));
      expect(content.right, 800 - 8);
    });

    testWidgets('Sobreposição ancorada — Acompanha a rolagem', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await _pumpApp(
        tester,
        ListView(
          controller: scroll,
          children: [
            const SizedBox(height: 200),
            Align(alignment: Alignment.topLeft, child: _anchored(controller)),
            const SizedBox(height: 1000),
          ],
        ),
      );
      await show(tester);
      final before = tester.getRect(find.byKey(_contentKey));
      scroll.jumpTo(100);
      await tester.pumpAndSettle();
      final after = tester.getRect(find.byKey(_contentKey));
      expect(after.top, before.top - 100);
      expect(after.top, tester.getRect(find.byKey(_anchorKey)).bottom + 4);
    });

    testWidgets(
      'Sobreposição ancorada — Acompanha a âncora que muda de tamanho',
      (tester) async {
        final height = ValueNotifier<double>(40);
        addTearDown(height.dispose);
        await _pumpApp(
          tester,
          _at(
            const Offset(50, 20),
            GjaAnchoredOverlay(
              controller: controller,
              gap: 4,
              overlayBuilder: (_) =>
                  const SizedBox(key: _contentKey, width: 120, height: 80),
              child: ValueListenableBuilder<double>(
                valueListenable: height,
                builder: (_, h, _) =>
                    SizedBox(key: _anchorKey, width: 100, height: h),
              ),
            ),
          ),
        );
        await show(tester);
        expect(tester.getRect(find.byKey(_contentKey)).top, 20 + 40 + 4);
        height.value = 60;
        await tester.pump();
        await tester.pump();
        final anchor = tester.getRect(find.byKey(_anchorKey));
        expect(anchor.height, 60);
        expect(tester.getRect(find.byKey(_contentKey)).top, anchor.bottom + 4);
      },
    );

    testWidgets('início e fim seguem a direção do texto', (tester) async {
      await _pumpApp(
        tester,
        _at(
          const Offset(300, 200),
          _anchored(controller, placement: GjaPlacement.end),
          textDirection: TextDirection.rtl,
        ),
      );
      await show(tester);
      final anchor = tester.getRect(find.byKey(_anchorKey));
      final content = tester.getRect(find.byKey(_contentKey));
      // Em RTL, o fim fica à esquerda, e o início do alinhamento é o topo.
      expect(content.right, anchor.left - 4);
      expect(content.top, anchor.top);
    });
  });

  group('Fechamento automático da sobreposição ancorada', () {
    testWidgets(
      'Fechamento automático da sobreposição ancorada — Toque fora e Esc',
      (tester) async {
        var dismissed = 0;
        await _pumpApp(
          tester,
          _at(
            const Offset(50, 20),
            _anchored(controller, onDismiss: () => dismissed++),
          ),
        );
        await show(tester);
        await tester.tapAt(const Offset(700, 500));
        await tester.pumpAndSettle();
        expect(find.byKey(_contentKey), findsNothing);

        await show(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byKey(_contentKey), findsNothing);
        expect(dismissed, 2);
        expect(controller.isShowing, isFalse);
      },
    );

    testWidgets(
      'Fechamento automático da sobreposição ancorada — Toque na âncora',
      (tester) async {
        var hides = 0;
        controller.addListener(() {
          if (!controller.isShowing) hides++;
        });
        await _pumpApp(
          tester,
          _at(
            const Offset(50, 20),
            _anchored(
              controller,
              onAnchorTap: () =>
                  controller.isShowing ? controller.hide() : controller.show(),
            ),
          ),
        );
        await show(tester);
        await tester.tap(find.byKey(_anchorKey));
        await tester.pumpAndSettle();
        expect(controller.isShowing, isFalse);
        expect(find.byKey(_contentKey), findsNothing);
        expect(hides, 1);
      },
    );

    testWidgets(
      'Fechamento automático da sobreposição ancorada — Foco da âncora restaurado',
      (tester) async {
        final anchorFocus = FocusNode();
        final itemFocus = FocusNode();
        addTearDown(anchorFocus.dispose);
        addTearDown(itemFocus.dispose);
        await _pumpApp(
          tester,
          _at(
            const Offset(50, 20),
            _anchored(
              controller,
              anchorFocus: anchorFocus,
              contentBuilder: (_) => Focus(
                focusNode: itemFocus,
                child: const SizedBox(key: _contentKey, width: 120, height: 40),
              ),
            ),
          ),
        );
        anchorFocus.requestFocus();
        await tester.pump();
        await show(tester);
        expect(itemFocus.hasPrimaryFocus, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(anchorFocus.hasPrimaryFocus, isTrue);
      },
    );
  });

  testWidgets('Empilhamento — Popover dentro de modal', (tester) async {
    late BuildContext screen;
    await _pumpApp(
      tester,
      Builder(
        builder: (context) {
          screen = context;
          return const SizedBox.expand();
        },
      ),
    );
    final itemFocus = FocusNode();
    addTearDown(itemFocus.dispose);
    var contentTaps = 0;
    unawaited(
      GjaModal.show<void>(
        screen,
        builder: (_) => SizedBox(
          width: 300,
          height: 200,
          child: Align(
            alignment: Alignment.topLeft,
            child: _anchored(
              controller,
              contentBuilder: (_) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => contentTaps++,
                child: Focus(
                  focusNode: itemFocus,
                  child: const SizedBox(
                    key: _contentKey,
                    width: 120,
                    height: 40,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await show(tester);

    // O conteúdo ancorado fica acima do modal: um toque nele o atinge.
    await tester.tapAt(tester.getCenter(find.byKey(_contentKey)));
    await tester.pump();
    expect(contentTaps, 1);
    expect(controller.isShowing, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(_contentKey), findsNothing);
    expect(find.byKey(_anchorKey), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(_anchorKey), findsNothing);
  });

  testWidgets('fechar o modal remove a sobreposição ancorada aberta', (
    tester,
  ) async {
    late BuildContext screen;
    late BuildContext modal;
    await _pumpApp(
      tester,
      Builder(
        builder: (context) {
          screen = context;
          return const SizedBox.expand();
        },
      ),
    );
    unawaited(
      GjaModal.show<void>(
        screen,
        builder: (context) {
          modal = context;
          return _anchored(controller, focusOnShow: false);
        },
      ),
    );
    await tester.pumpAndSettle();
    await show(tester);
    Navigator.of(modal).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_contentKey), findsNothing);
  });
}

import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/golden.dart';
import '../../support/traceability.dart';

/// Monta [child] centralizado, sob [theme] e [direction], sem `GjaApp`.
Widget _host(
  Widget child, {
  GjaThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) => GjaTheme(
  data: theme ?? GjaThemeData.light(),
  duration: Duration.zero,
  child: Directionality(
    textDirection: direction,
    child: Center(child: child),
  ),
);

Text _text(WidgetTester tester, [int index = 0]) => tester.widget<Text>(
  find
      .descendant(
        of: find.byType(GjaLink).at(index),
        matching: find.byType(Text),
      )
      .first,
);

RenderParagraph _paragraph(WidgetTester tester) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byType(GjaLink),
        matching: find.byType(RichText),
      ),
    );

const _long = 'Ver todos os pedidos aguardando aprovação do gestor';

final _light = GjaThemeData.light();

void main() {
  testWidgets('[API] Propriedades — Link mínimo', (tester) async {
    await tester.pumpWidget(
      _host(GjaLink(text: 'Ver pedido', onPress: () {})),
    );
    final text = _text(tester);
    expect(text.data, 'Ver pedido');
    expect(text.maxLines, 1);
    expect(text.style!.color, _light.colors.link);
    expect(text.style!.fontSize, _light.typography.base.fontSize);
    expect(text.style!.fontWeight, _light.typography.base.fontWeight);
    expect(text.style!.decoration, TextDecoration.none);
  });

  test('[API] Texto válido — Texto vazio', () {
    for (final text in ['']) {
      expect(() => GjaLink(text: text, onPress: () {}), throwsAssertionError);
    }
  });

  group('[API] Callbacks e controlador', () {
    testWidgets('[API] Callbacks e controlador — Acionar o link', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        GjaApp(
          home: Center(
            child: GjaLink(text: 'Ver pedido', onPress: () => calls++),
          ),
        ),
      );
      await tester.tap(find.byType(GjaLink));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(calls, 2);
    });

    testWidgets('[API] Callbacks e controlador — Link desabilitado', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const GjaLink(text: 'Ver pedido', enabled: false)),
      );
      await tester.tap(find.byType(GjaLink), warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(GjaLink),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        _light.interaction.disabledOpacity,
      );
    });
  });

  group('[Comportamento] Quebra do texto', () {
    testWidgets('[Comportamento] Quebra do texto — Texto longo sem quebra', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 120,
            child: GjaLink(text: _long, onPress: () {}),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(_paragraph(tester).didExceedMaxLines, isTrue);
      expect(_text(tester).overflow, TextOverflow.ellipsis);
    });

    testWidgets('[Comportamento] Quebra do texto — Texto longo com quebra', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 120,
            child: GjaLink(text: _long, wrapping: true, onPress: () {}),
          ),
        ),
      );
      final paragraph = _paragraph(tester);
      expect(paragraph.didExceedMaxLines, isFalse);
      final lineHeight = paragraph.preferredLineHeight;
      expect(paragraph.size.height, greaterThan(lineHeight * 1.5));
      expect(_text(tester).overflow, isNull);
    });
  });

  testWidgets('[Aparência] Variantes — Link sutil e enfatizado', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GjaLink(text: 'Sutil', subtle: true, onPress: () {}),
            GjaLink(text: 'Enfatizado', emphasized: true, onPress: () {}),
          ],
        ),
      ),
    );
    expect(_text(tester, 0).style!.color, _light.colors.text);
    final emphasized = _text(tester, 1).style!;
    expect(emphasized.color, _light.colors.link);
    expect(emphasized.fontWeight, _light.typography.baseBold.fontWeight);
  });

  testWidgets('[Aparência] Tokens de componente — Cor do link nos temas', (
    tester,
  ) async {
    for (final theme in [GjaThemeData.light(), GjaThemeData.dark()]) {
      await tester.pumpWidget(
        _host(
          theme: theme,
          GjaLink(
            key: ValueKey(theme.brightness),
            text: 'Ver pedido',
            onPress: () {},
          ),
        ),
      );
      expect(_text(tester).style!.color, theme.colors.link);
    }
  });

  group('[Estados] Interação', () {
    testWidgets('[Estados] Interação — Sublinhado no hover e no pressionado', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(GjaLink(text: 'Ver pedido', onPress: () {})),
      );
      TextDecoration? decoration() => _text(tester).style!.decoration;
      final center = tester.getCenter(find.byType(GjaLink));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(center);
      await tester.pump();
      expect(decoration(), TextDecoration.underline);
      await mouse.down(center);
      await tester.pump();
      expect(decoration(), TextDecoration.underline);
      await mouse.up();
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      expect(decoration(), TextDecoration.none);
    });

    testWidgets('[Estados] Interação — Foco pelo teclado no link', (
      tester,
    ) async {
      await tester.pumpWidget(
        GjaApp(
          home: Center(
            child: GjaLink(text: 'Ver pedido', onPress: () {}),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester
            .widget<GjaFocusRing>(
              find.descendant(
                of: find.byType(GjaLink),
                matching: find.byType(GjaFocusRing),
              ),
            )
            .visible,
        isTrue,
      );
    });
  });

  testWidgets('[Acessibilidade] Semântica — Semântica do link', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GjaLink(text: 'Ver pedido', onPress: () {}),
            const GjaLink(text: 'Ver nota', enabled: false),
          ],
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(GjaLink).at(0)),
      containsSemantics(
        label: 'Ver pedido',
        isLink: true,
        isButton: false,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.byType(GjaLink).at(1)),
      containsSemantics(
        label: 'Ver nota',
        isLink: true,
        isButton: false,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('[Responsividade] Largura e direção — Link em RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        direction: TextDirection.rtl,
        SizedBox(
          width: 120,
          child: GjaLink(text: _long, onPress: () {}),
        ),
      ),
    );
    final paragraph = _paragraph(tester);
    expect(paragraph.textDirection, TextDirection.rtl);
    expect(paragraph.didExceedMaxLines, isTrue);
  });

  testWidgets('[Integração] Dependências — Link sem Material', (tester) async {
    await tester.pumpWidget(
      GjaApp(
        home: Column(
          children: [
            GjaLink(text: 'Normal', onPress: () {}),
            GjaLink(text: 'Sutil', subtle: true, onPress: () {}),
            GjaLink(text: 'Enfatizado', emphasized: true, onPress: () {}),
            const GjaLink(text: 'Desabilitado', enabled: false),
          ],
        ),
      ),
    );
    for (final element in find.byType(GjaLink).evaluate().toList()) {
      await tester.tap(find.byWidget(element.widget), warnIfMissed: false);
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade do link', () {
      final names = scenarioNames('gja/widgets/gja-link', 'add-gja-link');
      expect(names, hasLength(19));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens do link', (tester) async {
      for (final (name, theme) in goldenThemes) {
        await expectGolden(
          tester,
          name: 'gja_link_$name',
          theme: theme,
          size: const Size(480, 320),
          child: GjaVBox(
            gap: GjaSpace.none,
            items: [
              GjaLink(text: 'Ver pedido 4711', onPress: () {}),
              GjaLink(text: 'Link sutil', subtle: true, onPress: () {}),
              GjaLink(
                text: 'Link enfatizado',
                emphasized: true,
                onPress: () {},
              ),
              const GjaLink(text: 'Link desabilitado', enabled: false),
              SizedBox(
                width: 200,
                child: GjaLink(text: _long, wrapping: true, onPress: () {}),
              ),
            ],
          ),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Link sem valor literal', () {
    final source = File(
      'lib/src/acoes_navegacao/link/gja_link.dart',
    ).readAsStringSync();
    final fields = RegExp(
      r'^  final (\S+) (\w+);$',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!).toList();
    expect(fields, isNotEmpty);
    for (final type in fields) {
      expect(
        type.replaceAll('?', ''),
        isNot(isIn(['double', 'Color', 'TextStyle', 'Uri', 'Widget'])),
      );
    }
  });
}

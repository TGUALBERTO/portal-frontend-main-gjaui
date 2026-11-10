import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/fonts.dart';
import '../../support/golden.dart';
import '../../support/traceability.dart';

const _s = Key('separator');
final _line = const BorderSide().width;

/// Monta [child] sob [theme], numa coluna de 300.
Widget _themed(Widget child, {GjaThemeData? theme}) => GjaTheme(
  data: theme ?? GjaThemeData.light(),
  duration: Duration.zero,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 300, child: child),
    ),
  ),
);

Finder _strokeOf(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(ColoredBox));

/// Retângulo da linha pintada (o `ColoredBox`) do separador de chave [key].
Rect _stroke(WidgetTester tester, [Key key = _s]) =>
    tester.getRect(_strokeOf(key));

Color _color(WidgetTester tester) =>
    tester.widget<ColoredBox>(_strokeOf(_s)).color;

/// Amostra dos goldens: lista com separadores horizontais e barra com
/// separador vertical entre as ações.
Widget _sample() => GjaVBox(
  gap: GjaSpace.l,
  items: [
    const GjaVBox(
      gap: GjaSpace.s,
      items: [
        GjaText('Item 1'),
        GjaSeparator(),
        GjaText('Item 2'),
        GjaSeparator(),
        GjaText('Item 3'),
      ],
    ),
    GjaBar(
      contentLeft: [
        GjaButton(text: 'Salvar', onPress: () {}),
        const GjaSeparator.vertical(),
        GjaButton(text: 'Copiar', onPress: () {}),
        GjaButton(text: 'Excluir', onPress: () {}),
      ],
    ),
  ],
);

void main() {
  setUpAll(loadGjaFonts);

  testWidgets('[API] Propriedades — Separador mínimo', (tester) async {
    await tester.pumpWidget(
      const GjaApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 300, child: GjaSeparator(key: _s)),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(_s)), Size(300, _line));
    expect(_color(tester), GjaThemeData.light().colors.separator);
  });

  testWidgets('[API] Callbacks e controlador — Separador sem ação', (
    tester,
  ) async {
    await tester.pumpWidget(_themed(const GjaSeparator(key: _s)));
    await tester.tapAt(tester.getCenter(find.byKey(_s)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byKey(_s),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
  });

  group('[Comportamento] Orientação', () {
    testWidgets('[Comportamento] Orientação — Separador vertical numa barra', (
      tester,
    ) async {
      final theme = GjaThemeData.light();
      await tester.pumpWidget(
        _themed(
          GjaBar(
            contentLeft: [
              GjaButton(text: 'Salvar', onPress: () {}),
              const GjaSeparator.vertical(key: _s),
              GjaButton(text: 'Copiar', onPress: () {}),
            ],
          ),
        ),
      );
      final stroke = _stroke(tester);
      final bar = tester.getRect(find.byType(GjaBar));
      expect(stroke.size, Size(_line, theme.density.separatorHeight));
      expect(theme.density.separatorHeight, lessThan(theme.density.barHeight));
      expect(stroke.center.dy, closeTo(bar.center.dy, 0.5));
    });

    testWidgets(
      '[Comportamento] Orientação — Separador vertical numa linha esticada',
      (tester) async {
        await tester.pumpWidget(
          _themed(
            const SizedBox(
              height: 80,
              child: GjaHBox(
                alignItems: GjaFlexAlignItems.stretch,
                items: [
                  GjaText('a'),
                  GjaSeparator.vertical(key: _s),
                  GjaText('b'),
                ],
              ),
            ),
          ),
        );
        expect(
          _stroke(tester).size,
          Size(_line, GjaThemeData.light().density.separatorHeight),
        );
      },
    );
  });

  testWidgets('[Aparência] Tokens de componente — Troca de tema do separador', (
    tester,
  ) async {
    for (final theme in [GjaThemeData.light(), GjaThemeData.dark()]) {
      await tester.pumpWidget(
        _themed(const GjaSeparator(key: _s), theme: theme),
      );
      await tester.pumpAndSettle();
      expect(_color(tester), theme.colors.separator);
    }
  });

  testWidgets(
    '[Estados] Sem estados de interação — Separador não recebe foco',
    (tester) async {
      final first = FocusNode();
      final second = FocusNode();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await tester.pumpWidget(
        GjaApp(
          home: Column(
            children: [
              Focus(
                focusNode: first,
                child: const SizedBox(width: 20, height: 20),
              ),
              const GjaSeparator(),
              Focus(
                focusNode: second,
                child: const SizedBox(width: 20, height: 20),
              ),
            ],
          ),
        ),
      );
      first.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(second.hasPrimaryFocus, isTrue);
    },
  );

  testWidgets(
    '[Acessibilidade] Teclado e foco — Teclas ignoradas pelo separador',
    (tester) async {
      await tester.pumpWidget(
        const GjaApp(home: Center(child: GjaSeparator())),
      );
      for (final key in [
        LogicalKeyboardKey.tab,
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.space,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
      }
      expect(find.byType(GjaSeparator), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '[Acessibilidade] Semântica e contraste — Separador fora da semântica',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _themed(
          const Column(
            children: [
              GjaText('Antes'),
              GjaSeparator(key: _s),
              GjaText('Depois'),
            ],
          ),
        ),
      );
      final labels = <String>[];
      bool visit(SemanticsNode node) {
        if (node.label.isNotEmpty) labels.add(node.label);
        node.visitChildren(visit);
        return true;
      }

      visit(
        tester
            .binding
            .renderViews
            .first
            .owner!
            .semanticsOwner!
            .rootSemanticsNode!,
      );
      expect(labels.join('\n').split('\n'), ['Antes', 'Depois']);
      expect(
        find.descendant(
          of: find.byKey(_s),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    },
  );

  testWidgets('[Responsividade] Densidade — Densidade compacta do separador', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themed(
        const GjaHBox(
          items: [
            GjaSeparator.vertical(key: Key('cozy')),
            GjaTheme.density(
              density: GjaDensity.compact,
              child: GjaSeparator.vertical(key: Key('compact')),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final cozy = _stroke(tester, const Key('cozy')).size;
    final compact = _stroke(tester, const Key('compact')).size;
    expect(cozy.height, GjaThemeData.light().density.separatorHeight);
    expect(
      compact.height,
      GjaThemeData.light(
        density: GjaDensity.compact,
      ).density.separatorHeight,
    );
    expect(compact.height, lessThan(cozy.height));
    expect(compact.width, cozy.width);
  });

  testWidgets('[Integração] Dependências — Separador sem Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      const GjaApp(
        home: Column(
          children: [
            GjaSeparator(),
            GjaHBox(items: [GjaSeparator.vertical()]),
          ],
        ),
      ),
    );
    expect(find.byType(GjaSeparator), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    testWidgets('[Testes] Cobertura exigida — Goldens do separador', (
      tester,
    ) async {
      for (final (name, theme) in goldenThemes) {
        // Recria a árvore a cada tema, para não capturar a barra no meio da
        // animação de densidade.
        await tester.pumpWidget(const SizedBox());
        await expectGolden(
          tester,
          name: 'gja_separator_$name',
          theme: theme,
          child: SizedBox(width: 360, child: _sample()),
          size: const Size(420, 220),
        );
      }
    }, tags: ['golden']);

    test('[Testes] Cobertura exigida — Rastreabilidade do separador', () {
      final names = scenarioNames(
        'gja/widgets/gja-separator',
        'update-gja-divider-fiori-separator',
      );
      expect(names, hasLength(14));
      expect(untestedScenarios(names), isEmpty);
    });
  });

  test('[Restrições] Fora do escopo — Separador sem parâmetros visuais', () {
    final source = File(
      'lib/src/fundacao_layout/separator/gja_separator.dart',
    ).readAsStringSync();
    final ctors = RegExp(
      r'const GjaSeparator(?:\.\w+)?\((.*?)\)\s*:',
      dotAll: true,
    ).allMatches(source).map((m) => m.group(1)!.trim()).toList();
    expect(ctors, ['{super.key}', '{super.key}']);
  });
}

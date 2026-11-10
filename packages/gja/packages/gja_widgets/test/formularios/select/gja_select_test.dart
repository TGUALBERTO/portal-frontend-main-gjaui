import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/golden.dart';
import '../../support/traceability.dart';

final _light = GjaThemeData.light();

const _items = [
  GjaDropdownItem(key: 'aberto', text: 'Em aberto'),
  GjaDropdownItem(key: 'aprovado', text: 'Aprovado'),
  GjaDropdownItem(key: 'recusado', text: 'Recusado'),
];

Widget _app(
  Widget home, {
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  double width = 300,
}) => GjaApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: Directionality(textDirection: direction, child: child!),
  ),
  home: Center(
    child: SizedBox(width: width, child: home),
  ),
);

/// Campo que guarda o próprio valor e registra cada `onChange`.
Widget _stateful(List<String> log, {String? initial = 'aberto'}) {
  var key = initial;
  return StatefulBuilder(
    builder: (context, setState) => GjaSelect<String>(
      semanticLabel: 'Status',
      items: _items,
      selectedKey: key,
      onChange: (value) {
        log.add(value);
        setState(() => key = value);
      },
    ),
  );
}

/// Moldura do campo de [index].
Finder _frame([int index = 0]) => find
    .descendant(
      of: find.byType(GjaSelect<String>).at(index),
      matching: find.byType(DecoratedBox),
    )
    .first;

BoxDecoration _decoration(WidgetTester tester, [int index = 0]) =>
    tester.widget<DecoratedBox>(_frame(index)).decoration as BoxDecoration;

Color _border(WidgetTester tester, [int index = 0]) =>
    (_decoration(tester, index).border! as Border).top.color;

Finder get _arrow => find.byIcon(GjaIcons.slimArrowDown);

void main() {
  testWidgets('[API] Propriedades — Seleção mínima', (tester) async {
    await tester.pumpWidget(_app(_stateful([], initial: 'aprovado')));
    final size = tester.getSize(_frame());
    expect(size.width, 300);
    expect(size.height, _light.density.controlHeight);
    expect(find.text('Aprovado'), findsOneWidget);
    expect(
      tester.getCenter(_arrow).dx,
      greaterThan(tester.getCenter(find.text('Aprovado')).dx),
    );
  });

  test('[API] Rótulo válido — Seleção sem rótulo', () {
    expect(
      () => GjaSelect<String>(semanticLabel: '', items: _items),
      throwsAssertionError,
    );
    expect(
      () => GjaSelect<String>(semanticLabel: 'x', items: const []),
      throwsAssertionError,
    );
  });

  testWidgets('[API] Callbacks e controlador — Trocar o item', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(_app(_stateful(log)));
    await tester.tap(find.byType(GjaSelect<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recusado').last);
    await tester.pumpAndSettle();
    expect(log, ['recusado']);
    expect(find.text('Recusado'), findsOneWidget);
    expect(find.text('Em aberto'), findsNothing);
  });

  testWidgets('[Comportamento] Abrir pelo teclado — Abrir com Espaço', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(_app(_stateful(log, initial: 'aprovado')));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('Recusado'), findsOneWidget);
    final focusedText = FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<GjaInteractable>()
        ?.semanticLabel;
    expect(focusedText, 'Aprovado');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Recusado'), findsNothing);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<GjaSelect<String>>(),
      isNotNull,
    );
    expect(log, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    await tester.pumpAndSettle();
    expect(find.text('Recusado'), findsOneWidget);
  });

  testWidgets('[Comportamento] Espaço reservado — Campo sem escolha', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        GjaSelect<String>(
          semanticLabel: 'Status',
          placeholder: 'Escolha',
          items: _items,
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('Escolha')).style?.color,
      _light.colors.label,
    );
  });

  testWidgets('[Aparência] Tokens de componente — Aparência da seleção', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GjaSelect<String>(
              semanticLabel: 'a',
              items: _items,
              selectedKey: 'aberto',
            ),
            GjaSelect<String>(
              semanticLabel: 'b',
              items: _items,
              valueState: GjaValueState.error,
            ),
            GjaSelect<String>(
              semanticLabel: 'c',
              items: _items,
              selectedKey: 'aberto',
              editable: false,
            ),
          ],
        ),
      ),
    );
    expect(_decoration(tester).color, _light.colors.base);
    expect(_border(tester), _light.colors.fieldBorder);
    final error = _light.colors.stateColors(GjaValueState.error);
    expect(_decoration(tester, 1).color, error.background);
    expect(_border(tester, 1), error.border);
    expect(_decoration(tester, 2).color, _light.colors.headerBackground);
    expect(_arrow, findsNWidgets(2));
    final arrow = tester.widget<Icon>(_arrow.first);
    expect(arrow.color, _light.colors.brand);
    expect(arrow.size, _light.icons.control);
  });

  group('[Estados] Interação', () {
    testWidgets('[Estados] Interação — Seleção somente leitura', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          GjaSelect<String>(
            semanticLabel: 'r',
            items: _items,
            selectedKey: 'aberto',
            editable: false,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<GjaSelect<String>>(),
        isNotNull,
      );
      await tester.tap(find.byType(GjaSelect<String>));
      await tester.pumpAndSettle();
      expect(find.text('Recusado'), findsNothing);
    });

    testWidgets('[Estados] Interação — Seleção desabilitada', (tester) async {
      await tester.pumpWidget(
        _app(
          GjaSelect<String>(
            semanticLabel: 'd',
            items: _items,
            selectedKey: 'aberto',
            enabled: false,
          ),
        ),
      );
      await tester.tap(find.byType(GjaSelect<String>), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Recusado'), findsNothing);
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(GjaSelect<String>),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        _light.interaction.disabledOpacity,
      );
    });

    testWidgets('[Estados] Interação — Mensagem da seleção', (tester) async {
      await tester.pumpWidget(
        _app(
          GjaSelect<String>(
            semanticLabel: 'm',
            items: _items,
            valueState: GjaValueState.error,
            valueStateText: 'Escolha um status',
          ),
        ),
      );
      expect(find.text('Escolha um status'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(find.text('Escolha um status'), findsOneWidget);
      expect(_border(tester), _light.colors.brand);
    });
  });

  testWidgets('[Acessibilidade] Semântica — Semântica da seleção', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(_stateful([], initial: 'aprovado')));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Status')),
      containsSemantics(
        isButton: true,
        label: 'Status',
        value: 'Aprovado',
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets(
    '[Acessibilidade] Contraste e alvo — Contraste e alvo da seleção',
    (tester) async {
      final handle = tester.ensureSemantics();
      for (final (_, theme) in goldenThemes) {
        await tester.pumpWidget(
          GjaApp(
            key: ValueKey(theme),
            theme: theme,
            darkTheme: theme,
            density: theme.density.density,
            home: GjaContainer(
              surface: GjaSurface.background,
              child: Center(
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GjaSelect<String>(
                        semanticLabel: 'a',
                        items: _items,
                        selectedKey: 'aberto',
                        onChange: (_) {},
                      ),
                      GjaSelect<String>(
                        semanticLabel: 'b',
                        items: _items,
                        placeholder: 'Escolha',
                        onChange: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(
          tester,
          meetsGuideline(
            MinimumTapTargetGuideline(
              size: Size.square(
                GjaAccessibility.minTargetSize(theme.density),
              ),
              link: GjaAccessibility.targetSizeLink,
            ),
          ),
        );
      }
      await tester.pumpWidget(
        _app(textScale: 2, width: 200, _stateful([], initial: 'aprovado')),
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    },
  );

  testWidgets('[Responsividade] Largura e direção — Seleção em RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(direction: TextDirection.rtl, _stateful([], initial: 'aprovado')),
    );
    expect(
      tester.getCenter(_arrow).dx,
      lessThan(tester.getCenter(_frame()).dx),
    );
  });

  testWidgets('[Integração] Dependências — Seleção sem Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stateful([]),
            GjaSelect<String>(
              semanticLabel: 'r',
              items: _items,
              editable: false,
            ),
            GjaSelect<String>(
              semanticLabel: 'd',
              items: _items,
              enabled: false,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byType(GjaSelect<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aprovado').last);
    await tester.pumpAndSettle();
    for (final i in [1, 2]) {
      await tester.tap(
        find.byType(GjaSelect<String>).at(i),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade da seleção', () {
      final names = scenarioNames(
        'gja/widgets/gja-select',
        'add-gja-select',
      );
      expect(names, hasLength(17));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens da seleção', (
      tester,
    ) async {
      for (final (name, theme) in goldenThemes) {
        await tester.pumpWidget(const SizedBox());
        await expectGolden(
          tester,
          name: 'gja_select_$name',
          theme: theme,
          size: const Size(380, 500),
          child: SizedBox(
            width: 300,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (_) => GjaVBox(
                    gap: GjaSpace.xxs,
                    items: [
                      GjaSelect<String>(
                        semanticLabel: 'a',
                        items: _items,
                        selectedKey: 'aprovado',
                        onChange: (_) {},
                      ),
                      GjaSelect<String>(
                        semanticLabel: 'b',
                        items: _items,
                        placeholder: 'Escolha um status',
                        onChange: (_) {},
                      ),
                      for (final state in GjaValueState.values.skip(1))
                        GjaSelect<String>(
                          semanticLabel: state.name,
                          items: _items,
                          selectedKey: 'aberto',
                          valueState: state,
                          onChange: (_) {},
                        ),
                      GjaSelect<String>(
                        semanticLabel: 'r',
                        items: _items,
                        selectedKey: 'aberto',
                        editable: false,
                      ),
                      GjaSelect<String>(
                        semanticLabel: 'd',
                        items: _items,
                        selectedKey: 'aberto',
                        enabled: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Seleção sem valor literal', () {
    final source = File(
      'lib/src/formularios/select/gja_select.dart',
    ).readAsStringSync();
    final fields = RegExp(
      r'^  final (\S+) (\w+);$',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!).toList();
    expect(fields, isNotEmpty);
    for (final type in fields) {
      expect(type, isNot(anyOf('double', 'double?', 'Color', 'Color?')));
    }
  });
}

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
  GjaNavigationListItem(key: 'inicio', text: 'Início', icon: GjaIcons.home),
  GjaNavigationListItem(
    key: 'pedidos',
    text: 'Pedidos',
    icon: GjaIcons.document,
  ),
  GjaNavigationListItem(
    key: 'clientes',
    text: 'Clientes',
    icon: GjaIcons.personPlaceholder,
  ),
];

const _nested = [
  GjaNavigationListItem(key: 'inicio', text: 'Início', icon: GjaIcons.home),
  GjaNavigationListItem(
    key: 'vendas',
    text: 'Vendas',
    icon: GjaIcons.document,
    items: [
      GjaNavigationListItem(key: 'pedidos', text: 'Pedidos'),
      GjaNavigationListItem(key: 'faturas', text: 'Faturas'),
    ],
  ),
  GjaNavigationListItem(
    key: 'relatorios',
    text: 'Relatórios',
    icon: GjaIcons.folderBlank,
    enabled: false,
  ),
];

const _fixed = [
  GjaNavigationListItem(
    key: 'ajuda',
    text: 'Ajuda',
    icon: GjaIcons.sysHelp,
  ),
];

Widget _app(Widget home, {TextDirection direction = TextDirection.ltr}) =>
    GjaApp(
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(height: 600, child: home),
      ),
    );

/// Navegação que guarda o próprio item e registra cada `onItemSelect`.
Widget _stateful(
  List<String> log, {
  String? initial,
  List<GjaNavigationListItem<String>> items = _items,
  List<GjaNavigationListItem<String>> fixedItems = const [],
  bool expanded = true,
}) {
  var key = initial;
  return StatefulBuilder(
    builder: (context, setState) => GjaSideNavigation<String>(
      items: items,
      fixedItems: fixedItems,
      selectedKey: key,
      expanded: expanded,
      onItemSelect: (value) {
        log.add(value);
        setState(() => key = value);
      },
    ),
  );
}

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

String? _focused() => FocusManager.instance.primaryFocus?.context
    ?.findAncestorWidgetOfExactType<GjaInteractable>()
    ?.semanticLabel;

void main() {
  testWidgets('[API] Propriedades — Navegação mínima', (tester) async {
    await tester.pumpWidget(_app(_stateful([], fixedItems: _fixed)));
    final top = tester.getTopLeft(find.text('Início')).dy;
    expect(tester.getTopLeft(find.text('Pedidos')).dy, greaterThan(top));
    expect(
      tester.getTopLeft(find.text('Clientes')).dy,
      greaterThan(tester.getTopLeft(find.text('Pedidos')).dy),
    );
    expect(top, lessThan(_light.density.listItemHeight));
    expect(tester.getBottomLeft(find.text('Ajuda')).dy, greaterThan(550));
    expect(find.byType(GjaSeparator), findsOneWidget);
  });

  testWidgets('[API] Itens válidos — Navegação com chave repetida', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const GjaSideNavigation<String>(
          items: [
            GjaNavigationListItem(key: 'a', text: 'A'),
            GjaNavigationListItem(key: 'a', text: 'B'),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('[API] Callbacks e controlador — Escolher um item', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(_app(_stateful(log, initial: 'inicio')));
    await tester.tap(find.text('Clientes'));
    await tester.pump();
    expect(log, ['clientes']);
    expect(_textColor(tester, 'Clientes'), _light.colors.brand);
    expect(_textColor(tester, 'Início'), _light.colors.text);
  });

  testWidgets('[Comportamento] Subitens — Abrir subitens', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(
      _app(_stateful(log, initial: 'inicio', items: _nested)),
    );
    expect(find.text('Faturas'), findsNothing);
    await tester.tap(find.text('Vendas'));
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('Faturas')).dx,
      tester.getTopLeft(find.text('Vendas')).dx,
    );
    expect(find.byIcon(GjaIcons.slimArrowDown), findsOneWidget);
    await tester.tap(find.text('Faturas'));
    await tester.pump();
    expect(log, ['vendas', 'faturas']);
  });

  testWidgets('[Comportamento] Modo recolhido — Navegação recolhida', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(_stateful([], items: _nested, expanded: false, initial: 'pedidos')),
    );
    expect(
      tester.getSize(find.byType(GjaSideNavigation<String>)).width,
      _light.density.barHeight,
    );
    expect(find.text('Início'), findsNothing);
    expect(find.text('Pedidos'), findsNothing);
    expect(find.byIcon(GjaIcons.home), findsOneWidget);
    expect(find.semantics.byLabel('Início'), findsOneWidget);
    expect(find.semantics.byLabel('Vendas'), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(GjaIcons.document)).color,
      _light.colors.brand,
    );
    handle.dispose();
  });

  testWidgets('[Comportamento] Teclado — Setas na navegação', (tester) async {
    await tester.pumpWidget(
      _app(_stateful([], initial: 'inicio', items: _nested)),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focused(), 'Início');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_focused(), 'Vendas');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('Pedidos'), findsOneWidget);
    expect(find.text('Faturas'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_focused(), 'Pedidos');
  });

  testWidgets('[Aparência] Tokens de componente — Item escolhido', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_stateful([], initial: 'pedidos')));
    expect(_textColor(tester, 'Pedidos'), _light.colors.brand);
    expect(_textColor(tester, 'Início'), _light.colors.text);
    final box = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text('Pedidos'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (box.decoration as BoxDecoration).color,
      _light.colors.selectionBackground,
    );
    expect(
      tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Pedidos'),
                  matching: find.byType(SizedBox),
                )
                .first,
          )
          .height,
      _light.density.listItemHeight,
    );
  });

  testWidgets('[Estados] Interação — Item desabilitado', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(
      _app(_stateful(log, initial: 'inicio', items: _nested)),
    );
    await tester.tap(find.text('Relatórios'), warnIfMissed: false);
    await tester.pump();
    expect(log, isEmpty);
    final opacity = tester.widget<Opacity>(
      find
          .ancestor(of: find.text('Relatórios'), matching: find.byType(Opacity))
          .first,
    );
    expect(opacity.opacity, _light.interaction.disabledOpacity);
  });

  group('[Acessibilidade] Semântica e contraste', () {
    testWidgets(
      '[Acessibilidade] Semântica e contraste — Semântica da navegação',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(
            const GjaSideNavigation<String>(
              selectedKey: 'pedidos',
              items: [
                GjaNavigationListItem(key: 'pedidos', text: 'Pedidos'),
                GjaNavigationListItem(
                  key: 'vendas',
                  text: 'Vendas',
                  items: [
                    GjaNavigationListItem(key: 'faturas', text: 'Faturas'),
                  ],
                ),
              ],
            ),
          ),
        );
        expect(
          tester.getSemantics(find.text('Pedidos')),
          containsSemantics(isButton: true, isSelected: true, label: 'Pedidos'),
        );
        expect(
          tester.getSemantics(find.text('Vendas')),
          containsSemantics(
            isButton: true,
            isSelected: false,
            hasExpandedState: true,
            isExpanded: false,
            label: 'Vendas',
          ),
        );
        handle.dispose();
      },
    );

    testWidgets(
      '[Acessibilidade] Semântica e contraste — Contraste e alvo da navegação',
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
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    height: 500,
                    child: _stateful(
                      [],
                      initial: 'pedidos',
                      items: _nested.sublist(0, 2),
                      fixedItems: _fixed,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(textContrastGuideline));
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
        handle.dispose();
      },
    );
  });

  testWidgets('[Responsividade] Altura e direção — Navegação em RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(direction: TextDirection.rtl, _stateful([], items: _nested)),
    );
    expect(
      tester.getCenter(find.byIcon(GjaIcons.home)).dx,
      greaterThan(tester.getCenter(find.text('Início')).dx),
    );
    expect(
      tester.getCenter(find.byIcon(GjaIcons.slimArrowRight)).dx,
      lessThan(tester.getCenter(find.text('Vendas')).dx),
    );
  });

  testWidgets('[Integração] Dependências — Navegação sem Material', (
    tester,
  ) async {
    var expanded = true;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => GjaVBox(
            items: [
              GjaButton(
                text: 'Recolher',
                onPress: () => setState(() => expanded = !expanded),
              ),
              Expanded(
                child: _stateful(
                  [],
                  items: _nested,
                  fixedItems: _fixed,
                  expanded: expanded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Vendas'));
    await tester.pump();
    await tester.tap(find.text('Recolher'));
    await tester.pump();
    await tester.tap(find.byIcon(GjaIcons.home));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade da navegação', () {
      final names = scenarioNames(
        'gja/widgets/gja-side-navigation',
        'add-gja-side-navigation',
      );
      expect(names, hasLength(16));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens da navegação', (
      tester,
    ) async {
      for (final (name, theme) in goldenThemes) {
        await tester.pumpWidget(const SizedBox());
        await expectGolden(
          tester,
          name: 'gja_side_navigation_$name',
          theme: theme,
          size: const Size(420, 420),
          child: SizedBox(
            height: 400,
            child: GjaHBox(
              gap: GjaSpace.l,
              items: [
                GjaSideNavigation<String>(
                  items: _nested,
                  fixedItems: _fixed,
                  selectedKey: 'pedidos',
                  onItemSelect: (_) {},
                ),
                GjaSideNavigation<String>(
                  items: _nested,
                  fixedItems: _fixed,
                  selectedKey: 'inicio',
                  expanded: false,
                  onItemSelect: (_) {},
                ),
              ],
            ),
          ),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Navegação sem valor literal', () {
    final source = File(
      'lib/src/acoes_navegacao/side_navigation/gja_side_navigation.dart',
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

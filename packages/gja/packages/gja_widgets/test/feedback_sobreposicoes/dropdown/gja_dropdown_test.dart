import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/fonts.dart';
import '../../support/golden.dart';
import '../../support/traceability.dart';

const _items = [
  GjaDropdownItem(key: 'aberto', text: 'Em aberto', icon: GjaIcons.pending),
  GjaDropdownItem(key: 'aprovado', text: 'Aprovado', additionalText: '12'),
  GjaDropdownItem(key: 'arquivado', text: 'Arquivado', enabled: false),
  GjaDropdownItem(key: 'rejeitado', text: 'Rejeitado'),
];

/// Aplicação de teste com [home] sob [theme], na direção [direction] e com a
/// escala de texto [textScale].
Widget _app(
  Widget home, {
  GjaThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
}) => GjaApp(
  theme: theme,
  darkTheme: theme,
  density: theme?.density.density,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: Directionality(
      textDirection: direction,
      child: RepaintBoundary(key: const Key('golden'), child: child!),
    ),
  ),
  home: home,
);

GjaPopoverController _controller() {
  final controller = GjaPopoverController();
  addTearDown(controller.dispose);
  return controller;
}

/// Dropdown de [items] sob uma âncora de [width], a 40 do canto superior
/// inicial.
Widget _dropdown(
  GjaPopoverController controller, {
  List<GjaDropdownItem<String>> items = _items,
  String? selectedKey,
  ValueChanged<String>? onSelectionChange,
  VoidCallback? onDismiss,
  double width = 240,
  Widget? anchor,
}) => Padding(
  padding: const EdgeInsetsDirectional.only(start: 40, top: 40),
  child: Align(
    alignment: AlignmentDirectional.topStart,
    child: GjaDropdown<String>(
      controller: controller,
      semanticLabel: 'Status',
      items: items,
      selectedKey: selectedKey,
      onSelectionChange: onSelectionChange ?? (_) {},
      onDismiss: onDismiss,
      child:
          anchor ??
          SizedBox(key: const Key('anchor'), width: width, height: 24),
    ),
  ),
);

Future<void> _open(
  WidgetTester tester,
  GjaPopoverController controller,
) async {
  controller.open();
  await tester.pumpAndSettle();
}

/// O item de rótulo [label].
Finder _item(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(GjaInteractable))
    .first;

/// A superfície da lista aberta.
Finder _panel() => find
    .ancestor(of: find.text('Em aberto'), matching: find.byType(GjaContainer))
    .first;

/// Fundo pintado no item [label].
Color _background(WidgetTester tester, String label) => tester
    .widget<ColoredBox>(
      find
          .descendant(of: _item(label), matching: find.byType(ColoredBox))
          .first,
    )
    .color;

bool _focused(WidgetTester tester, String label) =>
    Focus.of(tester.element(find.text(label))).hasPrimaryFocus;

final _light = GjaThemeData.light();

void main() {
  group('[API] Propriedades', () {
    testWidgets('[API] Propriedades — Dropdown com itens', (tester) async {
      final controller = _controller();
      await tester.pumpWidget(_app(_dropdown(controller)));
      await _open(tester, controller);
      final open = tester.getRect(_item('Em aberto'));
      final approved = tester.getRect(_item('Aprovado'));
      final rejected = tester.getRect(_item('Rejeitado'));
      expect(open.bottom, lessThanOrEqualTo(approved.top));
      expect(approved.bottom, lessThanOrEqualTo(rejected.top));
      final icon = tester.getRect(find.byIcon(GjaIcons.pending));
      expect(
        icon.right,
        lessThanOrEqualTo(tester.getRect(find.text('Em aberto')).left),
      );
      expect(
        tester.getRect(find.text('12')).right,
        closeTo(approved.right - _light.spacing.m, 0.01),
      );
    });

    testWidgets('[API] Propriedades — Item selecionado', (tester) async {
      final controller = _controller();
      await tester.pumpWidget(
        _app(_dropdown(controller, selectedKey: 'aprovado')),
      );
      await _open(tester, controller);
      for (final item in _items) {
        expect(
          tester.widget<GjaInteractable>(_item(item.text)).selected,
          item.key == 'aprovado',
          reason: item.text,
        );
      }
    });
  });

  test('[API] Itens válidos — Valores repetidos', () {
    final controller = GjaPopoverController();
    addTearDown(controller.dispose);
    expect(
      () => GjaDropdown<String>(
        controller: controller,
        semanticLabel: 'Status',
        items: const [
          GjaDropdownItem(key: 'a', text: 'A'),
          GjaDropdownItem(key: 'a', text: 'B'),
        ],
        onSelectionChange: (_) {},
        child: const SizedBox(),
      ),
      throwsAssertionError,
    );
  });

  group('[API] Callbacks e controlador', () {
    testWidgets('[API] Callbacks e controlador — Escolha de um item', (
      tester,
    ) async {
      final controller = _controller();
      final chosen = <String>[];
      var dismissed = 0;
      await tester.pumpWidget(
        _app(
          _dropdown(
            controller,
            onSelectionChange: chosen.add,
            onDismiss: () => dismissed++,
          ),
        ),
      );
      await _open(tester, controller);
      await tester.tap(find.text('Aprovado'));
      await tester.pumpAndSettle();
      expect(chosen, ['aprovado']);
      expect(controller.isOpen, isFalse);
      expect(dismissed, 0);
    });

    testWidgets('[API] Callbacks e controlador — Item desabilitado', (
      tester,
    ) async {
      final controller = _controller();
      final chosen = <String>[];
      await tester.pumpWidget(
        _app(_dropdown(controller, onSelectionChange: chosen.add)),
      );
      await _open(tester, controller);
      await tester.tap(find.text('Arquivado'));
      await tester.pumpAndSettle();
      expect(chosen, isEmpty);
      expect(controller.isOpen, isTrue);
    });
  });

  group('[Comportamento] Largura e texto', () {
    testWidgets(
      '[Comportamento] Largura e texto — Lista na largura da âncora',
      (tester) async {
        final controller = _controller();
        await tester.pumpWidget(_app(_dropdown(controller, width: 300)));
        await _open(tester, controller);
        expect(tester.getRect(_panel()).width, closeTo(300, 0.01));
        for (final item in _items) {
          expect(tester.getRect(_item(item.text)).width, closeTo(300, 0.01));
        }
      },
    );

    testWidgets('[Comportamento] Largura e texto — Âncora estreita', (
      tester,
    ) async {
      final controller = _controller();
      await tester.pumpWidget(_app(_dropdown(controller, width: 40)));
      await _open(tester, controller);
      expect(
        tester.getRect(_panel()).width,
        closeTo(_light.spacing.xxxl * 6, 0.01),
      );
    });

    testWidgets('[Comportamento] Largura e texto — Rótulo longo', (
      tester,
    ) async {
      const long =
          'Aguardando aprovação do gestor de compras e do departamento '
          'financeiro antes do faturamento';
      final controller = _controller();
      await tester.pumpWidget(
        _app(
          _dropdown(
            controller,
            items: const [
              GjaDropdownItem(key: 'aberto', text: 'Em aberto'),
              GjaDropdownItem(key: 'longo', text: long, additionalText: '12'),
            ],
          ),
        ),
      );
      await _open(tester, controller);
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text(long));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      final panel = tester.getRect(_panel());
      final count = tester.getRect(find.text('12'));
      expect(count.right, lessThanOrEqualTo(panel.right));
      expect(count.left, greaterThan(tester.getRect(find.text(long)).left));
    });
  });

  testWidgets('[Aparência] Itens da lista — Itens da lista', (tester) async {
    for (final base in [GjaThemeData.light(), GjaThemeData.dark()]) {
      for (final density in GjaDensity.values) {
        final theme = base.withDensity(density);
        final controller = _controller();
        await tester.pumpWidget(
          _app(
            theme: theme,
            KeyedSubtree(
              key: ValueKey((theme.brightness, density)),
              child: _dropdown(controller),
            ),
          ),
        );
        await _open(tester, controller);
        final normal = GjaControlColors.of(
          GjaControlFamily.list,
          theme.colors,
        ).resolve({});
        expect(_background(tester, 'Rejeitado'), normal.background);
        expect(
          tester.widget<Text>(find.text('Rejeitado')).style!.color,
          normal.text,
        );
        final box = find
            .descendant(
              of: _item('Rejeitado'),
              matching: find.byType(ColoredBox),
            )
            .first;
        expect(
          tester.getSize(box).height,
          closeTo(theme.density.controlHeight, 0.01),
        );
        expect(
          tester.getRect(find.byIcon(GjaIcons.pending)).left,
          closeTo(
            tester.getRect(_item('Em aberto')).left + theme.spacing.m,
            0.01,
          ),
        );
      }
    }
  });

  group('[Estados] Hover, ativo, selecionado e desabilitado', () {
    testWidgets(
      '[Estados] Hover, ativo, selecionado e desabilitado — Item em hover',
      (tester) async {
        final controller = _controller();
        await tester.pumpWidget(
          _app(_dropdown(controller, selectedKey: 'aprovado')),
        );
        await _open(tester, controller);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(_item('Em aberto')));
        await tester.pump();
        expect(_background(tester, 'Em aberto'), _light.colors.hoverBackground);
        await mouse.moveTo(tester.getCenter(_item('Aprovado')));
        await tester.pump();
        expect(
          _background(tester, 'Aprovado'),
          _light.colors.selectionHoverBackground,
        );
      },
    );

    testWidgets(
      '[Estados] Hover, ativo, selecionado e desabilitado — Aparência do item desabilitado',
      (tester) async {
        final controller = _controller();
        await tester.pumpWidget(_app(_dropdown(controller)));
        await _open(tester, controller);
        double opacity(String label) => tester
            .widget<Opacity>(
              find
                  .descendant(of: _item(label), matching: find.byType(Opacity))
                  .first,
            )
            .opacity;
        expect(
          opacity('Arquivado'),
          _light.interaction.opacity({GjaInteractionState.disabled}),
        );
        expect(opacity('Arquivado'), lessThan(1));
        expect(opacity('Aprovado'), 1);
        expect(opacity('Rejeitado'), 1);
      },
    );
  });

  group('[Acessibilidade] Teclado', () {
    testWidgets('[Acessibilidade] Teclado — Navegação pelas setas', (
      tester,
    ) async {
      final controller = _controller();
      final anchor = FocusNode();
      addTearDown(anchor.dispose);
      final chosen = <String>[];
      await tester.pumpWidget(
        _app(
          _dropdown(
            controller,
            selectedKey: 'aprovado',
            onSelectionChange: chosen.add,
            anchor: Focus(
              focusNode: anchor,
              child: const SizedBox(width: 240, height: 24),
            ),
          ),
        ),
      );
      anchor.requestFocus();
      await tester.pump();
      await _open(tester, controller);
      expect(_focused(tester, 'Aprovado'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_focused(tester, 'Rejeitado'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_focused(tester, 'Rejeitado'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(_focused(tester, 'Em aberto'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, ['aberto']);
      expect(controller.isOpen, isFalse);
      expect(anchor.hasPrimaryFocus, isTrue);
    });

    testWidgets('[Acessibilidade] Teclado — Busca pela primeira letra', (
      tester,
    ) async {
      final controller = _controller();
      await tester.pumpWidget(_app(_dropdown(controller)));
      await _open(tester, controller);
      expect(_focused(tester, 'Em aberto'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      expect(_focused(tester, 'Rejeitado'), isTrue);
    });
  });

  testWidgets('[Acessibilidade] Semântica — Semântica dos itens', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = _controller();
    await tester.pumpWidget(
      _app(_dropdown(controller, selectedKey: 'aprovado')),
    );
    await _open(tester, controller);
    final routes = [
      for (final element in find.bySemanticsLabel('Status').evaluate())
        tester.getSemantics(
          find.byElementPredicate((candidate) => candidate == element),
        ),
    ].where((node) => node.hasFlag(SemanticsFlag.namesRoute)).toSet();
    expect(routes, hasLength(1));
    expect(
      tester.getSemantics(_item('Aprovado')),
      containsSemantics(
        label: 'Aprovado, 12',
        isButton: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(_item('Arquivado')),
      containsSemantics(
        label: 'Arquivado',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  group('[Responsividade] Direção e escala', () {
    testWidgets('[Responsividade] Direção e escala — Dropdown em RTL', (
      tester,
    ) async {
      final controller = _controller();
      await tester.pumpWidget(
        _app(direction: TextDirection.rtl, _dropdown(controller)),
      );
      await _open(tester, controller);
      final open = tester.getRect(_item('Em aberto'));
      final approved = tester.getRect(_item('Aprovado'));
      expect(
        tester.getRect(find.byIcon(GjaIcons.pending)).right,
        closeTo(open.right - _light.spacing.m, 0.01),
      );
      expect(
        tester.getRect(find.text('12')).left,
        closeTo(approved.left + _light.spacing.m, 0.01),
      );
    });

    testWidgets(
      '[Responsividade] Direção e escala — Dropdown com escala de texto 2,0',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(400, 400);
        addTearDown(tester.view.reset);
        final controller = _controller();
        await tester.pumpWidget(
          _app(
            textScale: 2,
            _dropdown(
              controller,
              items: [
                const GjaDropdownItem(key: 'aberto', text: 'Em aberto'),
                for (var i = 2; i <= 12; i++)
                  GjaDropdownItem(key: '$i', text: 'Item $i'),
              ],
            ),
          ),
        );
        await _open(tester, controller);
        expect(tester.takeException(), isNull);
        await tester.drag(find.text('Item 2'), const Offset(0, -3000));
        await tester.pumpAndSettle();
        final last = tester.getRect(find.text('Item 12'));
        expect(last.top, greaterThanOrEqualTo(0));
        expect(last.bottom, lessThanOrEqualTo(400));
        expect(tester.takeException(), isNull);
      },
    );
  });

  testWidgets('[Integração] Dependências — Dropdown sem Material', (
    tester,
  ) async {
    final controller = _controller();
    final chosen = <String>[];
    await tester.pumpWidget(
      _app(
        _dropdown(
          controller,
          onSelectionChange: chosen.add,
          anchor: GjaButton(text: 'Status', onPress: controller.toggle),
        ),
      ),
    );
    await tester.tap(find.text('Status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aprovado'));
    await tester.pumpAndSettle();
    expect(chosen, ['aprovado']);
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade do dropdown', () {
      final names = scenarioNames(
        'gja/widgets/gja-dropdown',
        'add-gja-dropdown',
      );
      expect(names, hasLength(22));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens do dropdown', (
      tester,
    ) async {
      await loadGjaFonts();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(720, 480);
      addTearDown(tester.view.reset);
      for (final (name, theme) in goldenThemes) {
        // Cada captura parte de uma aplicação nova: trocar o tema da mesma
        // GjaApp anima a densidade, e a sobreposição abriria com a âncora
        // no meio da transição.
        await tester.pumpWidget(const SizedBox());
        final controller = _controller();
        await tester.pumpWidget(
          _app(
            theme: theme,
            // O fundo da aplicação fica fora da captura; a amostra o pinta.
            GjaContainer(
              key: ValueKey(name),
              surface: GjaSurface.background,
              child: _dropdown(
                controller,
                selectedKey: 'aprovado',
                // Âncora no formato de um campo, como a de um futuro
                // GjaSelect: a lista fica na largura dela.
                anchor: SizedBox(
                  width: theme.spacing.xxxl * 6,
                  child: const GjaContainer(
                    surface: GjaSurface.base,
                    border: true,
                    radius: GjaRadius.field,
                    child: GjaSpacing.padding(
                      horizontal: GjaSpace.m,
                      vertical: GjaSpace.s,
                      child: GjaText('Aprovado'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await _open(tester, controller);
        await expectLater(
          find.byKey(const Key('golden')),
          matchesGoldenFile('goldens/gja_dropdown_$name.png'),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Dropdown sem valor literal', () {
    final source = File(
      'lib/src/feedback_sobreposicoes/dropdown/gja_dropdown.dart',
    ).readAsStringSync();
    final fields = RegExp(
      r'^  final (\S+) (\w+);$',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!).toList();
    expect(fields, isNotEmpty);
    for (final type in fields) {
      expect(
        type.replaceAll('?', ''),
        isNot(isIn(['double', 'Color', 'EdgeInsets'])),
      );
    }
  });
}

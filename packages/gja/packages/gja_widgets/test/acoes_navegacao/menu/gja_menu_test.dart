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

/// Itens de teste; [log] recebe o rótulo de cada item acionado.
List<GjaMenuItem> _items(List<String> log) => [
  GjaMenuItem(
    text: 'Editar',
    icon: GjaIcons.edit,
    shortcutText: 'Ctrl+E',
    onPress: () => log.add('Editar'),
  ),
  GjaMenuItem(
    text: 'Copiar',
    icon: GjaIcons.copy,
    shortcutText: 'Ctrl+C',
    onPress: () => log.add('Copiar'),
  ),
  const GjaMenuItem(
    text: 'Exportar',
    icon: GjaIcons.download,
    enabled: false,
  ),
  GjaMenuItem(
    text: 'Excluir',
    icon: GjaIcons.delete,
    startsSection: true,
    onPress: () => log.add('Excluir'),
  ),
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

/// Menu de [items] sob uma âncora de [width], a 40 do canto superior inicial.
Widget _menu(
  GjaPopoverController controller,
  List<GjaMenuItem> items, {
  VoidCallback? onDismiss,
  double width = 240,
  Widget? anchor,
}) => Padding(
  padding: const EdgeInsetsDirectional.only(start: 40, top: 40),
  child: Align(
    alignment: AlignmentDirectional.topStart,
    child: GjaMenu(
      controller: controller,
      semanticLabel: 'Ações',
      items: items,
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

/// A superfície do menu aberto.
Finder _panel() => find
    .ancestor(of: find.text('Editar'), matching: find.byType(GjaContainer))
    .first;

Color _background(WidgetTester tester, String label) => tester
    .widget<ColoredBox>(
      find
          .descendant(of: _item(label), matching: find.byType(ColoredBox))
          .first,
    )
    .color;

bool _focused(WidgetTester tester, String label) =>
    Focus.of(tester.element(find.text(label))).hasPrimaryFocus;

/// Papéis dos ancestrais semânticos de [node].
List<SemanticsRole> _ancestorRoles(SemanticsNode node) => [
  for (SemanticsNode? n = node.parent; n != null; n = n.parent)
    n.getSemanticsData().role,
];

final _light = GjaThemeData.light();

void main() {
  group('[API] Propriedades', () {
    testWidgets('[API] Propriedades — Menu com itens', (tester) async {
      final controller = _controller();
      await tester.pumpWidget(
        _app(_menu(controller, _items([]).take(3).toList())),
      );
      await _open(tester, controller);
      final edit = tester.getRect(_item('Editar'));
      final copy = tester.getRect(_item('Copiar'));
      final export = tester.getRect(_item('Exportar'));
      expect(edit.bottom, lessThanOrEqualTo(copy.top));
      expect(copy.bottom, lessThanOrEqualTo(export.top));
      expect(
        tester.getRect(find.byIcon(GjaIcons.edit)).right,
        lessThanOrEqualTo(tester.getRect(find.text('Editar')).left),
      );
      expect(
        tester.getRect(find.text('Ctrl+E')).right,
        closeTo(edit.right - _light.spacing.m, 0.01),
      );
    });

    testWidgets('[API] Propriedades — Separador de seção', (tester) async {
      final controller = _controller();
      final items = _items([]);
      await tester.pumpWidget(
        _app(_menu(controller, [items[0], items[1], items[3]])),
      );
      await _open(tester, controller);
      expect(find.byType(GjaSeparator), findsOneWidget);
      final separator = tester.getRect(find.byType(GjaSeparator));
      expect(
        separator.top,
        greaterThanOrEqualTo(tester.getRect(_item('Copiar')).bottom),
      );
      expect(
        separator.bottom,
        lessThanOrEqualTo(tester.getRect(_item('Excluir')).top),
      );
    });
  });

  test('[API] Itens válidos — Menu sem itens', () {
    final controller = GjaPopoverController();
    addTearDown(controller.dispose);
    expect(
      () => GjaMenu(
        controller: controller,
        semanticLabel: 'Ações',
        items: const [],
        child: const SizedBox(),
      ),
      throwsAssertionError,
    );
  });

  group('[API] Callbacks e controlador', () {
    testWidgets('[API] Callbacks e controlador — Acionar um item', (
      tester,
    ) async {
      final controller = _controller();
      final log = <String>[];
      var dismissed = 0;
      await tester.pumpWidget(
        _app(_menu(controller, _items(log), onDismiss: () => dismissed++)),
      );
      await _open(tester, controller);
      await tester.tap(find.text('Copiar'));
      await tester.pumpAndSettle();
      expect(log, ['Copiar']);
      expect(controller.isOpen, isFalse);
      expect(dismissed, 0);
    });

    testWidgets('[API] Callbacks e controlador — Item desabilitado', (
      tester,
    ) async {
      final controller = _controller();
      final log = <String>[];
      await tester.pumpWidget(_app(_menu(controller, _items(log))));
      await _open(tester, controller);
      await tester.tap(find.text('Exportar'));
      await tester.pumpAndSettle();
      expect(log, isEmpty);
      expect(controller.isOpen, isTrue);
    });
  });

  group('[Comportamento] Largura e texto', () {
    testWidgets('[Comportamento] Largura e texto — Menu na largura da âncora', (
      tester,
    ) async {
      final controller = _controller();
      await tester.pumpWidget(_app(_menu(controller, _items([]), width: 300)));
      await _open(tester, controller);
      expect(tester.getRect(_panel()).width, closeTo(300, 0.01));
      for (final label in ['Editar', 'Copiar', 'Exportar', 'Excluir']) {
        expect(tester.getRect(_item(label)).width, closeTo(300, 0.01));
      }
    });

    testWidgets('[Comportamento] Largura e texto — Menu sob âncora estreita', (
      tester,
    ) async {
      final controller = _controller();
      await tester.pumpWidget(
        _app(
          _menu(
            controller,
            _items([]),
            anchor: GjaButton(
              icon: GjaIcons.overflow,
              tooltip: 'Mais ações',
              onPress: controller.toggle,
              type: GjaButtonType.transparent,
            ),
          ),
        ),
      );
      await _open(tester, controller);
      final panel = tester.getRect(_panel());
      expect(panel.width, closeTo(_light.spacing.xxxl * 6, 0.01));
      expect(
        panel.left,
        closeTo(tester.getRect(find.byType(GjaButton)).left, 0.01),
      );
    });
  });

  testWidgets('[Aparência] Itens e seções — Itens do menu', (tester) async {
    for (final base in [GjaThemeData.light(), GjaThemeData.dark()]) {
      for (final density in GjaDensity.values) {
        final theme = base.withDensity(density);
        final controller = _controller();
        await tester.pumpWidget(
          _app(
            theme: theme,
            KeyedSubtree(
              key: ValueKey((theme.brightness, density)),
              child: _menu(controller, _items([])),
            ),
          ),
        );
        await _open(tester, controller);
        final normal = GjaControlColors.of(
          GjaControlFamily.list,
          theme.colors,
        ).resolve({});
        expect(_background(tester, 'Copiar'), normal.background);
        expect(
          tester.widget<Text>(find.text('Copiar')).style!.color,
          normal.text,
        );
        final box = find
            .descendant(of: _item('Copiar'), matching: find.byType(ColoredBox))
            .first;
        expect(
          tester.getSize(box).height,
          closeTo(theme.density.controlHeight, 0.01),
        );
        expect(find.byType(GjaSeparator), findsOneWidget);
        expect(
          tester.getSize(find.byType(GjaSeparator)).height,
          const BorderSide().width,
        );
      }
    }
  });

  group('[Estados] Hover, ativo e desabilitado', () {
    testWidgets(
      '[Estados] Hover, ativo e desabilitado — Item do menu em hover',
      (tester) async {
        final controller = _controller();
        await tester.pumpWidget(_app(_menu(controller, _items([]))));
        await _open(tester, controller);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(_item('Copiar')));
        await tester.pump();
        expect(_background(tester, 'Copiar'), _light.colors.hoverBackground);
      },
    );

    testWidgets(
      '[Estados] Hover, ativo e desabilitado — Menu sem item selecionado',
      (tester) async {
        final controller = _controller();
        await tester.pumpWidget(_app(_menu(controller, _items([]))));
        void expectNoneSelected() {
          for (final label in ['Editar', 'Copiar', 'Exportar', 'Excluir']) {
            expect(
              tester.widget<GjaInteractable>(_item(label)).selected,
              isFalse,
              reason: label,
            );
          }
        }

        await _open(tester, controller);
        expectNoneSelected();
        await tester.tap(find.text('Editar'));
        await tester.pumpAndSettle();
        await _open(tester, controller);
        expectNoneSelected();
      },
    );
  });

  group('[Acessibilidade] Teclado', () {
    testWidgets('[Acessibilidade] Teclado — Menu pelo teclado', (tester) async {
      final controller = _controller();
      final anchor = FocusNode();
      addTearDown(anchor.dispose);
      final log = <String>[];
      final items = _items(log);
      await tester.pumpWidget(
        _app(
          _menu(
            controller,
            [items[0], items[2], items[3]],
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
      expect(_focused(tester, 'Editar'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_focused(tester, 'Excluir'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(log, ['Excluir']);
      expect(controller.isOpen, isFalse);
      expect(anchor.hasPrimaryFocus, isTrue);
    });

    testWidgets('[Acessibilidade] Teclado — Primeira letra no menu', (
      tester,
    ) async {
      final controller = _controller();
      await tester.pumpWidget(_app(_menu(controller, _items([]))));
      await _open(tester, controller);
      expect(_focused(tester, 'Editar'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.pump();
      expect(_focused(tester, 'Copiar'), isTrue);
    });
  });

  testWidgets('[Acessibilidade] Semântica — Semântica do menu', (tester) async {
    final handle = tester.ensureSemantics();
    final controller = _controller();
    await tester.pumpWidget(_app(_menu(controller, _items([]))));
    await _open(tester, controller);
    final routes = [
      for (final element in find.bySemanticsLabel('Ações').evaluate())
        tester.getSemantics(
          find.byElementPredicate((candidate) => candidate == element),
        ),
    ].where((node) => node.hasFlag(SemanticsFlag.namesRoute)).toSet();
    expect(routes, hasLength(1));
    final edit = tester.getSemantics(_item('Editar'));
    expect(_ancestorRoles(edit), contains(SemanticsRole.menu));
    expect(edit.getSemanticsData().role, SemanticsRole.menuItem);
    expect(
      edit,
      containsSemantics(
        label: 'Editar, Ctrl+E',
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    final export = tester.getSemantics(_item('Exportar'));
    expect(export.getSemanticsData().role, SemanticsRole.menuItem);
    expect(
      export,
      containsSemantics(
        label: 'Exportar',
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  group('[Responsividade] Direção e escala', () {
    testWidgets('[Responsividade] Direção e escala — Menu em RTL', (
      tester,
    ) async {
      final controller = _controller();
      await tester.pumpWidget(
        _app(direction: TextDirection.rtl, _menu(controller, _items([]))),
      );
      await _open(tester, controller);
      final edit = tester.getRect(_item('Editar'));
      expect(
        tester.getRect(find.byIcon(GjaIcons.edit)).right,
        closeTo(edit.right - _light.spacing.m, 0.01),
      );
      expect(
        tester.getRect(find.text('Ctrl+E')).left,
        closeTo(edit.left + _light.spacing.m, 0.01),
      );
    });

    testWidgets(
      '[Responsividade] Direção e escala — Menu com escala de texto 2,0',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(400, 400);
        addTearDown(tester.view.reset);
        final controller = _controller();
        await tester.pumpWidget(
          _app(
            textScale: 2,
            _menu(controller, [
              GjaMenuItem(text: 'Editar', onPress: () {}),
              for (var i = 2; i <= 10; i++)
                GjaMenuItem(
                  text: 'Ação $i',
                  startsSection: i == 6,
                  onPress: () {},
                ),
            ]),
          ),
        );
        await _open(tester, controller);
        expect(tester.takeException(), isNull);
        await tester.drag(find.text('Ação 2'), const Offset(0, -3000));
        await tester.pumpAndSettle();
        final last = tester.getRect(find.text('Ação 10'));
        expect(last.top, greaterThanOrEqualTo(0));
        expect(last.bottom, lessThanOrEqualTo(400));
        expect(tester.takeException(), isNull);
      },
    );
  });

  testWidgets('[Integração] Dependências — Menu sem Material', (tester) async {
    final controller = _controller();
    final log = <String>[];
    await tester.pumpWidget(
      _app(
        _menu(
          controller,
          _items(log),
          anchor: GjaButton(text: 'Ações', onPress: controller.toggle),
        ),
      ),
    );
    await tester.tap(find.text('Ações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copiar'));
    await tester.pumpAndSettle();
    expect(log, ['Copiar']);
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade do menu', () {
      final names = scenarioNames('gja/widgets/gja-menu', 'add-gja-menu');
      expect(names, hasLength(21));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens do menu', (tester) async {
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
              child: _menu(
                controller,
                _items([]),
                anchor: GjaButton(text: 'Ações', onPress: () {}),
              ),
            ),
          ),
        );
        await _open(tester, controller);
        await expectLater(
          find.byKey(const Key('golden')),
          matchesGoldenFile('goldens/gja_menu_$name.png'),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Menu sem valor literal', () {
    final source = File(
      'lib/src/acoes_navegacao/menu/gja_menu.dart',
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

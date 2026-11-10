import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

/// Lê o tema ativo e guarda cada leitura.
class _Reader extends StatelessWidget {
  const _Reader(this.reads);

  final List<GjaThemeData> reads;

  @override
  Widget build(BuildContext context) {
    reads.add(GjaTheme.of(context));
    return const SizedBox(width: 10, height: 10);
  }
}

Widget _ltr(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

/// App mínimo com os atalhos de teclado do `WidgetsApp` (Tab, Esc…).
Widget _app(Widget child) =>
    WidgetsApp(color: const Color(0xFF000000), builder: (context, _) => child);

Widget _focusable(FocusNode node) =>
    Focus(focusNode: node, child: const SizedBox(width: 20, height: 20));

/// Ordem em que [nodes] recebem o foco com Tab, a partir do primeiro.
Future<List<int>> _tabOrder(WidgetTester tester, List<FocusNode> nodes) async {
  nodes.first.requestFocus();
  await tester.pump();
  final order = <int>[nodes.indexWhere((n) => n.hasPrimaryFocus)];
  for (var i = 1; i < nodes.length; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    order.add(nodes.indexWhere((n) => n.hasPrimaryFocus));
  }
  return order;
}

/// Raiz do repositório, a partir do diretório do pacote.
Directory get _repo => Directory.current.parent.parent;

void main() {
  final light = GjaThemeData.light();
  final dark = GjaThemeData.dark();

  testWidgets('[API] Propriedades — Uso mínimo', (tester) async {
    final reads = <GjaThemeData>[];
    await tester.pumpWidget(GjaTheme(data: dark, child: _Reader(reads)));
    expect(reads.last, dark);
  });

  testWidgets('[API] Callbacks e controlador — Troca por reconstrução', (
    tester,
  ) async {
    final reads = <GjaThemeData>[];
    await tester.pumpWidget(GjaTheme(data: light, child: _Reader(reads)));
    await tester.pumpWidget(GjaTheme(data: dark, child: _Reader(reads)));
    await tester.pumpAndSettle();
    expect(reads.last, dark);
  });

  group('[Comportamento] Troca animada de tema', () {
    testWidgets('[Comportamento] Troca animada de tema — Meio da transição', (
      tester,
    ) async {
      final reads = <GjaThemeData>[];
      const duration = Duration(milliseconds: 200);
      await tester.pumpWidget(
        GjaTheme(data: light, duration: duration, child: _Reader(reads)),
      );
      await tester.pumpWidget(
        GjaTheme(data: dark, duration: duration, child: _Reader(reads)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final mid = reads.last.colors.base;
      expect(mid, isNot(light.colors.base));
      expect(mid, isNot(dark.colors.base));
      // A cor intermediária fica entre as duas em cada canal.
      for (final (m, a, b) in [
        (mid.r, light.colors.base.r, dark.colors.base.r),
        (mid.g, light.colors.base.g, dark.colors.base.g),
        (mid.b, light.colors.base.b, dark.colors.base.b),
      ]) {
        expect(m, inInclusiveRange(a < b ? a : b, a < b ? b : a));
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(reads.last.colors.base, dark.colors.base);
    });

    testWidgets('[Comportamento] Troca animada de tema — Movimento reduzido', (
      tester,
    ) async {
      final reads = <GjaThemeData>[];
      Widget app(GjaThemeData data) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: GjaTheme(data: data, child: _Reader(reads)),
      );
      await tester.pumpWidget(app(light));
      await tester.pumpWidget(app(dark));
      await tester.pump();
      expect(reads.last.colors, dark.colors);
    });

    testWidgets('troca imediata com o modo de animação none do tema', (
      tester,
    ) async {
      final reads = <GjaThemeData>[];
      Widget app(GjaThemeData data) => MediaQuery(
        data: const MediaQueryData(),
        child: GjaTheme(
          data: data.copyWith(animationMode: GjaAnimationMode.none),
          child: _Reader(reads),
        ),
      );
      await tester.pumpWidget(app(light));
      await tester.pumpWidget(app(dark));
      await tester.pump();
      expect(reads.last.colors, dark.colors);
    });
  });

  testWidgets('[Comportamento] Densidade por subárvore — Subárvore compacta', (
    tester,
  ) async {
    final inside = <GjaThemeData>[];
    final outside = <GjaThemeData>[];
    await tester.pumpWidget(
      GjaTheme(
        data: light,
        child: _ltr(
          Row(
            children: [
              _Reader(outside),
              GjaTheme.density(
                density: GjaDensity.compact,
                child: _Reader(inside),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(inside.last.density.density, GjaDensity.compact);
    expect(inside.last.colors, light.colors);
    expect(inside.last.typography, light.typography);
    expect(outside.last.density.density, GjaDensity.cozy);
  });

  testWidgets('[Aparência] Texto e ícone padrão — Troca de tema', (
    tester,
  ) async {
    Widget app(GjaThemeData data) => GjaTheme(
      data: data,
      child: _ltr(
        const Column(
          children: [
            Text('texto'),
            Icon(IconData(0x41), key: Key('icon')),
          ],
        ),
      ),
    );
    await tester.pumpWidget(app(light));
    expect(
      tester
          .renderObject<RenderParagraph>(find.text('texto'))
          .text
          .style!
          .color,
      light.colors.text,
    );
    await tester.pumpWidget(app(dark));
    await tester.pumpAndSettle();
    final style = DefaultTextStyle.of(tester.element(find.text('texto'))).style;
    expect(style.color, dark.colors.text);
    expect(style.fontSize, dark.typography.base.fontSize);
    final icon = IconTheme.of(tester.element(find.byKey(const Key('icon'))));
    expect(icon.color, dark.colors.text);
    expect(icon.size, dark.icons.control);
  });

  testWidgets('[Estados] Sem estados visuais — Não recebe foco', (
    tester,
  ) async {
    final nodes = [FocusNode(), FocusNode()];
    addTearDown(() {
      for (final n in nodes) {
        n.dispose();
      }
    });
    await tester.pumpWidget(
      _app(
        GjaTheme(
          data: light,
          child: Column(children: [for (final n in nodes) _focusable(n)]),
        ),
      ),
    );
    expect(await _tabOrder(tester, nodes), [0, 1]);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    // O foco não para no próprio GjaTheme: volta ao primeiro elemento.
    expect(nodes.first.hasPrimaryFocus, isTrue);
  });

  testWidgets('[Acessibilidade] Teclado e foco — Ordem de foco preservada', (
    tester,
  ) async {
    Future<List<int>> order({required bool themed}) async {
      final nodes = [FocusNode(), FocusNode(), FocusNode()];
      addTearDown(() {
        for (final n in nodes) {
          n.dispose();
        }
      });
      final second = _focusable(nodes[1]);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              _focusable(nodes[0]),
              if (themed) GjaTheme(data: light, child: second) else second,
              _focusable(nodes[2]),
            ],
          ),
        ),
      );
      return _tabOrder(tester, nodes);
    }

    final plain = await order(themed: false);
    final themed = await order(themed: true);
    expect(themed, plain);
    expect(plain, [0, 1, 2]);
  });

  testWidgets(
    '[Acessibilidade] Semântica, escala e movimento — Semântica inalterada',
    (tester) async {
      final handle = tester.ensureSemantics();
      Widget content() => _ltr(
        Semantics(
          button: true,
          label: 'Enviar',
          child: const SizedBox(width: 40, height: 40),
        ),
      );
      await tester.pumpWidget(content());
      final plain = tester
          .getSemantics(find.bySemanticsLabel('Enviar'))
          .getSemanticsData();
      await tester.pumpWidget(GjaTheme(data: light, child: content()));
      final themed = tester
          .getSemantics(find.bySemanticsLabel('Enviar'))
          .getSemanticsData();
      expect(themed, plain);
      handle.dispose();
    },
  );

  testWidgets('[Responsividade] Densidade e plataformas — Densidade compacta', (
    tester,
  ) async {
    await tester.pumpWidget(
      GjaTheme(
        data: light,
        child: _ltr(
          Align(
            alignment: Alignment.topLeft,
            child: GjaTheme.density(
              density: GjaDensity.compact,
              child: GjaInteractable(
                key: const Key('target'),
                onPressed: () {},
                builder: (context, states) =>
                    const SizedBox(width: 8, height: 8),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final compact = light.withDensity(GjaDensity.compact);
    expect(
      tester.getSize(find.byKey(const Key('target'))),
      Size.square(compact.density.minTargetSize),
    );
  });

  testWidgets('[Integração] Dependências — Funciona sem Material', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        builder: (context, _) => GjaTheme(
          data: light,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pedido'),
              GjaInteractable(
                onPressed: () => pressed++,
                semanticLabel: 'Enviar',
                builder: (context, states) => const Text('Enviar'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Enviar'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(pressed, 1);
  });

  testWidgets('[Restrições] Fora do escopo — Sem estado global', (
    tester,
  ) async {
    final first = <GjaThemeData>[];
    final second = <GjaThemeData>[];
    await tester.pumpWidget(
      _ltr(
        Row(
          children: [
            GjaTheme(data: light, child: _Reader(first)),
            GjaTheme(data: dark, child: _Reader(second)),
          ],
        ),
      ),
    );
    expect(first.last, light);
    expect(second.last, dark);
  });

  test('[Testes] Cobertura exigida — Rastreabilidade', () {
    const id = 'gja/widgets/gja-theme';
    final spec = [
      File('${_repo.path}/openspec/specs/$id/spec.md'),
      File('${_repo.path}/openspec/changes/add-gja-theme/specs/$id/spec.md'),
    ].firstWhere((f) => f.existsSync());
    final names = <String>[];
    String? requirement;
    for (final line in spec.readAsLinesSync()) {
      final req = RegExp(r'^### Requirement: (.+)$').firstMatch(line);
      if (req != null) requirement = req.group(1)!.trim();
      final scen = RegExp(r'^#### Scenario: (.+)$').firstMatch(line);
      if (scen != null) names.add('$requirement — ${scen.group(1)!.trim()}');
    }
    final suites = [
      Directory('${_repo.path}/packages/gja_widgets/test'),
      Directory('${_repo.path}/apps/gja_gallery/test'),
    ];
    final tests = [
      for (final dir in suites)
        for (final f in dir.listSync(recursive: true).whereType<File>())
          if (f.path.endsWith('_test.dart')) f.readAsStringSync(),
    ].join('\n');
    final missing = [
      for (final name in names)
        if (!tests.contains("'$name'")) name,
    ];
    expect(names, hasLength(14));
    expect(missing, isEmpty);
  });
}

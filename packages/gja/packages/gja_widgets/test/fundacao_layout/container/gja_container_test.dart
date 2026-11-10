import 'dart:io';
import 'package:flutter/foundation.dart' show Diagnosticable;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/fonts.dart';
import '../../support/golden.dart';

const _c = Key('container');
const _box = SizedBox(width: 20, height: 20);

/// Monta [child] sob [theme], alinhado ao topo, em LTR.
Widget _themed(Widget child, {GjaThemeData? theme}) => GjaTheme(
  data: theme ?? GjaThemeData.light(),
  duration: Duration.zero,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Align(alignment: Alignment.topLeft, child: child),
  ),
);

/// Decoração pintada pelo [GjaContainer] de chave [_c].
BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byKey(_c),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

Finder _clip() =>
    find.descendant(of: find.byKey(_c), matching: find.byType(ClipRRect));

Set<String> _diagnosticNames(Diagnosticable tokens) =>
    tokens.toDiagnosticsNode().getProperties().map((p) => p.name!).toSet();

Directory get _repo => Directory.current.parent.parent;

/// Amostra dos goldens: superfícies, borda, raios, sombras e um cartão.
Widget _sample() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        for (final s in [
          GjaSurface.background,
          GjaSurface.base,
          GjaSurface.header,
          GjaSurface.shell,
        ])
          GjaSpacing.padding(
            end: GjaSpace.s,
            child: GjaContainer(
              surface: s,
              border: true,
              padding: GjaSpace.m,
              // Tamanho `small`, como nos goldens de referência.
              child: Builder(
                builder: (context) {
                  final theme = GjaThemeData.of(context);
                  return Text(
                    's',
                    style: theme.typography.small.copyWith(
                      color: theme.colors.text,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    ),
    GjaSpacing.vertical(GjaSpace.l),
    Row(
      children: [
        for (final r in [
          GjaRadius.button,
          GjaRadius.tile,
          GjaRadius.full,
        ])
          GjaSpacing.padding(
            end: GjaSpace.s,
            child: GjaContainer(
              surface: GjaSurface.base,
              border: true,
              radius: r,
              padding: GjaSpace.l,
            ),
          ),
      ],
    ),
    GjaSpacing.vertical(GjaSpace.l),
    Row(
      children: [
        for (final e in [
          GjaShadow.card,
          GjaShadow.popover,
          GjaShadow.dialog,
          GjaShadow.dragged,
          GjaShadow.header,
        ])
          GjaSpacing.padding(
            end: GjaSpace.l,
            child: GjaContainer(
              surface: GjaSurface.base,
              radius: GjaRadius.button,
              shadow: e,
              padding: GjaSpace.l,
            ),
          ),
      ],
    ),
    GjaSpacing.vertical(GjaSpace.xl),
    GjaContainer(
      surface: GjaSurface.base,
      border: true,
      radius: GjaRadius.tile,
      shadow: GjaShadow.card,
      padding: GjaSpace.l,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GjaTitle('Pedido 4711', titleStyle: GjaTitleLevel.h3),
          GjaSpacing.vertical(GjaSpace.xs),
          GjaLabel('Aguardando aprovação'),
        ],
      ),
    ),
  ],
);

void main() {
  setUpAll(loadGjaFonts);

  testWidgets('[API] Propriedades — Uso mínimo', (tester) async {
    await tester.pumpWidget(
      const GjaApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: GjaContainer(key: _c, child: _box),
        ),
      ),
    );
    final d = _decoration(tester);
    expect(d.color, isNull);
    expect(d.border, isNull);
    expect(d.boxShadow, isEmpty);
    expect(tester.getSize(find.byKey(_c)), const Size(20, 20));
    expect(_clip(), findsNothing);
  });

  test('[API] Valores dos papéis — Papéis do fundamento', () {
    final radius = _diagnosticNames(const GjaRadiusTokens.fallback());
    for (final r in GjaRadius.values) {
      expect(radius, contains(r.name), reason: r.name);
    }
    final shadow = _diagnosticNames(const GjaShadowTokens.fallback());
    for (final e in GjaShadow.values) {
      expect(shadow, contains(e.name), reason: e.name);
    }
    expect(GjaSurface.values.map((s) => s.name), [
      'none',
      'background',
      'base',
      'header',
      'shell',
    ]);
  });

  testWidgets('[API] Callbacks e controlador — Sem ação', (tester) async {
    await tester.pumpWidget(
      _themed(
        const GjaContainer(
          key: _c,
          surface: GjaSurface.base,
          padding: GjaSpace.xl,
          child: _box,
        ),
      ),
    );
    await tester.tapAt(tester.getTopLeft(find.byKey(_c)) + const Offset(2, 2));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byKey(_c),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
  });

  group('[Comportamento] Recorte nos cantos', () {
    testWidgets('[Comportamento] Recorte nos cantos — Filho recortado', (
      tester,
    ) async {
      final theme = GjaThemeData.light();
      await tester.pumpWidget(
        _themed(
          const GjaContainer(
            key: _c,
            radius: GjaRadius.tile,
            child: ColoredBox(
              color: Color(0xFF000000),
              child: SizedBox(width: 80, height: 40),
            ),
          ),
        ),
      );
      final clip = tester.widget<ClipRRect>(_clip());
      expect(clip.borderRadius, BorderRadius.circular(theme.radius.tile));
    });

    testWidgets('[Comportamento] Recorte nos cantos — Sem raio, sem recorte', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themed(const GjaContainer(key: _c, child: _box)),
      );
      expect(_clip(), findsNothing);
      expect(_decoration(tester).borderRadius, isNull);
    });
  });

  group('[Aparência] Tokens de componente', () {
    testWidgets('[Aparência] Tokens de componente — Troca de tema', (
      tester,
    ) async {
      Widget app(GjaThemeData theme) => _themed(
        const GjaContainer(
          key: _c,
          surface: GjaSurface.base,
          border: true,
          shadow: GjaShadow.card,
          child: _box,
        ),
        theme: theme,
      );
      for (final theme in [GjaThemeData.light(), GjaThemeData.dark()]) {
        await tester.pumpWidget(app(theme));
        await tester.pumpAndSettle();
        final d = _decoration(tester);
        final reason = theme.brightness.name;
        expect(d.color, theme.colors.base, reason: reason);
        expect(
          (d.border! as Border).top.color,
          theme.colors.separator,
          reason: reason,
        );
        expect(
          d.boxShadow,
          theme.shadows.boxShadows(theme.shadows.card, theme.colors.shadow),
          reason: reason,
        );
      }
    });

    testWidgets('[Aparência] Tokens de componente — Superfícies', (
      tester,
    ) async {
      final c = GjaThemeData.light().colors;
      final expected = {
        GjaSurface.none: null,
        GjaSurface.background: c.background,
        GjaSurface.base: c.base,
        GjaSurface.header: c.headerBackground,
        GjaSurface.shell: c.shell,
      };
      for (final MapEntry(key: surface, value: color) in expected.entries) {
        await tester.pumpWidget(
          _themed(GjaContainer(key: _c, surface: surface, child: _box)),
        );
        expect(_decoration(tester).color, color, reason: surface.name);
      }
      expect(expected.keys, GjaSurface.values);
    });

    testWidgets('[Aparência] Tokens de componente — Raio e sombra', (
      tester,
    ) async {
      final theme = GjaThemeData.light();
      final radius = <GjaRadius, double>{
        GjaRadius.xs: theme.radius.xs,
        GjaRadius.s: theme.radius.s,
        GjaRadius.m: theme.radius.m,
        GjaRadius.l: theme.radius.l,
        GjaRadius.xl: theme.radius.xl,
        GjaRadius.full: theme.radius.full,
        GjaRadius.button: theme.radius.button,
        GjaRadius.field: theme.radius.field,
        GjaRadius.popover: theme.radius.popover,
        GjaRadius.element: theme.radius.element,
        GjaRadius.tile: theme.radius.tile,
      };
      for (final MapEntry(key: r, value: v) in radius.entries) {
        await tester.pumpWidget(
          _themed(GjaContainer(key: _c, radius: r, child: _box)),
        );
        expect(
          _decoration(tester).borderRadius,
          BorderRadius.circular(v),
          reason: r.name,
        );
      }
      final e = theme.shadows;
      final shadows = {
        GjaShadow.none: e.none,
        GjaShadow.card: e.card,
        GjaShadow.popover: e.popover,
        GjaShadow.dialog: e.dialog,
        GjaShadow.dragged: e.dragged,
        GjaShadow.header: e.header,
      };
      for (final MapEntry(key: role, value: layers) in shadows.entries) {
        await tester.pumpWidget(
          _themed(GjaContainer(key: _c, shadow: role, child: _box)),
        );
        expect(
          _decoration(tester).boxShadow,
          e.boxShadows(layers, theme.colors.shadow),
          reason: role.name,
        );
      }
    });
  });

  testWidgets('[Estados] Sem estados de interação — Não recebe foco', (
    tester,
  ) async {
    final first = FocusNode();
    final second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(
      GjaApp(
        home: Column(
          children: [
            Focus(focusNode: first, child: _box),
            const GjaContainer(surface: GjaSurface.base, child: _box),
            Focus(focusNode: second, child: _box),
          ],
        ),
      ),
    );
    first.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(second.hasPrimaryFocus, isTrue);
  });

  testWidgets('[Acessibilidade] Teclado e foco — Ordem preservada', (
    tester,
  ) async {
    final first = FocusNode();
    final second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(
      GjaApp(
        home: GjaContainer(
          surface: GjaSurface.base,
          radius: GjaRadius.tile,
          padding: GjaSpace.m,
          child: Column(
            children: [
              Focus(focusNode: first, child: _box),
              Focus(focusNode: second, child: _box),
            ],
          ),
        ),
      ),
    );
    first.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(second.hasPrimaryFocus, isTrue);
  });

  testWidgets('[Acessibilidade] Semântica e contraste — Semântica inalterada', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    SemanticsData data() =>
        tester.getSemantics(find.text('Pedido')).getSemanticsData();
    await tester.pumpWidget(_themed(const GjaText('Pedido')));
    final plain = data();
    await tester.pumpWidget(
      _themed(
        const GjaContainer(
          surface: GjaSurface.base,
          border: true,
          radius: GjaRadius.tile,
          shadow: GjaShadow.card,
          padding: GjaSpace.l,
          child: GjaText('Pedido'),
        ),
      ),
    );
    final wrapped = data();
    expect(wrapped.label, plain.label);
    expect(wrapped.flags, plain.flags);
    handle.dispose();
  });

  // "Texto sobre as superfícies" fica em gja_container_contrast_test.dart,
  // sem a fonte real: a diretriz de contraste mede pixels.

  testWidgets('[Responsividade] Densidade — Densidade compacta', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themed(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GjaContainer(
              key: Key('cozy'),
              radius: GjaRadius.tile,
              shadow: GjaShadow.card,
              padding: GjaSpace.l,
              child: _box,
            ),
            GjaTheme.density(
              density: GjaDensity.compact,
              child: GjaContainer(
                key: Key('compact'),
                radius: GjaRadius.tile,
                shadow: GjaShadow.card,
                padding: GjaSpace.l,
                child: _box,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final cozy = GjaThemeData.light().spacing.l;
    final compact = GjaThemeData.light(
      density: GjaDensity.compact,
    ).spacing.l;
    expect(
      tester.getSize(find.byKey(const Key('cozy'))),
      Size.square(20 + cozy * 2),
    );
    expect(
      tester.getSize(find.byKey(const Key('compact'))),
      Size.square(20 + compact * 2),
    );
    // Como no Fiori, a densidade não muda o espaçamento.
    expect(compact, cozy);
    BoxDecoration deco(String key) =>
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byKey(Key(key)),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(deco('compact').borderRadius, deco('cozy').borderRadius);
    expect(deco('compact').boxShadow, deco('cozy').boxShadow);
  });

  testWidgets('[Integração] Dependências — Funciona sem Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      GjaApp(
        home: Column(
          children: [
            for (final s in GjaSurface.values)
              GjaContainer(
                surface: s,
                border: true,
                radius: GjaRadius.button,
                shadow: GjaShadow.card,
                padding: GjaSpace.s,
                child: GjaText(s.name),
              ),
          ],
        ),
      ),
    );
    expect(find.byType(GjaContainer), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    testWidgets('[Testes] Cobertura exigida — Goldens das superfícies', (
      tester,
    ) async {
      for (final (name, theme) in goldenThemes) {
        await expectGolden(
          tester,
          name: 'gja_container_$name',
          theme: theme,
          surface: GjaSurface.background,
          child: _sample(),
          size: const Size(520, 420),
        );
      }
    }, tags: ['golden']);

    test('[Testes] Cobertura exigida — Rastreabilidade', () {
      const id = 'gja/widgets/gja-container';
      final spec = [
        File('${_repo.path}/openspec/specs/$id/spec.md'),
        File(
          '${_repo.path}/openspec/changes/add-gja-container/specs/$id/spec.md',
        ),
      ].firstWhere((f) => f.existsSync());
      final names = <String>[];
      String? requirement;
      for (final line in spec.readAsLinesSync()) {
        final req = RegExp(r'^### Requirement: (.+)$').firstMatch(line);
        if (req != null) requirement = req.group(1)!.trim();
        final scen = RegExp(r'^#### Scenario: (.+)$').firstMatch(line);
        if (scen != null) names.add('$requirement — ${scen.group(1)!.trim()}');
      }
      final tests = [
        for (final dir in [
          Directory('${_repo.path}/packages/gja_widgets/test'),
          Directory('${_repo.path}/apps/gja_gallery/test'),
        ])
          for (final f in dir.listSync(recursive: true).whereType<File>())
            if (f.path.endsWith('_test.dart')) f.readAsStringSync(),
      ].join('\n');
      expect(names, hasLength(18));
      expect([
        for (final name in names)
          if (!tests.contains("'$name'")) name,
      ], isEmpty);
    });
  });

  test('[Restrições] Fora do escopo — Sem valores literais', () {
    final source = File(
      'lib/src/fundacao_layout/container/gja_container.dart',
    ).readAsStringSync();
    final ctor = RegExp(
      r'const GjaContainer\((.*?)\}\);',
      dotAll: true,
    ).firstMatch(source)!.group(1)!;
    final fields = RegExp(
      r'^  final (\w+)\?? ',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!).toSet();
    for (final type in [
      'Color',
      'double',
      'BorderRadius',
      'BoxShadow',
      'EdgeInsets',
      'BoxDecoration',
    ]) {
      expect(ctor, isNot(contains(type)), reason: type);
      expect(fields, isNot(contains(type)), reason: type);
    }
  });
}

import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/fonts.dart';
import '../../support/golden.dart';

/// Monta [child] sob [theme], na direção [direction].
Widget _themed(
  Widget child, {
  GjaThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) => GjaTheme(
  data: theme ?? GjaThemeData.light(),
  duration: Duration.zero,
  child: Directionality(
    textDirection: direction,
    child: Align(alignment: Alignment.topLeft, child: child),
  ),
);

Icon _icon(WidgetTester tester, [Finder? within]) => tester.widget<Icon>(
  within == null
      ? find.byType(Icon)
      : find.descendant(of: within, matching: find.byType(Icon)),
);

/// Se o glifo de [finder] é desenhado espelhado no eixo horizontal.
bool _mirrored(WidgetTester tester, Finder finder) {
  final transforms = tester.widgetList<Transform>(
    find.descendant(of: finder, matching: find.byType(Transform)),
  );
  return transforms.any((t) => t.transform.storage[0] == -1);
}

Directory get _repo => Directory.current.parent.parent;

Color _toneColor(GjaColorTokens c, GjaIconTone tone) => switch (tone) {
  GjaIconTone.standard => c.text,
  GjaIconTone.muted => c.label,
  GjaIconTone.brand => c.brand,
  GjaIconTone.success => c.stateColors(GjaValueState.success).foreground,
  GjaIconTone.warning => c.stateColors(GjaValueState.warning).foreground,
  GjaIconTone.error => c.stateColors(GjaValueState.error).foreground,
  GjaIconTone.information =>
    c.stateColors(GjaValueState.information).foreground,
};

double _tokenSize(GjaIconTokens t, GjaIconSize size) =>
    t.values[size.name]!;

/// Amostra dos goldens: tamanhos, tons e um direcional em LTR e RTL.
Widget _sample() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        for (final s in GjaIconSize.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GjaIcon(GjaIcons.search, size: s),
          ),
      ],
    ),
    const SizedBox(height: 16),
    Row(
      children: [
        for (final t in GjaIconTone.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GjaIcon(
              GjaIcons.information,
              size: GjaIconSize.large,
              tone: t,
            ),
          ),
      ],
    ),
    const SizedBox(height: 16),
    const Row(
      children: [
        GjaIcon(GjaIcons.slimArrowRight, size: GjaIconSize.large),
        SizedBox(width: 16),
        Directionality(
          textDirection: TextDirection.rtl,
          child: GjaIcon(GjaIcons.slimArrowRight, size: GjaIconSize.large),
        ),
      ],
    ),
  ],
);

void main() {
  setUpAll(loadGjaFonts);

  testWidgets('[API] Propriedades — Uso mínimo', (tester) async {
    final handle = tester.ensureSemantics();
    final theme = GjaThemeData.light();
    await tester.pumpWidget(
      GjaApp(
        themeMode: GjaThemeMode.light,
        density: GjaDensity.cozy,
        home: const Center(
          child: GjaIcon(GjaIcons.search, key: Key('icon')),
        ),
      ),
    );
    final icon = _icon(tester);
    expect(icon.size, theme.icons.control);
    expect(icon.color, theme.colors.text);
    expect(
      tester.getSize(find.byKey(const Key('icon'))),
      Size.square(theme.icons.control),
    );
    expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
    handle.dispose();
  });

  testWidgets('[API] Callbacks e controlador — Sem ação', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _themed(const GjaIcon(GjaIcons.information, semanticLabel: 'Detalhes')),
    );
    await tester.tap(find.byType(GjaIcon));
    await tester.pump();
    final data = tester
        .getSemantics(find.bySemanticsLabel('Detalhes'))
        .getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isFalse);
    handle.dispose();
  });

  testWidgets('[Comportamento] Espelhamento em RTL — Direcional em RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themed(
        const Row(
          children: [
            GjaIcon(GjaIcons.slimArrowRight, key: Key('chevron')),
            GjaIcon(GjaIcons.accept, key: Key('check')),
          ],
        ),
        direction: TextDirection.rtl,
      ),
    );
    expect(_mirrored(tester, find.byKey(const Key('chevron'))), isTrue);
    expect(_mirrored(tester, find.byKey(const Key('check'))), isFalse);

    await tester.pumpWidget(
      _themed(const GjaIcon(GjaIcons.slimArrowRight, key: Key('chevron'))),
    );
    expect(_mirrored(tester, find.byKey(const Key('chevron'))), isFalse);
  });

  group('[Aparência] Tokens de componente', () {
    testWidgets('[Aparência] Tokens de componente — Troca de tema', (
      tester,
    ) async {
      final light = GjaThemeData.light();
      final dark = GjaThemeData.dark();
      Widget app(GjaThemeData theme) => _themed(
        const GjaIcon(GjaIcons.home, tone: GjaIconTone.brand),
        theme: theme,
      );
      await tester.pumpWidget(app(light));
      expect(_icon(tester).color, light.colors.brand);
      await tester.pumpWidget(app(dark));
      await tester.pumpAndSettle();
      expect(_icon(tester).color, dark.colors.brand);
    });

    testWidgets('[Aparência] Tokens de componente — Tamanhos e tons', (
      tester,
    ) async {
      final theme = GjaThemeData.light();
      for (final size in GjaIconSize.values) {
        for (final tone in GjaIconTone.values) {
          final reason = '${size.name}/${tone.name}';
          await tester.pumpWidget(
            _themed(
              GjaIcon(
                GjaIcons.add,
                key: const Key('i'),
                size: size,
                tone: tone,
              ),
            ),
          );
          final expected = _tokenSize(theme.icons, size);
          expect(
            tester.getSize(find.byKey(const Key('i'))),
            Size.square(expected),
            reason: reason,
          );
          expect(
            _icon(tester).color,
            _toneColor(theme.colors, tone),
            reason: reason,
          );
        }
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
            Focus(
              focusNode: first,
              child: const SizedBox(width: 20, height: 20),
            ),
            const GjaIcon(GjaIcons.information),
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
  });

  testWidgets('[Acessibilidade] Teclado e foco — Teclas ignoradas', (
    tester,
  ) async {
    await tester.pumpWidget(
      const GjaApp(home: Center(child: GjaIcon(GjaIcons.information))),
    );
    for (final key in [
      LogicalKeyboardKey.tab,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pump();
    }
    expect(find.byType(GjaIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('[Acessibilidade] Semântica e contraste', () {
    testWidgets('[Acessibilidade] Semântica e contraste — Ícone decorativo', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_themed(const GjaIcon(GjaIcons.search)));
      final node = tester.getSemantics(find.byType(GjaIcon));
      // O ícone decorativo não cria nó próprio: o nó encontrado é o da raiz,
      // sem rótulo nem papel de imagem.
      expect(node.label, isEmpty);
      expect(node.getSemanticsData().hasFlag(SemanticsFlag.isImage), isFalse);
      handle.dispose();
    });

    testWidgets(
      '[Acessibilidade] Semântica e contraste — Ícone com significado',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _themed(
            const GjaIcon(
              GjaIcons.warning,
              tone: GjaIconTone.warning,
              semanticLabel: 'Aviso',
            ),
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Aviso')),
          matchesSemantics(label: 'Aviso', isImage: true),
        );
        handle.dispose();
      },
    );

    test('[Acessibilidade] Semântica e contraste — Contraste dos tons', () {
      for (final theme in [GjaThemeData.light(), GjaThemeData.dark()]) {
        final c = theme.colors;
        for (final tone in GjaIconTone.values) {
          for (final (name, ground) in [
            ('base', c.base),
            ('background', c.background),
          ]) {
            expect(
              gjaContrastRatioOver(_toneColor(c, tone), ground),
              greaterThanOrEqualTo(3),
              reason: '${theme.brightness.name}/${tone.name}/$name',
            );
          }
        }
      }
    });
  });

  group('[Responsividade] Escala de texto e densidade', () {
    testWidgets(
      '[Responsividade] Escala de texto e densidade — Escala de texto 2,0',
      (tester) async {
        final theme = GjaThemeData.light();
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: _themed(
              const Row(
                children: [
                  GjaIcon(
                    GjaIcons.information,
                    key: Key('inline'),
                    size: GjaIconSize.inline,
                  ),
                  GjaIcon(GjaIcons.information, key: Key('control')),
                ],
              ),
            ),
          ),
        );
        expect(
          tester.getSize(find.byKey(const Key('inline'))),
          Size.square(theme.icons.inline * 2),
        );
        expect(
          tester.getSize(find.byKey(const Key('control'))),
          Size.square(theme.icons.control),
        );
      },
    );

    testWidgets(
      '[Responsividade] Escala de texto e densidade — Densidade compacta',
      (tester) async {
        await tester.pumpWidget(
          _themed(
            const Row(
              children: [
                GjaIcon(GjaIcons.information, key: Key('cozy')),
                GjaTheme.density(
                  density: GjaDensity.compact,
                  child: GjaIcon(GjaIcons.information, key: Key('compact')),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(const Key('compact'))),
          tester.getSize(find.byKey(const Key('cozy'))),
        );
      },
    );
  });

  testWidgets('[Integração] Dependências — Funciona sem Material', (
    tester,
  ) async {
    final icons = [
      GjaIcons.add,
      GjaIcons.decline,
      GjaIcons.search,
      GjaIcons.accept,
      GjaIcons.slimArrowRight,
      GjaIcons.warning,
      GjaIcons.information,
      GjaIcons.home,
    ];
    await tester.pumpWidget(
      GjaApp(home: Wrap(children: [for (final i in icons) GjaIcon(i)])),
    );
    expect(find.byType(GjaIcon), findsNWidgets(icons.length));
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    testWidgets('[Testes] Cobertura exigida — Goldens dos tamanhos e tons', (
      tester,
    ) async {
      for (final (name, theme) in goldenThemes) {
        await expectGolden(
          tester,
          name: 'gja_icon_$name',
          theme: theme,
          child: _sample(),
          size: const Size(480, 240),
        );
      }
    }, tags: ['golden']);

    test('[Testes] Cobertura exigida — Rastreabilidade', () {
      const id = 'gja/widgets/gja-icon';
      final spec = [
        File('${_repo.path}/openspec/specs/$id/spec.md'),
        File('${_repo.path}/openspec/changes/add-gja-icon/specs/$id/spec.md'),
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
      expect(names, hasLength(17));
      expect([
        for (final name in names)
          if (!tests.contains("'$name'")) name,
      ], isEmpty);
    });
  });

  test('[Restrições] Fora do escopo — Sem tamanho nem cor arbitrários', () {
    final source = File(
      'lib/src/fundacao_layout/icon/gja_icon.dart',
    ).readAsStringSync();
    final fields = RegExp(
      r'^  final (\w+\??) ',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!.replaceAll('?', '')).toSet();
    expect(fields, isNot(contains('double')));
    expect(fields, isNot(contains('Color')));
    final ctor = RegExp(
      r'const GjaIcon\((.*?)\}\);',
      dotAll: true,
    ).firstMatch(source)!.group(1)!;
    expect(ctor, isNot(contains('double')));
    expect(ctor, isNot(contains('Color')));
  });
}

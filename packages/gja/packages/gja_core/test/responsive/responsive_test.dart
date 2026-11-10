import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

void _setView(WidgetTester tester, double width, [double height = 600]) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
}

/// Lê a classe da tela e conta os builds.
class _Probe extends StatelessWidget {
  const _Probe();

  static final builds = <GjaSizeClass>[];

  @override
  Widget build(BuildContext context) {
    builds.add(GjaResponsive.screenSizeClassOf(context));
    return const SizedBox();
  }
}

Widget _ltr(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  setUp(_Probe.builds.clear);

  group('Classe de tamanho da tela', () {
    testWidgets('Classe de tamanho da tela — Largura da janela', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      for (final scoped in [true, false]) {
        _Probe.builds.clear();
        _setView(tester, 800);
        await tester.pumpWidget(
          scoped ? const GjaScreenSizeScope(child: _Probe()) : const _Probe(),
        );
        _setView(tester, 1200);
        await tester.pump();
        expect(_Probe.builds, [
          GjaSizeClass.medium,
          GjaSizeClass.large,
        ], reason: scoped ? 'com escopo' : 'sem escopo');
      }
    });

    testWidgets('Classe de tamanho da tela — Mudança que não troca a classe', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      _setView(tester, 800, 600);
      await tester.pumpWidget(const GjaScreenSizeScope(child: _Probe()));
      _setView(tester, 900, 600);
      await tester.pump();
      _setView(tester, 900, 400);
      await tester.pump();
      expect(_Probe.builds, [GjaSizeClass.medium]);
    });

    testWidgets('Classe de tamanho da tela — Limiares recebidos', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      _setView(tester, 500);
      const custom = GjaBreakpointTokens(
        medium: 480,
        large: 960,
        extraLarge: 1280,
      );
      late GjaSizeClass scoped;
      late GjaSizeClass unscoped;
      await tester.pumpWidget(
        GjaScreenSizeScope(
          breakpoints: custom,
          child: Builder(
            builder: (context) {
              scoped = GjaResponsive.screenSizeClassOf(
                context,
                breakpoints: custom,
              );
              unscoped = GjaResponsive.screenSizeClassOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(scoped, GjaSizeClass.medium);
      // Limiares diferentes dos do escopo: classifica direto pela janela.
      expect(unscoped, GjaSizeClass.small);
    });
  });

  group('Classe de tamanho do contêiner', () {
    testWidgets('Classe de tamanho do contêiner — Contêiner menor que a tela', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      _setView(tester, 1500);
      late GjaSizeClass panel;
      late GjaSizeClass screen;
      await tester.pumpWidget(
        _ltr(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 500,
              child: GjaResponsiveBuilder(
                builder: (context, sizeClass) {
                  panel = sizeClass;
                  screen = GjaResponsive.screenSizeClassOf(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(panel, GjaSizeClass.small);
      expect(screen, GjaSizeClass.extraLarge);
    });

    testWidgets('Classe de tamanho do contêiner — Largura sem limite', (
      tester,
    ) async {
      late GjaSizeClass sizeClass;
      await tester.pumpWidget(
        _ltr(
          ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GjaResponsiveBuilder(
                builder: (context, value) {
                  sizeClass = value;
                  return const SizedBox(width: 10);
                },
              ),
            ],
          ),
        ),
      );
      expect(sizeClass, GjaSizeClass.extraLarge);
    });
  });

  group('Valores por classe de tamanho', () {
    test('Valores por classe de tamanho — Herança da classe menor', () {
      const value = GjaResponsiveValue(small: 12, large: 4);
      expect(GjaSizeClass.values.map(value.resolve), [12, 12, 4, 4]);
    });

    testWidgets(
      'Valores por classe de tamanho — Resolução pela tela e pelo contêiner',
      (tester) async {
        addTearDown(tester.view.reset);
        _setView(tester, 800);
        const value = GjaResponsiveValue(small: 1, medium: 2);
        late int byScreen;
        late int byPanel;
        await tester.pumpWidget(
          GjaScreenSizeScope(
            child: _ltr(
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 500,
                  child: GjaResponsiveBuilder(
                    builder: (context, sizeClass) {
                      byScreen = value.resolve(
                        GjaResponsive.screenSizeClassOf(context),
                      );
                      byPanel = value.resolve(sizeClass);
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        expect(byScreen, 2);
        expect(byPanel, 1);
      },
    );

    test('igualdade por valor', () {
      // Instâncias não canônicas, para testar a igualdade por valor.
      // ignore: prefer_const_constructors
      final a = GjaResponsiveValue(small: 1, large: 3);
      // ignore: prefer_const_constructors
      final b = GjaResponsiveValue(small: 1, large: 3);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const GjaResponsiveValue(small: 1, medium: 3)));
    });
  });

  test('Densidade recomendada — Plataformas', () {
    final expected = {
      TargetPlatform.windows: GjaDensity.compact,
      TargetPlatform.macOS: GjaDensity.compact,
      TargetPlatform.linux: GjaDensity.compact,
      TargetPlatform.android: GjaDensity.cozy,
      TargetPlatform.iOS: GjaDensity.cozy,
      TargetPlatform.fuchsia: GjaDensity.cozy,
    };
    expect(expected.keys, unorderedEquals(TargetPlatform.values));
    for (final MapEntry(key: platform, value: density) in expected.entries) {
      expect(
        GjaResponsive.recommendedDensity(platform),
        density,
        reason: '$platform',
      );
    }
  });
}

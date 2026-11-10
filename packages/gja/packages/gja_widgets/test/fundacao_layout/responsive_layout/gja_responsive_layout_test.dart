import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/traceability.dart';

/// Construtor que exibe o nome da classe.
WidgetBuilder _label(String name) =>
    (_) => Text(name);

/// Ajusta a janela de teste para [width] × [height].
void _view(WidgetTester tester, double width, [double height = 800]) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
}

/// Monta [child] numa área de [width], sob [theme].
Widget _area(double width, Widget child, {GjaThemeData? theme}) => GjaTheme(
  data: theme ?? GjaThemeData.light(),
  duration: Duration.zero,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

GjaResponsiveLayout _smallLarge({
  GjaLayoutBasis basis = GjaLayoutBasis.container,
}) => GjaResponsiveLayout(
  basis: basis,
  small: _label('small'),
  large: _label('large'),
);

GjaResponsiveLayout _smallMedium() =>
    GjaResponsiveLayout(small: _label('small'), medium: _label('medium'));

void main() {
  testWidgets('[API] Propriedades — Layout responsivo mínimo', (tester) async {
    await tester.pumpWidget(
      GjaApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: GjaResponsiveLayout(small: _label('small')),
          ),
        ),
      ),
    );
    expect(find.text('small'), findsOneWidget);
    expect(GjaLayoutBasis.values, [
      GjaLayoutBasis.container,
      GjaLayoutBasis.screen,
    ]);
  });

  testWidgets('[API] Callbacks e controlador — Layout sem ação', (
    tester,
  ) async {
    await tester.pumpWidget(
      _area(
        300,
        GjaResponsiveLayout(
          small: (_) => const SizedBox(height: 40, child: Text('small')),
        ),
      ),
    );
    await tester.tapAt(const Offset(250, 30));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(GjaResponsiveLayout),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
  });

  testWidgets(
    '[Comportamento] Construtor por classe com herança — Herança da classe menor no layout',
    (tester) async {
      _view(tester, 2000);
      final shown = <String>[];
      for (final width in [500.0, 800.0, 1200.0, 1600.0]) {
        await tester.pumpWidget(_area(width, _smallLarge()));
        shown.add(find.text('small').evaluate().isNotEmpty ? 'small' : 'large');
      }
      expect(shown, ['small', 'small', 'large', 'large']);
    },
  );

  testWidgets(
    '[Comportamento] Base da medida — Contêiner estreito numa tela larga',
    (tester) async {
      _view(tester, 1500);
      await tester.pumpWidget(
        GjaApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 500,
              child: Column(
                children: [
                  GjaResponsiveLayout(
                    small: _label('container: small'),
                    extraLarge: _label('container: extraLarge'),
                  ),
                  GjaResponsiveLayout(
                    basis: GjaLayoutBasis.screen,
                    small: _label('screen: small'),
                    extraLarge: _label('screen: extraLarge'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('container: small'), findsOneWidget);
      expect(find.text('screen: extraLarge'), findsOneWidget);
    },
  );

  testWidgets('[Comportamento] Troca de classe — Janela redimensionada', (
    tester,
  ) async {
    var largeBuilds = 0;
    _view(tester, 800);
    await tester.pumpWidget(
      GjaApp(
        home: GjaResponsiveLayout(
          basis: GjaLayoutBasis.screen,
          small: _label('small'),
          large: (_) {
            largeBuilds++;
            return const Text('large');
          },
        ),
      ),
    );
    expect(find.text('small'), findsOneWidget);
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpAndSettle();
    expect(find.text('large'), findsOneWidget);
    tester.view.physicalSize = const Size(1300, 800);
    await tester.pumpAndSettle();
    expect(find.text('large'), findsOneWidget);
    expect(find.text('small'), findsNothing);
    expect(largeBuilds, greaterThanOrEqualTo(1));
  });

  testWidgets('[Aparência] Tokens de componente — Limiares do tema no layout', (
    tester,
  ) async {
    final base = GjaThemeData.light();
    final theme = base.copyWith(
      breakpoints: base.breakpoints.copyWith(medium: 480),
    );
    await tester.pumpWidget(_area(500, _smallMedium(), theme: theme));
    expect(find.text('medium'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GjaResponsiveLayout),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });

  testWidgets('[Estados] Sem estados de interação — Layout não recebe foco', (
    tester,
  ) async {
    final first = FocusNode();
    final second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(
      GjaApp(
        home: GjaResponsiveLayout(
          small: (_) => Column(
            children: [
              Focus(
                focusNode: first,
                child: const SizedBox(width: 20, height: 20),
              ),
              Focus(
                focusNode: second,
                child: const SizedBox(width: 20, height: 20),
              ),
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

  testWidgets(
    '[Acessibilidade] Teclado e foco — Só o conteúdo atual na árvore',
    (tester) async {
      await tester.pumpWidget(_area(500, _smallLarge()));
      expect(find.text('small'), findsOneWidget);
      expect(find.text('large'), findsNothing);
    },
  );

  testWidgets(
    '[Acessibilidade] Semântica e escala — Escala de texto sem efeito na classe',
    (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: _area(500, _smallMedium()),
        ),
      );
      expect(find.text('small'), findsOneWidget);
    },
  );

  testWidgets(
    '[Responsividade] Classes e densidade — Densidade sem efeito na classe',
    (tester) async {
      await tester.pumpWidget(
        _area(
          700,
          Column(
            children: [
              _smallMedium(),
              GjaTheme.density(
                density: GjaDensity.compact,
                child: _smallMedium(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('medium'), findsNWidgets(2));
    },
  );

  testWidgets('[Integração] Dependências — Layout sem Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      GjaApp(
        home: Column(
          children: [
            _smallLarge(),
            _smallLarge(basis: GjaLayoutBasis.screen),
          ],
        ),
      ),
    );
    expect(find.byType(GjaResponsiveLayout), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  test('[Testes] Cobertura exigida — Rastreabilidade do layout responsivo', () {
    final names = scenarioNames(
      'gja/widgets/gja-responsive-layout',
      'add-gja-responsive-layout',
    );
    expect(names, hasLength(14));
    expect(untestedScenarios(names), isEmpty);
  });

  test('[Restrições] Fora do escopo — Layout sem largura literal', () {
    final source = File(
      'lib/src/fundacao_layout/responsive_layout/gja_responsive_layout.dart',
    ).readAsStringSync();
    final ctor = RegExp(
      r'const GjaResponsiveLayout\((.*?)\}\);',
      dotAll: true,
    ).firstMatch(source)!.group(1)!;
    expect(ctor, isNot(contains('double')));
    expect(
      RegExp(r'^  final double', multiLine: true).hasMatch(source),
      isFalse,
    );
  });
}

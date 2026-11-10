import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/fonts.dart';
import '../../support/golden.dart';
import '../../support/traceability.dart';

final _light = GjaThemeData.light();
final _march5 = DateTime(2026, 3, 5);

Widget _app(Widget home, {TextDirection direction = TextDirection.ltr}) =>
    GjaApp(
      locale: const Locale('pt', 'BR'),
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SizedBox(width: 320, child: home),
        ),
      ),
    );

/// Seletor que guarda a própria data e registra cada `onChange`.
Widget _stateful(
  List<DateTime?> log, {
  DateTime? initial,
  DateTime? minDate,
  bool enabled = true,
}) {
  var date = initial;
  return StatefulBuilder(
    builder: (context, setState) => GjaDatePicker(
      semanticLabel: 'Entrega',
      dateValue: date,
      minDate: minDate,
      enabled: enabled,
      onChange: (value) {
        log.add(value);
        setState(() => date = value);
      },
    ),
  );
}

/// Se o cabeçalho mostra o mês [month] e o ano [year].
bool _shows(String month, String year) =>
    find.text(month).evaluate().length == 1 &&
    find.text(year).evaluate().length == 1;

Future<void> _openCalendar(WidgetTester tester) async {
  await tester.tap(find.byIcon(GjaIcons.calendar));
  await tester.pumpAndSettle();
}

Finder _day(String label) => find.byWidgetPredicate(
  (w) => w is GjaInteractable && w.semanticLabel == label,
);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.tap(find.byType(EditableText));
  await tester.pump();
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump();
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

void main() {
  testWidgets('[API] Propriedades — Seletor mínimo', (tester) async {
    await tester.pumpWidget(_app(_stateful([], initial: _march5)));
    expect(find.text('05/03/2026'), findsOneWidget);
    expect(find.byIcon(GjaIcons.calendar), findsOneWidget);
  });

  testWidgets('[API] Limites válidos — Limites invertidos', (tester) async {
    await tester.pumpWidget(
      _app(
        GjaDatePicker(
          semanticLabel: 'Entrega',
          minDate: DateTime(2026, 3, 10),
          maxDate: DateTime(2026, 3, 1),
        ),
      ),
    );
    expect(tester.takeException(), isA<AssertionError>());
  });

  group('[API] Callbacks e controlador', () {
    testWidgets('[API] Callbacks e controlador — Escolher no calendário', (
      tester,
    ) async {
      final log = <DateTime?>[];
      await tester.pumpWidget(_app(_stateful(log, initial: _march5)));
      await _openCalendar(tester);
      expect(_shows('março', '2026'), isTrue);
      await tester.tap(_day('terça-feira, 17 de março de 2026'));
      await tester.pumpAndSettle();
      expect(log, [DateTime(2026, 3, 17)]);
      expect(find.text('março'), findsNothing);
      expect(find.text('17/03/2026'), findsOneWidget);
    });

    testWidgets('[API] Callbacks e controlador — Digitar uma data', (
      tester,
    ) async {
      final log = <DateTime?>[];
      await tester.pumpWidget(_app(_stateful(log)));
      await _type(tester, '20/03/2026');
      expect(log, [DateTime(2026, 3, 20)]);
    });
  });

  group('[Comportamento] Data inválida e limites', () {
    testWidgets('[Comportamento] Data inválida e limites — Data inválida', (
      tester,
    ) async {
      final log = <DateTime?>[];
      await tester.pumpWidget(_app(_stateful(log)));
      await _type(tester, '31/02/2026');
      expect(log, isEmpty);
      expect(
        tester.widget<GjaInput>(find.byType(GjaInput)).valueState,
        GjaValueState.error,
      );
    });

    testWidgets(
      '[Comportamento] Data inválida e limites — Limites do calendário',
      (tester) async {
        final handle = tester.ensureSemantics();
        final log = <DateTime?>[];
        await tester.pumpWidget(
          _app(
            _stateful(
              log,
              initial: DateTime(2026, 3, 12),
              minDate: DateTime(2026, 3, 10),
            ),
          ),
        );
        await _openCalendar(tester);
        final day5 = _day('quinta-feira, 5 de março de 2026');
        await tester.tap(day5, warnIfMissed: false);
        await tester.pump();
        expect(log, isEmpty);
        expect(
          tester.getSemantics(day5),
          containsSemantics(
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
          ),
        );
        handle.dispose();
      },
    );
  });

  testWidgets('[Comportamento] Calendário — Navegar entre meses', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_stateful([], initial: _march5)));
    await _openCalendar(tester);
    await tester.tap(find.byIcon(GjaIcons.slimArrowRight).last);
    await tester.pumpAndSettle();
    expect(_shows('abril', '2026'), isTrue);
  });

  testWidgets('[Comportamento] Teclado do calendário — Teclado no calendário', (
    tester,
  ) async {
    final log = <DateTime?>[];
    await tester.pumpWidget(
      _app(_stateful(log, initial: DateTime(2026, 3, 31))),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_shows('abril', '2026'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(log, [DateTime(2026, 4, 1)]);
  });

  testWidgets('[Aparência] Tokens de componente — Dia escolhido', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_stateful([], initial: _march5)));
    await _openCalendar(tester);
    Text dayText(String label) => tester.widget<Text>(
      find.descendant(of: _day(label), matching: find.byType(Text)),
    );
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: _day('quinta-feira, 5 de março de 2026'),
            matching: find.byType(DecoratedBox),
          )
          .last,
    );
    expect((box.decoration as BoxDecoration).color, _light.colors.brand);
    expect(
      dayText('quinta-feira, 5 de março de 2026').style?.color,
      _light.colors.contrastText,
    );
    expect(
      dayText('quarta-feira, 1 de abril de 2026').style?.color,
      _light.colors.label,
    );
    expect(
      tester.getSize(_day('quinta-feira, 5 de março de 2026')).height,
      greaterThanOrEqualTo(_light.density.minTargetSize),
    );
  });

  testWidgets('[Estados] Interação — Seletor desabilitado', (tester) async {
    await tester.pumpWidget(_app(_stateful([], enabled: false)));
    expect(find.byIcon(GjaIcons.calendar), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    await tester.pumpAndSettle();
    expect(find.text('Anterior'), findsNothing);
    expect(find.byType(GjaButton), findsNothing);
  });

  group('[Acessibilidade] Semântica e contraste', () {
    testWidgets(
      '[Acessibilidade] Semântica e contraste — Semântica do calendário',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_app(_stateful([], initial: _march5)));
        await _openCalendar(tester);
        expect(
          tester.getSemantics(_day('quinta-feira, 5 de março de 2026')),
          containsSemantics(
            isButton: true,
            isSelected: true,
            label: 'quinta-feira, 5 de março de 2026',
          ),
        );
        expect(find.semantics.byLabel('Anterior'), findsOneWidget);
        expect(find.semantics.byLabel('Próximo'), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets(
      '[Acessibilidade] Semântica e contraste — Contraste e alvo do seletor',
      (tester) async {
        final handle = tester.ensureSemantics();
        for (final (_, theme) in goldenThemes) {
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(
            GjaApp(
              key: ValueKey(theme),
              theme: theme,
              darkTheme: theme,
              density: theme.density.density,
              locale: const Locale('pt', 'BR'),
              home: GjaContainer(
                surface: GjaSurface.background,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 320,
                    child: _stateful([], initial: _march5),
                  ),
                ),
              ),
            ),
          );
          await _openCalendar(tester);
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

  testWidgets('[Responsividade] Largura e direção — Calendário em RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(direction: TextDirection.rtl, _stateful([], initial: _march5)),
    );
    await _openCalendar(tester);
    expect(
      tester.getCenter(find.text('dom.')).dx,
      greaterThan(tester.getCenter(find.text('seg.')).dx),
    );
  });

  testWidgets('[Integração] Dependências — Seletor sem Material', (
    tester,
  ) async {
    final log = <DateTime?>[];
    await tester.pumpWidget(_app(_stateful(log, initial: _march5)));
    await _openCalendar(tester);
    await tester.tap(find.byIcon(GjaIcons.slimArrowLeft).last);
    await tester.pumpAndSettle();
    await tester.tap(_day('domingo, 15 de fevereiro de 2026'));
    await tester.pumpAndSettle();
    await _type(tester, '');
    expect(log, [DateTime(2026, 2, 15), null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('[Comportamento] Escolha de mês e ano — Escolher mês e ano', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_stateful([], initial: _march5)));
    await _openCalendar(tester);
    await tester.tap(find.text('março'));
    await tester.pumpAndSettle();
    expect(find.text('dezembro'), findsOneWidget);
    await tester.tap(find.text('julho'));
    await tester.pumpAndSettle();
    expect(_shows('julho', '2026'), isTrue);
    await tester.tap(find.text('2026'));
    await tester.pumpAndSettle();
    expect(find.text('2016 – 2035'), findsOneWidget);
    await tester.tap(find.text('2028'));
    await tester.pumpAndSettle();
    expect(_shows('julho', '2028'), isTrue);
    expect(_day('sábado, 1 de julho de 2028'), findsOneWidget);
  });

  testWidgets('[Comportamento] Botão Hoje — Escolher hoje', (tester) async {
    final log = <DateTime?>[];
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => GjaDatePicker(
            semanticLabel: 'Entrega',
            showCurrentDateButton: true,
            dateValue: log.isEmpty ? _march5 : log.last,
            onChange: (value) => setState(() => log.add(value)),
          ),
        ),
      ),
    );
    await _openCalendar(tester);
    await tester.tap(
      find.byWidgetPredicate((w) => w is GjaButton && w.tooltip == 'Hoje'),
    );
    await tester.pumpAndSettle();
    final now = DateTime.now();
    expect(log, [DateTime(now.year, now.month, now.day)]);
    expect(find.text('Anterior'), findsNothing);
    expect(find.byType(GjaInteractable).evaluate().length, lessThan(10));
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade do seletor', () {
      final names = scenarioNames(
        'gja/widgets/gja-date-picker',
        'add-gja-date-picker',
      );
      expect(names, hasLength(20));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens do seletor', (
      tester,
    ) async {
      await loadGjaFonts();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(440, 480);
      addTearDown(tester.view.reset);
      for (final (name, theme) in goldenThemes) {
        // Uma aplicação nova por tema, para o calendário abrir com a âncora
        // no lugar final.
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          GjaApp(
            theme: theme,
            darkTheme: theme,
            density: theme.density.density,
            locale: const Locale('pt', 'BR'),
            debugShowCheckedModeBanner: false,
            builder: (context, child) =>
                RepaintBoundary(key: const Key('golden'), child: child!),
            home: GjaContainer(
              key: ValueKey(name),
              surface: GjaSurface.background,
              padding: GjaSpace.l,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 400,
                  child: GjaDatePicker(
                    semanticLabel: 'Entrega',
                    dateValue: _march5,
                    minDate: DateTime(2026, 3, 3),
                    showCurrentDateButton: true,
                    onChange: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await _openCalendar(tester);
        await expectLater(
          find.byKey(const Key('golden')),
          matchesGoldenFile('goldens/gja_date_picker_$name.png'),
        );
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Seletor sem valor literal', () {
    final source = File(
      'lib/src/formularios/date_picker/gja_date_picker.dart',
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

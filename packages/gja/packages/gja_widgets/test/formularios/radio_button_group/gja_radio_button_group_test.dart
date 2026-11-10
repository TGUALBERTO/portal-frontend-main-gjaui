import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/traceability.dart';

Widget _app(Widget home, {TextDirection direction = TextDirection.ltr}) =>
    GjaApp(
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: Center(child: home),
    );

const _payment = [
  GjaRadioButton(text: 'Boleto'),
  GjaRadioButton(text: 'Pix'),
  GjaRadioButton(text: 'Cartão'),
];

/// Grupo que guarda o próprio índice e registra cada `onSelect`.
Widget _stateful(
  List<int> log, {
  int initial = 0,
  List<GjaRadioButton> buttons = _payment,
  int columns = 1,
}) {
  var index = initial;
  return StatefulBuilder(
    builder: (context, setState) => GjaRadioButtonGroup(
      buttons: buttons,
      selectedIndex: index,
      columns: columns,
      onSelect: (i) {
        log.add(i);
        setState(() => index = i);
      },
    ),
  );
}

List<bool> _selected(WidgetTester tester) => tester
    .widgetList<GjaRadioButton>(find.byType(GjaRadioButton))
    .map((b) => b.selected)
    .toList();

GjaRadioButton? _focused() => FocusManager.instance.primaryFocus?.context
    ?.findAncestorWidgetOfExactType<GjaRadioButton>();

void main() {
  testWidgets('[API] Propriedades — Grupo mínimo', (tester) async {
    await tester.pumpWidget(
      _app(const GjaRadioButtonGroup(buttons: _payment, selectedIndex: 1)),
    );
    expect(_selected(tester), [false, true, false]);
    expect(
      tester.getTopLeft(find.text('Pix')).dy,
      greaterThan(tester.getTopLeft(find.text('Boleto')).dy),
    );
  });

  testWidgets('[API] Opções válidas — Grupo sem opções', (tester) async {
    await tester.pumpWidget(
      _app(GjaRadioButtonGroup(buttons: <GjaRadioButton>[])),
    );
    expect(tester.takeException(), isA<AssertionError>());
    var columns = 0;
    expect(
      () => GjaRadioButtonGroup(buttons: _payment, columns: columns),
      throwsAssertionError,
    );
  });

  testWidgets('[API] Callbacks e controlador — Escolher no grupo', (
    tester,
  ) async {
    final log = <int>[];
    await tester.pumpWidget(_app(_stateful(log)));
    await tester.tap(find.text('Cartão'));
    await tester.pump();
    expect(log, [2]);
    expect(_selected(tester), [false, false, true]);
  });

  testWidgets('[Comportamento] Navegação pelas setas — Setas no grupo', (
    tester,
  ) async {
    final log = <int>[];
    await tester.pumpWidget(
      _app(
        _stateful(
          log,
          buttons: const [
            GjaRadioButton(text: 'a'),
            GjaRadioButton(text: 'b', enabled: false),
            GjaRadioButton(text: 'c'),
          ],
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focused()?.text, 'a');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(log, [2]);
    expect(_focused()?.text, 'c');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(log, [2, 0]);
  });

  testWidgets('[Aparência] Colunas e espaço — Grupo em duas colunas', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 400,
          child: GjaRadioButtonGroup(
            columns: 2,
            buttons: const [
              GjaRadioButton(text: 'a'),
              GjaRadioButton(text: 'b'),
              GjaRadioButton(text: 'c'),
              GjaRadioButton(text: 'd'),
            ],
          ),
        ),
      ),
    );
    final a = tester.getTopLeft(find.text('a'));
    expect(tester.getTopLeft(find.text('b')).dy, a.dy);
    expect(tester.getTopLeft(find.text('c')).dy, greaterThan(a.dy));
    expect(tester.getTopLeft(find.text('c')).dx, a.dx);
  });

  testWidgets('[Estados] Estados do grupo — Grupo desabilitado', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const GjaRadioButtonGroup(buttons: _payment, enabled: false)),
    );
    expect(
      tester
          .widgetList<GjaRadioButton>(find.byType(GjaRadioButton))
          .every((b) => !b.enabled),
      isTrue,
    );
  });

  testWidgets('[Acessibilidade] Teclado e semântica — Tab no grupo', (
    tester,
  ) async {
    final first = FocusNode();
    final last = FocusNode();
    addTearDown(first.dispose);
    addTearDown(last.dispose);
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Focus(focusNode: first, child: const SizedBox.square(dimension: 8)),
            const GjaRadioButtonGroup(buttons: _payment, selectedIndex: 1),
            Focus(focusNode: last, child: const SizedBox.square(dimension: 8)),
          ],
        ),
      ),
    );
    first.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focused()?.text, 'Pix');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(last.hasPrimaryFocus, isTrue);
  });

  testWidgets('[Responsividade] Largura — Colunas em RTL', (tester) async {
    await tester.pumpWidget(
      _app(
        direction: TextDirection.rtl,
        SizedBox(
          width: 400,
          child: GjaRadioButtonGroup(
            columns: 2,
            buttons: const [
              GjaRadioButton(text: 'a'),
              GjaRadioButton(text: 'b'),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getCenter(find.text('a')).dx,
      greaterThan(tester.getCenter(find.text('b')).dx),
    );
  });

  testWidgets('[Integração] Dependências — Grupo sem Material', (tester) async {
    await tester.pumpWidget(_app(_stateful([])));
    for (final text in ['Boleto', 'Pix', 'Cartão']) {
      await tester.tap(find.text(text));
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
  });

  test('[Testes] Cobertura exigida — Rastreabilidade do grupo', () {
    final names = scenarioNames(
      'gja/widgets/gja-radio-button-group',
      'add-gja-radio-button',
    );
    expect(names, hasLength(12));
    expect(untestedScenarios(names), isEmpty);
  });

  test('[Restrições] Fora do escopo — Grupo sem valor literal', () {
    const group = GjaRadioButtonGroup(buttons: _payment);
    expect(group.columns, isA<int>());
    expect(group.valueState, GjaValueState.none);
  });
}

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import '../../support/golden.dart';
import '../../support/traceability.dart';

final _light = GjaThemeData.light();

Widget _app(
  Widget home, {
  double width = 1100,
  TextDirection direction = TextDirection.ltr,
}) => GjaApp(
  builder: (context, child) =>
      Directionality(textDirection: direction, child: child!),
  home: Align(
    alignment: Alignment.topCenter,
    child: SizedBox(width: width, child: home),
  ),
);

Widget _input(String placeholder) =>
    GjaInput(placeholder: 'Informe $placeholder', onLiveChange: (_) {});

final _dados = GjaFormContainer(
  title: 'Dados',
  formElements: [
    GjaFormElement(label: 'Nome', required: true, fields: [_input('Nome')]),
    GjaFormElement(label: 'Cidade', fields: [_input('Cidade')]),
  ],
);

final _contato = GjaFormContainer(
  title: 'Contato',
  formElements: [
    GjaFormElement(label: 'E-mail', fields: [_input('E-mail')]),
    GjaFormElement(
      label: 'Telefone',
      fields: [_input('DDD'), _input('Número')],
    ),
  ],
);

GjaForm _form({
  List<GjaFormContainer>? containers,
  String? title = 'Fornecedor',
  int columnsL = 2,
}) => GjaForm(
  editable: true,
  title: title,
  columnsL: columnsL,
  formContainers: containers ?? [_dados],
);

Finder _label(String text) =>
    find.byWidgetPredicate((w) => w is GjaLabel && w.text == text);

/// Superfície larga o bastante para as larguras L e XL.
void _wide(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1600, 1200);
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('[API] Propriedades — Formulário mínimo', (tester) async {
    _wide(tester);
    await tester.pumpWidget(_app(_form()));
    expect(
      tester.getTopLeft(find.text('Fornecedor')).dy,
      lessThan(tester.getTopLeft(_label('Nome')).dy),
    );
    for (final name in ['Nome', 'Cidade']) {
      final label = tester.getCenter(_label(name));
      final field = tester.getCenter(
        find.byType(EditableText).at(name == 'Nome' ? 0 : 1),
      );
      expect(label.dx, lessThan(field.dx));
      expect(label.dy, closeTo(field.dy, 2));
    }
  });

  testWidgets('[API] Contêineres e elementos válidos — Elemento sem campo', (
    tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(
      _app(
        const GjaForm(
          editable: true,
          formContainers: [
            GjaFormContainer(
              formElements: [GjaFormElement(label: 'Nome', fields: [])],
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('[API] Callbacks e controlador — Campo dentro do formulário', (
    tester,
  ) async {
    _wide(tester);
    final log = <String>[];
    await tester.pumpWidget(
      _app(
        GjaForm(
          editable: true,
          formContainers: [
            GjaFormContainer(
              formElements: [
                GjaFormElement(
                  label: 'Nome',
                  fields: [
                    GjaInput(placeholder: 'Nome', onLiveChange: log.add),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'ACME');
    await tester.pump();
    expect(log.last, 'ACME');
  });

  group('[Comportamento] Colunas e rótulos', () {
    testWidgets('[Comportamento] Colunas e rótulos — Contêineres em colunas', (
      tester,
    ) async {
      _wide(tester);
      final form = _form(containers: [_dados, _contato]);
      await tester.pumpWidget(_app(form));
      expect(
        tester.getTopLeft(find.text('Contato')).dy,
        tester.getTopLeft(find.text('Dados')).dy,
      );
      expect(
        tester.getTopLeft(find.text('Contato')).dx,
        greaterThan(tester.getTopLeft(find.text('Dados')).dx),
      );
      await tester.pumpWidget(_app(form, width: 800));
      expect(
        tester.getTopLeft(find.text('Contato')).dy,
        greaterThan(tester.getBottomLeft(find.text('Cidade')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Contato')).dx,
        tester.getTopLeft(find.text('Dados')).dx,
      );
    });

    testWidgets(
      '[Comportamento] Colunas e rótulos — Rótulos acima no celular',
      (tester) async {
        _wide(tester);
        await tester.pumpWidget(_app(_form(), width: 400));
        final label = tester.getRect(find.text('Cidade'));
        final field = tester.getRect(find.byType(EditableText).at(1));
        expect(field.top, greaterThan(label.bottom));
      },
    );
  });

  testWidgets('[Comportamento] Modo de exibição — Formulário de exibição', (
    tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(
      _app(
        const GjaForm(
          formContainers: [
            GjaFormContainer(
              formElements: [
                GjaFormElement(
                  label: 'Cidade',
                  fields: [GjaText('Belo Horizonte')],
                ),
              ],
            ),
          ],
        ),
      ),
    );
    expect(
      tester.getTopLeft(_label('Cidade')).dy,
      tester.getTopLeft(find.text('Belo Horizonte')).dy,
    );
  });

  testWidgets('[Aparência] Tokens de componente — Largura do rótulo', (
    tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(_app(width: 1200, _form(title: null, columnsL: 1)));
    final input = tester.getRect(find.byType(GjaInput).first);
    final form = tester.getRect(find.byType(GjaForm));
    expect(input.left - form.left, closeTo(1200 / 3, 1));
    final labelBox = find.ancestor(
      of: find.byType(GjaLabel).first,
      matching: find.byType(Padding),
    );
    expect(
      tester.widget<Padding>(labelBox.first).padding,
      EdgeInsetsDirectional.only(end: _light.spacing.s),
    );
    expect(
      tester.widget<Text>(find.text('Dados')).style?.fontSize,
      _light.typography.header5.fontSize,
    );
  });

  testWidgets('[Estados] Obrigatório — Elemento obrigatório', (tester) async {
    _wide(tester);
    await tester.pumpWidget(_app(_form()));
    expect(
      tester
          .widgetList<GjaLabel>(find.byType(GjaLabel))
          .firstWhere((label) => label.text == 'Nome')
          .required,
      isTrue,
    );
    expect(find.textContaining('*'), findsOneWidget);
  });

  group('[Acessibilidade] Semântica e contraste', () {
    testWidgets(
      '[Acessibilidade] Semântica e contraste — Semântica do formulário',
      (tester) async {
        _wide(tester);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_app(_form()));
        expect(
          tester.getSemantics(find.text('Fornecedor')),
          containsSemantics(isHeader: true),
        );
        expect(
          tester.getSemantics(find.text('Dados')),
          containsSemantics(isHeader: true),
        );
        final order = tester.semantics
            .simulatedAccessibilityTraversal()
            .map((node) => node.label)
            .where((label) => label.contains('Nome'))
            .toList();
        expect(order.first, startsWith('Nome'));
        expect(order.length, greaterThan(1));
        handle.dispose();
      },
    );

    testWidgets(
      '[Acessibilidade] Semântica e contraste — Contraste do formulário',
      (tester) async {
        _wide(tester);
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
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 1100,
                    child: _form(containers: [_dados, _contato]),
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

  testWidgets('[Responsividade] Direção — Formulário em RTL', (tester) async {
    _wide(tester);
    await tester.pumpWidget(_app(direction: TextDirection.rtl, _form()));
    expect(
      tester.getCenter(find.text('Cidade')).dx,
      greaterThan(tester.getCenter(find.byType(EditableText).at(1)).dx),
    );
  });

  testWidgets('[Integração] Dependências — Formulário sem Material', (
    tester,
  ) async {
    _wide(tester);
    var selected = false;
    String? status;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => GjaForm(
            editable: true,
            formContainers: [
              GjaFormContainer(
                formElements: [
                  GjaFormElement(label: 'Nome', fields: [_input('Nome')]),
                  GjaFormElement(
                    label: 'Status',
                    fields: [
                      GjaSelect<String>(
                        semanticLabel: 'Status',
                        selectedKey: status,
                        onChange: (value) => setState(() => status = value),
                        items: const [
                          GjaDropdownItem(key: 'a', text: 'Ativo'),
                          GjaDropdownItem(key: 'i', text: 'Inativo'),
                        ],
                      ),
                    ],
                  ),
                  GjaFormElement(
                    label: 'Preferencial',
                    fields: [
                      GjaCheckBox(
                        semanticLabel: 'Preferencial',
                        selected: selected,
                        onSelect: (value) => setState(() => selected = value),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'ACME');
    await tester.tap(find.byType(GjaCheckBox));
    await tester.pumpAndSettle();
    expect(selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  group('[Testes] Cobertura exigida', () {
    test('[Testes] Cobertura exigida — Rastreabilidade do formulário', () {
      final names = scenarioNames('gja/widgets/gja-form', 'add-gja-form');
      expect(names, hasLength(16));
      expect(untestedScenarios(names), isEmpty);
    });

    testWidgets('[Testes] Cobertura exigida — Goldens do formulário', (
      tester,
    ) async {
      _wide(tester);
      for (final (name, theme) in goldenThemes) {
        for (final (size, width) in [('l', 1040.0), ('s', 360.0)]) {
          await tester.pumpWidget(const SizedBox());
          await expectGolden(
            tester,
            name: 'gja_form_${size}_$name',
            theme: theme,
            size: Size(width + 40, size == 'l' ? 260 : 520),
            child: SizedBox(
              width: width,
              child: _form(containers: [_dados, _contato]),
            ),
          );
        }
      }
    }, tags: ['golden']);
  });

  test('[Restrições] Fora do escopo — Formulário sem valor literal', () {
    final source = File(
      'lib/src/formularios/form/gja_form.dart',
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

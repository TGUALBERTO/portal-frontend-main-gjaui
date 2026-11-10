import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../../fundacao_layout/label/gja_label.dart';
import '../../fundacao_layout/title/gja_title.dart';

/// Elemento de um [GjaFormContainer], como o `sap.ui.layout.form.FormElement`
/// do SAPUI5: um rótulo e os campos que ele descreve.
///
/// É uma configuração, não um widget: use em
/// [GjaFormContainer.formElements].
@immutable
class GjaFormElement {
  /// Cria o elemento com [fields].
  const GjaFormElement({
    required this.fields,
    this.label,
    this.required = false,
  });

  /// Texto do rótulo.
  final String? label;

  /// Se o rótulo mostra o asterisco de obrigatório.
  final bool required;

  /// Campos do elemento, lado a lado; cada um mantém o próprio estado.
  final List<Widget> fields;
}

/// Grupo de elementos de um [GjaForm], como o
/// `sap.ui.layout.form.FormContainer` do SAPUI5.
///
/// É uma configuração, não um widget: use em [GjaForm.formContainers].
@immutable
class GjaFormContainer {
  /// Cria o contêiner com [formElements].
  const GjaFormContainer({required this.formElements, this.title});

  /// Título do contêiner.
  final String? title;

  /// Elementos, de cima para baixo.
  final List<GjaFormElement> formElements;
}

/// Formulário, como o `sap.ui.layout.form.Form` com o `ColumnLayout` do
/// SAPUI5.
///
/// Mostra [title] e os [formContainers] distribuídos em colunas pela
/// largura do próprio formulário (não da tela): 1 coluna no S e [columnsM],
/// [columnsL] ou [columnsXL] nas outras classes de tamanho, no máximo uma
/// por contêiner. Os rótulos ficam ao lado dos campos, com
/// [labelCellsLarge] partes de 12 da coluna, no L e no XL, e no M com uma
/// coluna; nos outros casos, acima.
///
/// Com [editable] `false` (o padrão, como no UI5), o formulário mostra
/// valores, e o rótulo fica alinhado ao topo dos campos; com `true`, para
/// campos de entrada, o rótulo acompanha a altura deles. O formulário não
/// tem estado: cada campo mantém o próprio valor e os próprios eventos.
///
/// ```dart
/// GjaForm(
///   title: 'Fornecedor',
///   editable: true,
///   formContainers: [
///     GjaFormContainer(
///       formElements: [
///         GjaFormElement(
///           label: 'Nome',
///           required: true,
///           fields: [GjaInput(value: nome, placeholder: 'Nome', onLiveChange: ...)],
///         ),
///       ],
///     ),
///   ],
/// )
/// ```
class GjaForm extends StatelessWidget {
  /// Cria o formulário com [formContainers].
  const GjaForm({
    required this.formContainers,
    this.title,
    this.columnsM = 1,
    this.columnsL = 2,
    this.columnsXL = 2,
    this.labelCellsLarge = 4,
    this.editable = false,
    super.key,
  });

  /// Título do formulário.
  final String? title;

  /// Contêineres, na ordem das colunas.
  final List<GjaFormContainer> formContainers;

  /// Colunas no M, de 1 a 2.
  final int columnsM;

  /// Colunas no L, de 1 a 3.
  final int columnsL;

  /// Colunas no XL, de 1 a 4.
  final int columnsXL;

  /// Partes de 12 da coluna ocupadas pelo rótulo ao lado, de 1 a 11.
  final int labelCellsLarge;

  /// Se o formulário tem campos de entrada (edição) ou mostra valores
  /// (exibição), como o `editable` do `sap.ui.layout.form.Form`.
  final bool editable;

  void _validate() {
    assert(formContainers.isNotEmpty, 'formContainers não pode ser vazia');
    assert(
      formContainers.every(
        (c) =>
            c.formElements.isNotEmpty &&
            c.formElements.every((e) => e.fields.isNotEmpty),
      ),
      'formElements e fields não podem ser vazias',
    );
    assert(columnsM >= 1 && columnsM <= 2, 'columnsM deve estar entre 1 e 2');
    assert(columnsL >= 1 && columnsL <= 3, 'columnsL deve estar entre 1 e 3');
    assert(
      columnsXL >= 1 && columnsXL <= 4,
      'columnsXL deve estar entre 1 e 4',
    );
    assert(
      labelCellsLarge >= 1 && labelCellsLarge <= 11,
      'labelCellsLarge deve estar entre 1 e 11',
    );
  }

  @override
  Widget build(BuildContext context) {
    _validate();
    final theme = GjaThemeData.of(context);
    final spacing = theme.spacing;
    final text = title;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sizeClass = theme.breakpoints.classify(constraints.maxWidth);
          final wanted = switch (sizeClass) {
            GjaSizeClass.small => 1,
            GjaSizeClass.medium => columnsM,
            GjaSizeClass.large => columnsL,
            GjaSizeClass.extraLarge => columnsXL,
          };
          final columns = wanted < formContainers.length
              ? wanted
              : formContainers.length;
          final beside =
              sizeClass.isAtLeast(GjaSizeClass.large) ||
              (sizeClass == GjaSizeClass.medium && columns == 1);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: spacing.l,
            children: [
              if (text != null)
                GjaTitle(text, titleStyle: GjaTitleLevel.h4),
              for (var i = 0; i < formContainers.length; i += columns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: spacing.l,
                  children: [
                    for (var j = i; j < i + columns; j++)
                      Expanded(
                        child: j < formContainers.length
                            ? _Container(
                                container: formContainers[j],
                                beside: beside,
                                labelCells: labelCellsLarge,
                                editable: editable,
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Container extends StatelessWidget {
  const _Container({
    required this.container,
    required this.beside,
    required this.labelCells,
    required this.editable,
  });

  final GjaFormContainer container;
  final bool beside;
  final int labelCells;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final text = container.title;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.spacing.s,
      children: [
        if (text != null) GjaTitle(text, titleStyle: GjaTitleLevel.h5),
        for (final element in container.formElements)
          _Element(
            element: element,
            beside: beside,
            labelCells: labelCells,
            editable: editable,
          ),
      ],
    );
  }
}

class _Element extends StatelessWidget {
  const _Element({
    required this.element,
    required this.beside,
    required this.labelCells,
    required this.editable,
  });

  final GjaFormElement element;
  final bool beside;
  final int labelCells;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final spacing = theme.spacing;
    final text = element.label;
    final label = text == null
        ? null
        : GjaLabel(text, required: element.required, wrapping: true);
    final fields = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: spacing.s,
      children: [
        // No início da célula, como no UI5: campos que não esticam (uma
        // caixa de seleção, por exemplo) não ficam centrados.
        for (final field in element.fields)
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              heightFactor: 1,
              child: field,
            ),
          ),
      ],
    );
    if (!beside) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.xs,
        children: [?label, fields],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: labelCells,
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: spacing.s),
            child: editable
                ? ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: theme.density.minTargetSize,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: 1,
                      child: label,
                    ),
                  )
                : Align(
                    alignment: AlignmentDirectional.topStart,
                    widthFactor: 1,
                    heightFactor: 1,
                    child: label,
                  ),
          ),
        ),
        Expanded(flex: 12 - labelCells, child: fields),
      ],
    );
  }
}

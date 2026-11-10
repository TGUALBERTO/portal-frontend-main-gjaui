import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../../fundacao_layout/text/gja_text.dart';
import '../../fundacao_layout/title/gja_title.dart';

/// Situação de uma [GjaIllustratedMessage], como o `IllustratedMessageType`
/// do SAPUI5; define o ícone da ilustração.
enum GjaIllustrationType {
  /// Não há dados para mostrar.
  noData,

  /// A lista ainda não tem itens.
  noEntries,

  /// A busca não encontrou resultados.
  noSearchResults,

  /// Os filtros não deixaram resultados.
  noFilterResults,

  /// Algo deu errado.
  error,

  /// A operação terminou com sucesso.
  success,
}

/// Tamanho de uma [GjaIllustratedMessage], como o `IllustratedMessageSize`
/// do SAPUI5.
enum GjaIllustrationSize {
  /// Pequena, para cartões e áreas estreitas.
  spot,

  /// Média, para diálogos e painéis.
  dialog,

  /// Grande, para páginas inteiras.
  scene,
}

/// Mensagem com ilustração para uma área sem conteúdo, como o
/// `sap.m.IllustratedMessage` do SAPUI5.
///
/// Mostra, centralizados, a ilustração do [illustrationType] (ou
/// [illustration]), o [title], a [description] e as ações de
/// [additionalContent]. [illustrationSize] define o tamanho da ilustração e
/// o estilo do título. As ilustrações da SAP não são reproduzidas: sem
/// [illustration], a ilustração é um ícone grande do catálogo.
///
/// ```dart
/// GjaIllustratedMessage(
///   illustrationType: GjaIllustrationType.noSearchResults,
///   title: 'Nenhum pedido encontrado',
///   description: 'Tente outros termos de busca.',
///   additionalContent: [GjaButton(text: 'Limpar busca', onPress: limpar)],
/// )
/// ```
class GjaIllustratedMessage extends StatelessWidget {
  /// Cria a mensagem com [title].
  const GjaIllustratedMessage({
    required this.title,
    this.description,
    this.illustrationType = GjaIllustrationType.noData,
    this.illustrationSize = GjaIllustrationSize.dialog,
    this.illustration,
    this.titleLevel = GjaTitleLevel.auto,
    this.additionalContent = const [],
    super.key,
  }) : assert(title != '', 'title não pode ser vazio');

  /// Título da mensagem.
  final String title;

  /// Texto que explica a situação e o que fazer.
  final String? description;

  /// Situação, que define o ícone da ilustração.
  final GjaIllustrationType illustrationType;

  /// Tamanho da ilustração e do título.
  final GjaIllustrationSize illustrationSize;

  /// Ilustração própria, no lugar do ícone do tipo.
  final Widget? illustration;

  /// Nível do título para leitores de tela.
  final GjaTitleLevel titleLevel;

  /// Ações abaixo da descrição, em geral botões.
  final List<Widget> additionalContent;

  IconData get _icon => switch (illustrationType) {
    GjaIllustrationType.noData => GjaIcons.document,
    GjaIllustrationType.noEntries => GjaIcons.folderBlank,
    GjaIllustrationType.noSearchResults => GjaIcons.search,
    GjaIllustrationType.noFilterResults => GjaIcons.filter,
    GjaIllustrationType.error => GjaIcons.error,
    GjaIllustrationType.success => GjaIcons.sysEnter2,
  };

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final (double factor, GjaTitleLevel style) = switch (illustrationSize) {
      GjaIllustrationSize.spot => (1, GjaTitleLevel.h4),
      GjaIllustrationSize.dialog => (2, GjaTitleLevel.h3),
      GjaIllustrationSize.scene => (4, GjaTitleLevel.h2),
    };
    final description = this.description;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.spacing.m,
      children: [
        ExcludeSemantics(
          child:
              illustration ??
              Icon(
                _icon,
                size: theme.icons.xLarge * factor,
                color: theme.colors.brand,
              ),
        ),
        GjaTitle(
          title,
          level: titleLevel,
          titleStyle: style,
          wrapping: true,
          textAlign: TextAlign.center,
        ),
        if (description != null)
          GjaText(description, textAlign: TextAlign.center),
        if (additionalContent.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.s,
            children: additionalContent,
          ),
      ],
    );
  }
}

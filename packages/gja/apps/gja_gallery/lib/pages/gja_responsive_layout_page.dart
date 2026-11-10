import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaResponsiveLayout": o mesmo formulário de exemplo pela classe
/// da tela e pela classe de um painel de 400.
///
/// O formulário tem uma coluna em `small` e duas a partir de `medium`. A
/// largura do painel é literal da galeria.
class GjaResponsiveLayoutPage extends StatelessWidget {
  /// Cria a página.
  const GjaResponsiveLayoutPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'GjaResponsiveLayout';

  /// Rota nomeada.
  static const route = '/gja-responsive-layout';

  /// Chave do exemplo de base `screen`.
  static const screenKey = Key('responsive-layout-screen');

  /// Chave do exemplo de base `container`.
  static const containerKey = Key('responsive-layout-container');

  /// Rótulo exibido pelo formulário de uma coluna.
  static const oneColumn = 'uma coluna';

  /// Rótulo exibido pelo formulário de duas colunas.
  static const twoColumns = 'duas colunas';

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        GjaSpacing.padding(
          all: GjaSpace.pageMargin,
          child: GjaVBox(
            gap: GjaSpace.l,
            items: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Semantics(
                  button: true,
                  child: const GjaText('← Voltar'),
                ),
              ),
              const GjaTitle(
                title,
                level: GjaTitleLevel.h1,
                titleStyle: GjaTitleLevel.h2,
              ),
              const GjaTitle(
                'Pela classe da tela',
                level: GjaTitleLevel.h2,
                titleStyle: GjaTitleLevel.h3,
              ),
              const _Form(key: screenKey, basis: GjaLayoutBasis.screen),
              const GjaTitle(
                'Pela classe de um painel de 400',
                level: GjaTitleLevel.h2,
                titleStyle: GjaTitleLevel.h3,
              ),
              const SizedBox(
                width: 400,
                child: _Form(
                  key: containerKey,
                  basis: GjaLayoutBasis.container,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Formulário de exemplo: uma coluna em `small`, duas a partir de `medium`.
class _Form extends StatelessWidget {
  const _Form({required this.basis, super.key});

  final GjaLayoutBasis basis;

  static const _fields = [
    _Field('Fornecedor'),
    _Field('Centro de custo'),
    _Field('Data de entrega'),
    _Field('Valor'),
  ];

  @override
  Widget build(BuildContext context) {
    return GjaContainer(
      surface: GjaSurface.base,
      border: true,
      radius: GjaRadius.tile,
      padding: GjaSpace.l,
      child: GjaResponsiveLayout(
        basis: basis,
        small: (context) => const GjaVBox(
          items: [GjaLabel(GjaResponsiveLayoutPage.oneColumn), ..._fields],
        ),
        medium: (context) => GjaVBox(
          items: [
            const GjaLabel(GjaResponsiveLayoutPage.twoColumns),
            for (var i = 0; i < _fields.length; i += 2)
              GjaHBox(
                gap: GjaSpace.l,
                items: [
                  Expanded(child: _fields[i]),
                  Expanded(child: _fields[i + 1]),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Campo de exemplo: rótulo e uma caixa vazia.
class _Field extends StatelessWidget {
  const _Field(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final height = GjaTheme.of(context).density.controlHeight;
    return GjaVBox(
      gap: GjaSpace.xs,
      items: [
        GjaLabel(label),
        GjaContainer(
          border: true,
          radius: GjaRadius.field,
          child: SizedBox(height: height, width: double.infinity),
        ),
      ],
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaBreadcrumbs": uma trilha navegável e os separadores.
class GjaBreadcrumbsPage extends StatefulWidget {
  /// Cria a página.
  const GjaBreadcrumbsPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaBreadcrumbs';

  /// Rota nomeada.
  static const route = '/gja-breadcrumbs';

  /// Chave da trilha navegável.
  static const trailKey = Key('breadcrumbs-trail');

  @override
  State<GjaBreadcrumbsPage> createState() => _GjaBreadcrumbsPageState();
}

class _GjaBreadcrumbsPageState extends State<GjaBreadcrumbsPage> {
  static const _levels = ['Início', 'Vendas', 'Pedidos', 'Pedido 4711'];
  int _depth = _levels.length - 1;

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaBreadcrumbsPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Trilhas no modelo do sap.m.Breadcrumbs'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            GjaBreadcrumbs(
              key: GjaBreadcrumbsPage.trailKey,
              semanticLabel: 'Caminho',
              links: [
                for (var i = 0; i < _depth; i++)
                  GjaLink(
                    text: _levels[i],
                    onPress: () => setState(() => _depth = i),
                  ),
              ],
              currentLocationText: _levels[_depth],
            ),
            if (_depth < _levels.length - 1)
              GjaButton(
                text: 'Voltar ao pedido',
                onPress: () => setState(() => _depth = _levels.length - 1),
              ),
            const GjaTitle(
              'Separadores',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            for (final style in GjaBreadcrumbsSeparator.values)
              GjaBreadcrumbs(
                separatorStyle: style,
                links: [
                  GjaLink(text: 'Início', onPress: () {}),
                  GjaLink(text: 'Pedidos', onPress: () {}),
                ],
                currentLocationText: style.name,
              ),
          ],
        ),
      ],
    );
  }
}

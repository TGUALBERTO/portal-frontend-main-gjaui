import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaHBox e GjaVBox": alinhamentos, linha de base, item
/// expandido e quebra.
///
/// Os blocos são `GjaContainer` com superfície `base` e borda; as áreas de
/// demonstração usam `header`, para que o espaço livre fique visível. As
/// dimensões das áreas são literais da galeria.
class GjaHBoxVBoxPage extends StatelessWidget {
  /// Cria a página.
  const GjaHBoxVBoxPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'GjaHBox e GjaVBox';

  /// Rota nomeada.
  static const route = '/gja-hbox-vbox';

  /// Chave da caixa horizontal com o alinhamento principal [alignment].
  static Key rowKey(GjaFlexJustifyContent alignment) =>
      ValueKey('row-${alignment.name}');

  /// Chave da caixa vertical com o alinhamento cruzado [alignment].
  static Key columnKey(GjaFlexAlignItems alignment) =>
      ValueKey('column-${alignment.name}');

  /// Chave do item expandido da caixa horizontal.
  static const rowExpandedKey = Key('row-expanded');

  /// Chave do item expandido da caixa vertical.
  static const columnExpandedKey = Key('column-expanded');

  /// Chave da caixa horizontal com quebra.
  static const wrapKey = Key('row-wrap');

  /// Chave da caixa horizontal alinhada pela linha de base.
  static const baselineKey = Key('row-baseline');

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        GjaSpacing.padding(
          all: GjaSpace.pageMargin,
          child: GjaVBox(
            gap: GjaSpace.s,
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
              const GjaSpacing.vertical(GjaSpace.l),
              const GjaTitle(
                'GjaHBox: alinhamento principal',
                level: GjaTitleLevel.h2,
                titleStyle: GjaTitleLevel.h3,
              ),
              for (final alignment in GjaFlexJustifyContent.values) ...[
                GjaLabel(alignment.name),
                _Area(
                  child: GjaHBox(
                    key: rowKey(alignment),
                    justifyContent: alignment,
                    items: const [_Block(), _Block(), _Block()],
                  ),
                ),
              ],
              const GjaLabel('baseline'),
              const _Area(
                child: GjaHBox(
                  key: baselineKey,
                  alignItems: GjaFlexAlignItems.baseline,
                  items: [
                    GjaTitle('Pedido 4711', titleStyle: GjaTitleLevel.h2),
                    GjaText('Aguardando aprovação'),
                  ],
                ),
              ),
              const GjaLabel('expandido'),
              const _Area(
                child: GjaHBox(
                  items: [
                    _Block(),
                    Expanded(child: _Block(key: rowExpandedKey)),
                  ],
                ),
              ),
              const GjaLabel('wrap'),
              SizedBox(
                width: 240,
                child: _Area(
                  child: GjaHBox(
                    wrap: GjaFlexWrap.wrap,
                    alignItems: GjaFlexAlignItems.start,
                    key: wrapKey,
                    items: [for (var i = 0; i < 8; i++) const _Block()],
                  ),
                ),
              ),
              const GjaSpacing.vertical(GjaSpace.l),
              const GjaTitle(
                'GjaVBox: alinhamento cruzado',
                level: GjaTitleLevel.h2,
                titleStyle: GjaTitleLevel.h3,
              ),
              GjaHBox(
                alignItems: GjaFlexAlignItems.start,
                items: [
                  for (final alignment in GjaFlexAlignItems.values)
                    if (alignment != GjaFlexAlignItems.baseline)
                      Expanded(
                        child: GjaVBox(
                          gap: GjaSpace.xs,
                          items: [
                            GjaLabel(alignment.name),
                            SizedBox(
                              height: 160,
                              child: _Area(
                                child: GjaVBox(
                                  key: columnKey(alignment),
                                  alignItems: alignment,
                                  items: const [_Block(), _Block()],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  const Expanded(
                    child: GjaVBox(
                      gap: GjaSpace.xs,
                      items: [
                        GjaLabel('expandido'),
                        SizedBox(
                          height: 160,
                          child: _Area(
                            child: GjaVBox(
                              items: [
                                _Block(),
                                Expanded(child: _Block(key: columnExpandedKey)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Área de demonstração com fundo `header`.
class _Area extends StatelessWidget {
  const _Area({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => GjaContainer(
    surface: GjaSurface.header,
    radius: GjaRadius.element,
    padding: GjaSpace.s,
    child: child,
  );
}

/// Bloco de exemplo, com o tamanho do espaço `xl`.
class _Block extends StatelessWidget {
  const _Block({super.key});

  @override
  Widget build(BuildContext context) {
    final size = GjaTheme.of(context).spacing.xl;
    return GjaContainer(
      surface: GjaSurface.base,
      border: true,
      radius: GjaRadius.xs,
      child: SizedBox(width: size, height: size),
    );
  }
}

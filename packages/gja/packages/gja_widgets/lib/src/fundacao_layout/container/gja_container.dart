import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../spacing/gja_spacing.dart';

/// Fundo de um [GjaContainer], por papel de cor do tema.
enum GjaSurface {
  /// Sem fundo (transparente).
  none,

  /// Fundo da página (`colors.background`).
  background,

  /// Superfície de conteúdo, como cartões e painéis (`colors.base`).
  base,

  /// Cabeçalhos e barras de grupo (`colors.headerBackground`).
  header,

  /// Barra da aplicação (`colors.shell`).
  shell,
}

/// Raio dos cantos de um [GjaContainer], com os nomes de
/// `GjaRadiusTokens`.
enum GjaRadius {
  /// Cantos retos.
  none,

  /// Passo muito pequeno.
  xs,

  /// Passo pequeno.
  s,

  /// Passo médio.
  m,

  /// Passo grande.
  l,

  /// Passo muito grande.
  xl,

  /// Pílula: cantos máximos.
  full,

  /// Botões (`sapButton_BorderCornerRadius`).
  button,

  /// Campos de entrada (`sapField_BorderCornerRadius`).
  field,

  /// Popovers, menus e listas suspensas (`sapPopover_BorderCornerRadius`).
  popover,

  /// Diálogos e painéis (`sapElement_BorderCornerRadius`).
  element,

  /// Cartões e blocos (`sapTile_BorderCornerRadius`).
  tile,
}

/// Sombra de um [GjaContainer], por papel de `GjaShadowTokens`.
enum GjaShadow {
  /// Sem sombra.
  none,

  /// Cartões e blocos.
  card,

  /// Popovers, menus, listas suspensas e dicas.
  popover,

  /// Diálogos e painéis modais.
  dialog,

  /// Item arrastado.
  dragged,

  /// Cabeçalhos e barras fixas.
  header,
}

/// Superfície do GJA que agrupa conteúdo, como o `backgroundDesign` e os
/// parâmetros de superfície do SAPUI5.
///
/// Cada aspecto é um papel do tema ativo: fundo ([surface]), borda
/// `separator` de 1 px ([border]), cantos ([radius], com recorte do
/// conteúdo), sombra ([shadow], com a cor `shadow`) e espaço interno
/// ([padding], pela densidade). Não há valores literais nem tamanho próprio.
///
/// ```dart
/// const GjaContainer(
///   surface: GjaSurface.base,
///   border: true,
///   radius: GjaRadius.tile,
///   shadow: GjaShadow.card,
///   padding: GjaSpace.l,
///   child: GjaText('Pedido 4711'),
/// )
/// ```
///
/// Para espaço diferente por lado, use `GjaSpacing.padding` dentro do
/// contêiner.
class GjaContainer extends StatelessWidget {
  /// Cria a superfície.
  const GjaContainer({
    this.child,
    this.surface = GjaSurface.none,
    this.border = false,
    this.radius = GjaRadius.none,
    this.shadow = GjaShadow.none,
    this.padding,
    super.key,
  });

  /// Conteúdo.
  final Widget? child;

  /// Fundo.
  final GjaSurface surface;

  /// Se a borda `separator` é desenhada.
  final bool border;

  /// Raio dos cantos; diferente de `none`, recorta o conteúdo.
  final GjaRadius radius;

  /// Papel de sombra.
  final GjaShadow shadow;

  /// Espaço interno em todos os lados; nulo não acrescenta espaço.
  final GjaSpace? padding;

  static Color? _surface(GjaColorTokens c, GjaSurface surface) =>
      switch (surface) {
        GjaSurface.none => null,
        GjaSurface.background => c.background,
        GjaSurface.base => c.base,
        GjaSurface.header => c.headerBackground,
        GjaSurface.shell => c.shell,
      };

  static double _radius(GjaRadiusTokens r, GjaRadius radius) =>
      switch (radius) {
        GjaRadius.none => r.none,
        GjaRadius.xs => r.xs,
        GjaRadius.s => r.s,
        GjaRadius.m => r.m,
        GjaRadius.l => r.l,
        GjaRadius.xl => r.xl,
        GjaRadius.full => r.full,
        GjaRadius.button => r.button,
        GjaRadius.field => r.field,
        GjaRadius.popover => r.popover,
        GjaRadius.element => r.element,
        GjaRadius.tile => r.tile,
      };

  static List<GjaShadowLayer> _shadow(
    GjaShadowTokens e,
    GjaShadow shadow,
  ) => switch (shadow) {
    GjaShadow.none => e.none,
    GjaShadow.card => e.card,
    GjaShadow.popover => e.popover,
    GjaShadow.dialog => e.dialog,
    GjaShadow.dragged => e.dragged,
    GjaShadow.header => e.header,
  };

  @override
  Widget build(BuildContext context) {
    final t = GjaThemeData.of(context);
    final rounded = radius != GjaRadius.none;
    final corners = BorderRadius.circular(_radius(t.radius, radius));

    Widget? content = child;
    final space = padding;
    if (space != null) {
      content = Padding(
        padding: EdgeInsets.all(GjaSpacing.resolve(t.spacing, space)),
        child: content,
      );
    }
    if (rounded && content != null) {
      content = ClipRRect(borderRadius: corners, child: content);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _surface(t.colors, surface),
        border: border ? Border.all(color: t.colors.separator) : null,
        borderRadius: rounded ? corners : null,
        boxShadow: t.shadows.boxShadows(
          _shadow(t.shadows, shadow),
          t.colors.shadow,
        ),
      ),
      child: content,
    );
  }
}

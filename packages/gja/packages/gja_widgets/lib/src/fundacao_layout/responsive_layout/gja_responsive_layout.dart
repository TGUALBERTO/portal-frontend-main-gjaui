import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';

/// De onde [GjaResponsiveLayout] mede a classe de tamanho.
enum GjaLayoutBasis {
  /// Largura máxima disponível para o próprio layout (padrão).
  container,

  /// Classe de tamanho da tela.
  screen,
}

/// Conteúdo diferente por classe de tamanho, como os controles responsivos
/// do SAPUI5.
///
/// Exibe o construtor da classe atual ou, sem ele, o da maior classe menor
/// que tenha construtor; [small] é sempre o último recurso. A classe vem da
/// largura disponível ([GjaLayoutBasis.container], padrão) ou da tela
/// ([GjaLayoutBasis.screen]), com os limiares do tema ativo. Só o
/// conteúdo exibido fica na árvore.
///
/// ```dart
/// GjaResponsiveLayout(
///   small: (context) => const GjaVBox(items: [campoA, campoB]),
///   medium: (context) => const GjaHBox(items: [
///     Expanded(child: campoA),
///     Expanded(child: campoB),
///   ]),
/// )
/// ```
///
/// Ao trocar de classe, o conteúdo é reconstruído com o novo construtor; o
/// estado de widgets que mudam de lugar não é preservado.
class GjaResponsiveLayout extends StatelessWidget {
  /// Cria o layout.
  const GjaResponsiveLayout({
    required this.small,
    this.medium,
    this.large,
    this.extraLarge,
    this.basis = GjaLayoutBasis.container,
    super.key,
  });

  /// Conteúdo da classe `small`, base das demais.
  final WidgetBuilder small;

  /// Conteúdo da classe `medium`, ou nulo para herdar.
  final WidgetBuilder? medium;

  /// Conteúdo da classe `large`, ou nulo para herdar.
  final WidgetBuilder? large;

  /// Conteúdo da classe `extraLarge`, ou nulo para herdar.
  final WidgetBuilder? extraLarge;

  /// De onde a classe de tamanho é medida.
  final GjaLayoutBasis basis;

  @override
  Widget build(BuildContext context) {
    final builders = GjaResponsiveValue<WidgetBuilder>(
      small: small,
      medium: medium,
      large: large,
      extraLarge: extraLarge,
    );
    return switch (basis) {
      GjaLayoutBasis.container => GjaResponsiveBuilder(
        builder: (context, sizeClass) => builders.resolve(sizeClass)(context),
      ),
      GjaLayoutBasis.screen => builders.resolve(
        GjaResponsive.screenSizeClassOf(context),
      )(context),
    };
  }
}

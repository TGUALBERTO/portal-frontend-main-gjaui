import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Linha fina que separa itens e grupos de conteúdo, como o
/// `sap.m.ToolbarSeparator` do SAPUI5.
///
/// [GjaSeparator.new] é horizontal e ocupa a largura disponível.
/// [GjaSeparator.vertical] tem a altura `density.separatorHeight` e fica
/// centrado na altura de quem o contém, sem esticar, como o separador de uma
/// barra. A cor é `colors.separator`, e a espessura é a linha fina padrão, a
/// mesma da borda do `GjaContainer`.
///
/// Como no UI5, não há espaço próprio em volta da linha: ele vem do
/// contêiner, por exemplo o `gap` de um `GjaVBox` ou o espaço entre os
/// itens de um `GjaBar`. É decorativo e fica fora da semântica.
///
/// ```dart
/// const GjaVBox(items: [
///   GjaText('Itens'),
///   GjaSeparator(),
///   GjaText('Total'),
/// ])
/// ```
class GjaSeparator extends StatelessWidget {
  /// Linha horizontal.
  const GjaSeparator({super.key}) : _axis = Axis.horizontal;

  /// Linha vertical, com a altura de separador da densidade.
  const GjaSeparator.vertical({super.key}) : _axis = Axis.vertical;

  final Axis _axis;

  @override
  Widget build(BuildContext context) {
    final t = GjaThemeData.of(context);
    // Linha fina padrão do Flutter (`sapElement_BorderWidth`), a mesma de
    // `Border.all` no `GjaContainer`; não há token semântico de espessura.
    final line = const BorderSide().width;
    final stroke = ColoredBox(color: t.colors.separator);

    final Widget separator = switch (_axis) {
      Axis.horizontal => SizedBox(
        height: line,
        width: double.infinity,
        child: stroke,
      ),
      // O `Center` mantém a altura da densidade mesmo sob altura imposta pelo
      // pai, e encolhe à linha na largura.
      Axis.vertical => Center(
        child: SizedBox(
          width: line,
          height: t.density.separatorHeight,
          child: stroke,
        ),
      ),
    };
    return ExcludeSemantics(child: separator);
  }
}

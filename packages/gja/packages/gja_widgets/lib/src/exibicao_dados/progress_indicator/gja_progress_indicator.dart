import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

import 'gja_progress_view.dart';

/// Indicador de progresso, como o `sap.m.ProgressIndicator` do SAPUI5.
///
/// Uma barra na largura disponível, com a espessura `spacing.xs`, preenchida
/// até [percentValue] (de 0 a 100); chega a cada novo valor em
/// `motion.short`, ou de imediato com movimento reduzido. Para uma operação
/// sem andamento medível, use `GjaBusyIndicator`.
///
/// O preenchimento usa `colors.brand` em [GjaValueState.none] e a cor do
/// estado nos demais ([state]). O leitor de tela anuncia [semanticLabel] (ou
/// o texto `loading`) e o valor em porcentagem.
///
/// ```dart
/// GjaProgressIndicator(percentValue: enviados / total * 100)
/// ```
class GjaProgressIndicator extends StatelessWidget {
  /// Cria a barra com [percentValue].
  const GjaProgressIndicator({
    required this.percentValue,
    this.state = GjaValueState.none,
    this.semanticLabel,
    super.key,
  }) : assert(
         percentValue >= 0 && percentValue <= 100,
         'percentValue deve estar entre 0 e 100: $percentValue',
       );

  /// Andamento, de 0 a 100.
  final double percentValue;

  /// Estado de valor, que define a cor do preenchimento.
  final GjaValueState state;

  /// Rótulo do leitor de tela; nulo usa o texto `loading`.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final localizations = GjaLocalizations.of(context);
    final colors = theme.colors;
    return Semantics(
      container: true,
      label: semanticLabel ?? localizations.loading,
      value: '${localizations.formatInteger(percentValue.round())}%',
      excludeSemantics: true,
      child: GjaProgressView(
        circular: false,
        value: percentValue / 100,
        fill: state == GjaValueState.none
            ? colors.brand
            : colors.stateColors(state).foreground,
        track: colors.separator,
        extent: theme.spacing.xs,
      ),
    );
  }
}

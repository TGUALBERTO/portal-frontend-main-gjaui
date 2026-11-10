import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Contador, como o badge dos controles (`BadgeEnabler`) e o `count` do
/// `IconTabFilter` do SAPUI5.
///
/// Mostra [count] numa pílula com as cores do [state] (padrão `error`, a cor
/// de destaque dos badges Fiori). Acima de [max], mostra `<max>+`; abaixo de
/// 1, não aparece. Sem [child], o contador aparece sozinho; com ele, fica
/// centrado no canto superior final do [child], sem mudar o tamanho dele nem
/// receber toques. O leitor de tela anuncia [semanticLabel] ou o número; sobre
/// o [child], no mesmo nó dele, depois do rótulo dele.
///
/// ```dart
/// GjaBadge(
///   count: naoLidas,
///   semanticLabel: '$naoLidas notificações',
///   child: GjaButton(
///     icon: GjaIcons.bell,
///     tooltip: 'Notificações',
///     type: GjaButtonType.transparent,
///     onPress: abrir,
///   ),
/// )
/// ```
class GjaBadge extends StatelessWidget {
  /// Cria o contador de [count].
  const GjaBadge({
    required this.count,
    this.max = 999,
    this.state = GjaValueState.error,
    this.child,
    this.semanticLabel,
    super.key,
  }) : assert(max >= 1, 'max deve ser ao menos 1: $max');

  /// Valor do contador; abaixo de 1, o contador não aparece.
  final int count;

  /// Maior valor mostrado; acima dele, aparece `<max>+`.
  final int max;

  /// Estado de valor, que define as cores.
  final GjaValueState state;

  /// Elemento sobre o qual o contador aparece; nulo mostra só o contador.
  final Widget? child;

  /// Rótulo do leitor de tela; nulo usa o número exibido.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final child = this.child;
    if (count < 1) return child ?? const SizedBox.shrink();

    final theme = GjaThemeData.of(context);
    final localizations = GjaLocalizations.of(context);
    final text = count > max
        ? '${localizations.formatInteger(max)}+'
        : localizations.formatInteger(count);
    final colors = theme.colors.stateColors(state);
    // Lado mínimo: a altura da linha do texto (na escala atual), nunca menor
    // que `icons.small`, para que um dígito forme um círculo.
    final label = theme.typography.small;
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(label.fontSize!) *
        (label.height ?? 1);
    final side = lineHeight > theme.icons.small
        ? lineHeight
        : theme.icons.small;
    final pill = ExcludeSemantics(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: side, minHeight: side),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.background,
            // Linha fina padrão do framework, como no GjaContainer.
            border: Border.all(
              color: colors.border,
              width: const BorderSide().width,
            ),
            borderRadius: BorderRadius.circular(theme.radius.full),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.spacing.xs),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              // Tamanho `small`, que os controles de texto não oferecem; a
              // change do selo revê o contador no modelo do SAPUI5.
              child: Text(
                text,
                style: label.copyWith(
                  // Sem estado, o contador usa a cor de texto do tema.
                  color: state == GjaValueState.none
                      ? theme.colors.text
                      : colors.foreground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
    final announced = semanticLabel ?? text;

    if (child == null) return Semantics(label: announced, child: pill);

    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Um só nó: o rótulo do elemento e, depois, o do contador.
    return MergeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          // Nó próprio depois do elemento, para ser anunciado depois dele.
          Semantics(container: true, label: announced),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: IgnorePointer(
              // Metade da pílula para fora, com o centro no canto.
              child: FractionalTranslation(
                translation: Offset(rtl ? -0.5 : 0.5, -0.5),
                child: pill,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

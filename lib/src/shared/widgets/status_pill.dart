import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart'
    show GjaThemeData, GjaValueState, GjaValueStateColors;

/// Tom semântico de um badge de status.
enum BadgeTone { neutral, info, success, warning, error }

/// Estado de valor do GJA equivalente a cada [BadgeTone].
GjaValueState badgeToneState(BadgeTone tone) => switch (tone) {
      BadgeTone.neutral => GjaValueState.none,
      BadgeTone.info => GjaValueState.information,
      BadgeTone.success => GjaValueState.success,
      BadgeTone.warning => GjaValueState.warning,
      BadgeTone.error => GjaValueState.error,
    };

GjaValueStateColors _toneColors(BuildContext context, BadgeTone tone) =>
    GjaThemeData.of(context).colors.stateColors(badgeToneState(tone));

/// Resolve as cores (fundo, texto) de um [BadgeTone]: as do estado de valor
/// do GJA.
(Color, Color) badgeToneColors(BuildContext context, BadgeTone tone) {
  final c = _toneColors(context, tone);
  return (c.background, c.foreground);
}

/// Etiqueta de status reutilizável.
///
/// Segue o desenho do `GjaObjectStatus` invertido: fundo, borda fina e
/// texto nas cores do estado, com o raio `radius.s` do GJA. O próprio
/// `GjaObjectStatus` não é usado porque as telas precisam de cores avulsas
/// (ex.: a versão da ATA) e de um spinner à esquerda, que ele não aceita.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.border,
    this.leading,
  });

  /// Constrói a partir de um [BadgeTone], opcionalmente com spinner.
  factory StatusPill.tone(
    BuildContext context, {
    required String label,
    required BadgeTone tone,
    bool spinner = false,
  }) {
    final c = _toneColors(context, tone);
    return StatusPill(
      label: label,
      background: c.background,
      foreground: c.foreground,
      border: c.border,
      leading: spinner
          ? SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.foreground,
              ),
            )
          : null,
    );
  }

  final String label;
  final Color background;
  final Color foreground;

  /// Cor da borda; nula usa o [foreground] translúcido, que fica entre o
  /// fundo e o texto como as bordas dos estados do GJA.
  final Color? border;

  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    // Dimensões FIXAS (sem .sp/.r): com screenutil a etiqueta inflava em
    // monitores grandes e ficava desproporcional nas tabelas.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
          color: border ?? foreground.withValues(alpha: 0.4),
          // Linha fina padrão, como no GjaObjectStatus.
          width: const BorderSide().width,
        ),
        borderRadius: BorderRadius.circular(theme.radius.s),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.xs + theme.spacing.xxs,
          vertical: theme.spacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: theme.spacing.xs),
            ],
            Text(
              label,
              style: theme.typography.small.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

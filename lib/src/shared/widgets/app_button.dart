import 'package:gja_ui/gja_ui.dart' show GjaButton, GjaButtonType;

import '../../imports/imports.dart';

/// A fully themed button supporting all [ButtonVariant]s and [ButtonSize]s.
///
/// Desenhado pelo [GjaButton] (design system GJA, `packages/gja`) nas
/// variantes `primary` (emphasized), `outline` (standard), `danger` (reject) e
/// `success` (accept). Os casos que o GJA não cobre — as variantes
/// `secondary` e `ghost`, cor customizada ([color]/[textColor]), ícone à
/// direita ([suffixIcon]) ou ícone à esquerda que não seja um [Icon] — usam o
/// desenho Material, com as cores, o raio e a fonte do GJA.
///
/// Usage:
/// ```dart
/// AppButton(
///   label: 'Save',
///   onPressed: _save,
///   variant: ButtonVariant.primary,
///   size: ButtonSize.large,
///   isLoading: state.isLoading,
/// )
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.color,
    this.textColor,
    this.height = ButtonSize.medium,
    this.width,
    this.isLoading = false,
    this.isFullWidth = false,
    this.prefixIcon,
    this.suffixIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final Color? color;
  final Color? textColor;
  final ButtonSize height;
  final ButtonSize? width;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  // Dimensões FIXAS (sem .h/.w/.sp), pelo mesmo motivo do [StatusPill]: a
  // TextTheme do app não passa pelo ScreenUtil, então só o botão crescia — em
  // janela estreita e alta o "Salvar" chegava a ~70 px de altura com rótulo de
  // 20 ao lado de um formulário de 16. Os valores são os do Material (48 dp de
  // alvo de toque, rótulo 14), iguais ao design de 360 dp.
  double get _buttonHeight => switch (height) {
        ButtonSize.small => 36.0,
        ButtonSize.medium => 48.0,
        ButtonSize.large => 56.0,
      };

  double? get _buttonWidth => switch (width) {
        ButtonSize.small => 100.0,
        ButtonSize.medium => 150.0,
        ButtonSize.large => 200.0,
        null => null,
      };

  /// Variante do portal → tipo do `sap.m.Button` no GJA, ou nulo quando o
  /// GJA não tem um equivalente visual.
  ///
  /// `secondary` (preenchido em tom suave) e `ghost` (fundo neutro sutil) não
  /// existem no GJA: o `standard` é contornado — já usado por `outline` — e
  /// o `transparent` não tem fundo nem borda, o que deixa o botão parecendo
  /// texto solto no conteúdo. Esses dois usam o desenho Material abaixo, com
  /// as cores, o raio e a fonte do GJA.
  GjaButtonType? get _gjaType => switch (variant) {
        ButtonVariant.primary => GjaButtonType.emphasized,
        ButtonVariant.outline => GjaButtonType.standard,
        ButtonVariant.danger => GjaButtonType.reject,
        ButtonVariant.success => GjaButtonType.accept,
        ButtonVariant.secondary || ButtonVariant.ghost => null,
      };

  /// O GJA recebe só um [IconData] à esquerda e não aceita cores avulsas.
  bool get _usesGja =>
      _gjaType != null &&
      color == null &&
      textColor == null &&
      suffixIcon == null &&
      (prefixIcon == null || (prefixIcon is Icon && (prefixIcon! as Icon).icon != null));

  @override
  Widget build(BuildContext context) {
    if (!_usesGja) return _buildMaterial(context);

    return SizedBox(
      width: isFullWidth ? double.infinity : _buttonWidth,
      height: _buttonHeight,
      child: GjaButton(
        text: label,
        icon: (prefixIcon as Icon?)?.icon,
        type: _gjaType!,
        enabled: onPressed != null,
        busy: isLoading,
        onPress: onPressed,
      ),
    );
  }

  /// Implementação Material anterior, para os casos fora do GJA.
  Widget _buildMaterial(BuildContext context) {
    final cs = context.theme.colorScheme;
    final appColors = context.theme.extension<AppColorsExtension>()!;
    final isDisabled = onPressed == null || isLoading;

    final horizontalPadding = switch (height) {
      ButtonSize.small => 12.0,
      ButtonSize.medium => 20.0,
      ButtonSize.large => 28.0,
    };

    final fontSize = switch (height) {
      ButtonSize.small => 12.0,
      ButtonSize.medium => 14.0,
      ButtonSize.large => 16.0,
    };

    final (bg, fg, border) = switch (variant) {
      ButtonVariant.primary => (
          color ?? cs.primary,
          color ?? cs.onPrimary,
          null
        ),
      // Tom suave da marca (primaryContainer = brand com alfa baixo).
      ButtonVariant.secondary => (cs.primaryContainer, cs.primary, null),
      ButtonVariant.outline => (
          Colors.transparent,
          cs.primary,
          BorderSide(color: cs.outline)
        ),
      // Fundo neutro sutil (headerBackground/hoverBackground do GJA), para
      // não parecer texto solto.
      ButtonVariant.ghost => (cs.surfaceContainerHigh, cs.primary, null),
      ButtonVariant.danger => (cs.error, cs.onError, null),
      ButtonVariant.success => (appColors.success, appColors.onSuccess, null),
    };

    final child = AnimatedSwitcher(
      duration: AppDurations.fast,
      switchInCurve: AppCurves.decelerate,
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loader'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: fg,
              ),
            )
          : Row(
              key: const ValueKey('content'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (prefixIcon != null) ...[
                  prefixIcon!,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: isDisabled
                          ? fg.withValues(alpha: 0.5)
                          : textColor ?? fg,
                    ),
                  ),
                ),
                if (suffixIcon != null) ...[
                  const SizedBox(width: 8),
                  suffixIcon!,
                ],
              ],
            ),
    );

    return AnimatedOpacity(
      duration: AppDurations.fast,
      opacity: isDisabled ? 0.6 : 1.0,
      child: SizedBox(
        width: isFullWidth ? double.infinity : _buttonWidth,
        height: _buttonHeight,
        child: TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            shape: border != null
                ? RoundedRectangleBorder(
                    borderRadius: AppBorders.button,
                    side: border,
                  )
                : const RoundedRectangleBorder(borderRadius: AppBorders.button),
          ),
          child: child,
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext, MediaQuery;

import '../accessibility/accessibility.dart';
import '../accessibility/animation_mode.dart';
import '../breakpoints/breakpoint_tokens.dart';
import '../color/color_tokens.dart';
import '../color/contrast_check.dart';
import '../density/density_tokens.dart';
import '../shadows/shadow_tokens.dart';
import '../iconography/icon_tokens.dart';
import '../interaction_states/interaction_state_tokens.dart';
import '../interaction_states/state_contrast_check.dart';
import '../radius/radius_tokens.dart';
import '../spacing/spacing_tokens.dart';
import '../tokens/lerp.dart';
import '../tokens/motion_tokens.dart';
import '../tokens/token_extensions.dart';
import '../tokens/token_set.dart';
import '../typography/typography_tokens.dart';
import 'theme_scope.dart';

/// Tema centralizado do GJA: todos os fundamentos em um único objeto.
///
/// Nível: semântico.
///
/// Use [GjaThemeData.light] ou [GjaThemeData.dark] e personalize com
/// [copyWith]; confira a personalização com [accessibilityIssues]. Os tokens
/// de componente dos widgets ficam em [components] (o widget usa os padrões
/// derivados dos semânticos quando o tipo não está registrado) e os tokens da
/// aplicação, em [extensions]. O espaçamento vem sempre da [density].
@immutable
class GjaThemeData extends GjaTokenSet<GjaThemeData> {
  /// Cria um tema com todos os conjuntos.
  const GjaThemeData({
    required this.brightness,
    required this.colors,
    required this.typography,
    required this.density,
    required this.radius,
    required this.shadows,
    required this.motion,
    required this.icons,
    required this.interaction,
    required this.breakpoints,
    this.animationMode = GjaAnimationMode.full,
    this.components = const GjaTokenExtensions.empty(),
    this.extensions = const GjaTokenExtensions.empty(),
  });

  /// Tema claro de referência, na densidade [density].
  factory GjaThemeData.light({
    GjaDensity density = GjaDensity.cozy,
  }) => GjaThemeData._reference(
    Brightness.light,
    const GjaColorTokens.light(),
    density,
  );

  /// Tema escuro de referência, na densidade [density].
  factory GjaThemeData.dark({
    GjaDensity density = GjaDensity.cozy,
  }) => GjaThemeData._reference(
    Brightness.dark,
    const GjaColorTokens.dark(),
    density,
  );

  factory GjaThemeData._reference(
    Brightness brightness,
    GjaColorTokens colors,
    GjaDensity density,
  ) => GjaThemeData(
    brightness: brightness,
    colors: colors,
    typography: const GjaTypographyTokens.fallback(),
    density: GjaDensityTokens.of(density),
    radius: const GjaRadiusTokens.fallback(),
    shadows: const GjaShadowTokens.fallback(),
    motion: const GjaMotionTokens.fallback(),
    icons: const GjaIconTokens.fallback(),
    interaction: const GjaInteractionStateTokens.fallback(),
    breakpoints: const GjaBreakpointTokens.fallback(),
  );

  /// Claro ou escuro; deve corresponder às [colors].
  final Brightness brightness;

  /// Papéis de cor.
  final GjaColorTokens colors;

  /// Estilos de texto.
  final GjaTypographyTokens typography;

  /// Densidade, com dimensões de controle e espaçamento.
  final GjaDensityTokens density;

  /// Raios de borda.
  final GjaRadiusTokens radius;

  /// Sombras e papéis de sombra.
  final GjaShadowTokens shadows;

  /// Durações e curvas de animação.
  final GjaMotionTokens motion;

  /// Tamanhos de ícone.
  final GjaIconTokens icons;

  /// Estados visuais de interação.
  final GjaInteractionStateTokens interaction;

  /// Limiares de largura.
  final GjaBreakpointTokens breakpoints;

  /// Modo de animação pedido pela aplicação (`sap-ui-animation-mode`).
  ///
  /// No tema resolvido ([resolve], [of]), é o modo efetivo, que também
  /// considera o pedido da plataforma.
  final GjaAnimationMode animationMode;

  /// Tokens de componente dos widgets do framework, por tipo.
  final GjaTokenExtensions components;

  /// Tokens próprios da aplicação, por tipo.
  final GjaTokenExtensions extensions;

  /// Espaçamento da densidade ativa.
  GjaSpacingTokens get spacing => density.spacing;

  /// Este tema com a densidade de referência de [mode].
  GjaThemeData withDensity(GjaDensity mode) =>
      copyWith(density: GjaDensityTokens.of(mode));

  /// Este tema resolvido para a plataforma.
  ///
  /// O modo efetivo é [animationMode] ou, com [disableAnimations], `none`
  /// ([GjaAnimationMode.effective]). O resultado tem esse modo e o
  /// movimento resolvido para ele; com o mesmo modo e sem redução, é este
  /// tema.
  GjaThemeData resolve({required bool disableAnimations}) {
    final mode = animationMode.effective(disableAnimations: disableAnimations);
    if (mode == animationMode && !mode.reducesMotion) return this;
    return copyWith(
      animationMode: mode,
      motion: GjaAccessibility.resolveMotion(motion, mode: mode),
    );
  }

  /// Tema ativo de [context]: o do `GjaThemeScope` mais próximo ou, sem
  /// escopo, o tema claro de referência.
  ///
  /// O tema vem resolvido para a plataforma ([resolve]) com
  /// `MediaQuery.disableAnimations`: com movimento reduzido, pelo tema ou pelo
  /// sistema, as durações valem zero. Quem chama é reconstruído quando o tema
  /// do escopo muda.
  static GjaThemeData of(BuildContext context) {
    final data = maybeOf(context) ?? _fallback;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return data.resolve(disableAnimations: reduce);
  }

  /// Tema do `GjaThemeScope` mais próximo, sem resolução de movimento, ou
  /// nulo sem escopo.
  static GjaThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GjaThemeScope>()?.data;

  // Uma única instância, para que leituras sem escopo sejam idênticas.
  static final _fallback = GjaThemeData.light();

  /// Problemas de acessibilidade deste tema: pares de contraste abaixo do
  /// mínimo (papéis de cor e estados das famílias de controle) e alvo de interação abaixo de
  /// [GjaAccessibility.minTargetSizeFloor]. Lista vazia significa conforme.
  List<String> accessibilityIssues() {
    return [
      for (final issue in [
        ...gjaCheckContrast(colors),
        ...gjaCheckStateContrast(colors),
      ])
        '${issue.foreground}/${issue.background}: '
            '${issue.ratio.toStringAsFixed(2)} < ${issue.minimum}',
      if (density.minTargetSize < GjaAccessibility.minTargetSizeFloor)
        'minTargetSize: ${density.minTargetSize} < '
            '${GjaAccessibility.minTargetSizeFloor}',
    ];
  }

  @override
  GjaThemeData copyWith({
    Brightness? brightness,
    GjaColorTokens? colors,
    GjaTypographyTokens? typography,
    GjaDensityTokens? density,
    GjaRadiusTokens? radius,
    GjaShadowTokens? shadows,
    GjaMotionTokens? motion,
    GjaIconTokens? icons,
    GjaInteractionStateTokens? interaction,
    GjaBreakpointTokens? breakpoints,
    GjaAnimationMode? animationMode,
    GjaTokenExtensions? components,
    GjaTokenExtensions? extensions,
  }) {
    return GjaThemeData(
      brightness: brightness ?? this.brightness,
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      density: density ?? this.density,
      radius: radius ?? this.radius,
      shadows: shadows ?? this.shadows,
      motion: motion ?? this.motion,
      icons: icons ?? this.icons,
      interaction: interaction ?? this.interaction,
      breakpoints: breakpoints ?? this.breakpoints,
      animationMode: animationMode ?? this.animationMode,
      components: components ?? this.components,
      extensions: extensions ?? this.extensions,
    );
  }

  @override
  GjaThemeData lerp(GjaThemeData? other, double t) {
    if (other == null || t == 0) return this;
    // Nos extremos o resultado é exatamente o destino: as coleções mantêm
    // extensões presentes em só um dos lados, o que quebraria lerp(b, 1) == b.
    if (t == 1) return other;
    return GjaThemeData(
      brightness: lerpDiscrete(brightness, other.brightness, t),
      colors: colors.lerp(other.colors, t),
      typography: typography.lerp(other.typography, t),
      density: density.lerp(other.density, t),
      radius: radius.lerp(other.radius, t),
      shadows: shadows.lerp(other.shadows, t),
      motion: motion.lerp(other.motion, t),
      icons: icons.lerp(other.icons, t),
      interaction: interaction.lerp(other.interaction, t),
      breakpoints: breakpoints.lerp(other.breakpoints, t),
      animationMode: lerpDiscrete(animationMode, other.animationMode, t),
      components: components.lerp(other.components, t),
      extensions: extensions.lerp(other.extensions, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GjaThemeData &&
        other.brightness == brightness &&
        other.colors == colors &&
        other.typography == typography &&
        other.density == density &&
        other.radius == radius &&
        other.shadows == shadows &&
        other.motion == motion &&
        other.icons == icons &&
        other.interaction == interaction &&
        other.breakpoints == breakpoints &&
        other.animationMode == animationMode &&
        other.components == components &&
        other.extensions == extensions;
  }

  @override
  int get hashCode => Object.hash(
    brightness,
    colors,
    typography,
    density,
    radius,
    shadows,
    motion,
    icons,
    interaction,
    breakpoints,
    animationMode,
    components,
    extensions,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Brightness>('brightness', brightness))
      ..add(DiagnosticsProperty<GjaColorTokens>('colors', colors))
      ..add(
        DiagnosticsProperty<GjaTypographyTokens>('typography', typography),
      )
      ..add(DiagnosticsProperty<GjaDensityTokens>('density', density))
      ..add(DiagnosticsProperty<GjaRadiusTokens>('radius', radius))
      ..add(DiagnosticsProperty<GjaShadowTokens>('shadows', shadows))
      ..add(DiagnosticsProperty<GjaMotionTokens>('motion', motion))
      ..add(DiagnosticsProperty<GjaIconTokens>('icons', icons))
      ..add(
        DiagnosticsProperty<GjaInteractionStateTokens>(
          'interaction',
          interaction,
        ),
      )
      ..add(
        DiagnosticsProperty<GjaBreakpointTokens>('breakpoints', breakpoints),
      )
      ..add(EnumProperty<GjaAnimationMode>('animationMode', animationMode))
      ..add(DiagnosticsProperty<GjaTokenExtensions>('components', components))
      ..add(
        DiagnosticsProperty<GjaTokenExtensions>('extensions', extensions),
      );
  }
}

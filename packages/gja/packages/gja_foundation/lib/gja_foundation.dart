/// Fundamentos do framework GJA: design tokens, tema, breakpoints,
/// densidade e estados semânticos.
///
/// Camada base: não depende de nenhum outro pacote GJA. Os primitivos
/// ficam em `package:gja_foundation/gja_primitives.dart`, que esta
/// biblioteca não reexporta.
library;

export 'src/tokens/token_set.dart';
export 'src/tokens/motion_tokens.dart';
export 'src/tokens/token_extensions.dart';
export 'src/color/contrast.dart';
export 'src/color/value_state.dart';
export 'src/color/color_tokens.dart';
export 'src/color/contrast_check.dart';
export 'src/spacing/spacing_tokens.dart';
export 'src/typography/typography_tokens.dart';
export 'src/radius/radius_tokens.dart';
export 'src/breakpoints/breakpoint_tokens.dart';
export 'src/breakpoints/size_class.dart';
export 'src/iconography/icons.dart';
export 'src/iconography/icon_tokens.dart';
export 'src/density/density_tokens.dart';
export 'src/shadows/shadow_layer.dart';
export 'src/shadows/shadow_tokens.dart';
export 'src/interaction_states/interaction_state.dart';
export 'src/interaction_states/control_colors.dart';
export 'src/interaction_states/interaction_state_tokens.dart';
export 'src/interaction_states/state_contrast_check.dart';
export 'src/accessibility/accessibility.dart';
export 'src/accessibility/animation_mode.dart';
export 'src/theming/theme_data.dart';
export 'src/theming/theme_scope.dart';

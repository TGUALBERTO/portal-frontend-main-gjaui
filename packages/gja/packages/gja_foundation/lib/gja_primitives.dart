/// Primitivos de design tokens do GJA: escalas de valores brutos.
///
/// Destinada a temas e aplicações que personalizam a identidade visual. Não
/// é reexportada por `gja_foundation.dart` nem por `gja_ui.dart`, e as
/// bibliotecas de `gja_core` e `gja_widgets` não podem importá-la
/// (verificado por `gja_checks architecture`).
library;

export 'src/tokens/primitives/motion_primitives.dart';
export 'src/color/primitives/color_primitives.dart';
export 'src/spacing/primitives/spacing_primitives.dart';
export 'src/density/primitives/density_primitives.dart';
export 'src/typography/primitives/typography_primitives.dart';
export 'src/radius/primitives/radius_primitives.dart';
export 'src/breakpoints/primitives/breakpoint_primitives.dart';
export 'src/iconography/primitives/icon_primitives.dart';
export 'src/shadows/primitives/shadow_primitives.dart';
export 'src/interaction_states/primitives/interaction_primitives.dart';

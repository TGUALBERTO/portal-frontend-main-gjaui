import 'package:gja_foundation/gja_foundation.dart';

import 'gja_button.dart';

/// Família de controle de cada [GjaButtonType], interna ao pacote (não
/// exportada), compartilhada pelos formatos do `GjaButton`.
GjaControlFamily gjaButtonFamily(GjaButtonType type) => switch (type) {
  GjaButtonType.standard => GjaControlFamily.standard,
  GjaButtonType.emphasized => GjaControlFamily.emphasized,
  GjaButtonType.transparent => GjaControlFamily.transparent,
  GjaButtonType.accept => GjaControlFamily.accept,
  GjaButtonType.reject => GjaControlFamily.reject,
  GjaButtonType.attention => GjaControlFamily.attention,
};

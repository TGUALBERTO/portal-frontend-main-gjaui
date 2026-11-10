import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_widgets/gja_widgets.dart';

import 'fonts.dart';

/// Temas e densidades dos goldens: claro e escuro em cada densidade.
final goldenThemes = <(String, GjaThemeData)>[
  for (final (name, base) in [
    ('light', GjaThemeData.light()),
    ('dark', GjaThemeData.dark()),
  ])
    for (final density in GjaDensity.values)
      ('${name}_${density.name}', base.withDensity(density)),
];

/// Renderiza [child] sob [theme], sobre a superfície [surface] (padrão
/// `base`) com espaço interno `l`, numa área de [size] e `devicePixelRatio` 1,
/// e compara com `goldens/<name>.png`.
///
/// Os goldens têm a etiqueta `golden` e referência gerada no Windows
/// (ADR 0008). Para atualizar: `flutter test --update-goldens --tags golden`.
Future<void> expectGolden(
  WidgetTester tester, {
  required String name,
  required GjaThemeData theme,
  required Widget child,
  Size size = const Size(480, 640),
  GjaSurface surface = GjaSurface.base,
}) async {
  await loadGjaFonts();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GjaTheme(
      data: theme,
      duration: Duration.zero,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: const Key('golden'),
          child: SizedBox.expand(
            child: GjaContainer(
              surface: surface,
              padding: GjaSpace.l,
              child: Align(alignment: Alignment.topLeft, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await expectLater(
    find.byKey(const Key('golden')),
    matchesGoldenFile('goldens/$name.png'),
  );
}

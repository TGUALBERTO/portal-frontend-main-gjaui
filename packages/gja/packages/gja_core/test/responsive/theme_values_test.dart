import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

void main() {
  testWidgets('Limiares do tema ativo — Tema com limiares próprios', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 600);
    addTearDown(tester.view.reset);
    final base = GjaThemeData.light();
    final theme = base.copyWith(
      breakpoints: base.breakpoints.copyWith(medium: 480),
    );
    late GjaSizeClass screen;
    late GjaSizeClass scoped;
    late GjaSizeClass panel;
    await tester.pumpWidget(
      GjaThemeScope(
        data: theme,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              screen = GjaResponsive.screenSizeClassOf(context);
              return GjaScreenSizeScope(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 500,
                    child: GjaResponsiveBuilder(
                      builder: (context, sizeClass) {
                        scoped = GjaResponsive.screenSizeClassOf(context);
                        panel = sizeClass;
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    expect(screen, GjaSizeClass.medium);
    expect(scoped, GjaSizeClass.medium);
    expect(panel, GjaSizeClass.medium);
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Superfície tocável de [side] × [side] com rótulo semântico.
Widget _target(double side) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: Semantics(
      button: true,
      label: 'alvo',
      child: GestureDetector(
        onTap: () {},
        child: SizedBox.square(dimension: side),
      ),
    ),
  ),
);

AccessibilityGuideline _targetGuideline(GjaDensityTokens density) =>
    MinimumTapTargetGuideline(
      size: Size.square(GjaAccessibility.minTargetSize(density)),
      link: GjaAccessibility.targetSizeLink,
    );

void main() {
  test('Meta de conformidade — Limites declarados', () {
    expect(GjaAccessibility.conformanceTarget, 'WCAG 2.2 AA');
    expect(GjaAccessibility.minTextContrast, 4.5);
    expect(GjaAccessibility.minNonTextContrast, 3);
    expect(GjaAccessibility.minSupportedTextScale, 2.0);
    expect(GjaAccessibility.minTargetSizeFloor, 24);
  });

  test(
    'Contraste pelos papéis de cor — Mesmos mínimos do fundamento de cor',
    () {
      expect(GjaAccessibility.minTextContrast, gjaTextContrastMinimum);
      expect(
        GjaAccessibility.minNonTextContrast,
        gjaNonTextContrastMinimum,
      );
      for (final colors in const [
        GjaColorTokens.light(),
        GjaColorTokens.dark(),
      ]) {
        expect(gjaCheckContrast(colors), isEmpty);
      }
    },
  );

  test('alvo mínimo padrão é o da densidade confortável de referência', () {
    expect(
      GjaAccessibility.defaultMinTargetSize,
      const GjaDensityTokens.cozy().minTargetSize,
    );
  });

  test('Alvo mínimo de interação por densidade — Alvo por densidade', () {
    expect(
      GjaAccessibility.minTargetSize(const GjaDensityTokens.cozy()),
      44,
    );
    expect(
      GjaAccessibility.minTargetSize(const GjaDensityTokens.compact()),
      32,
    );
  });

  group('Movimento reduzido', () {
    const motion = GjaMotionTokens.fallback();

    test('Movimento reduzido — Animações desativadas', () {
      for (final mode in [
        GjaAnimationMode.minimal,
        GjaAnimationMode.none,
      ]) {
        final reduced = GjaAccessibility.resolveMotion(motion, mode: mode);
        for (final d in [
          reduced.instant,
          reduced.short,
          reduced.medium,
          reduced.long,
        ]) {
          expect(d, Duration.zero, reason: mode.name);
        }
        expect(reduced.standard, motion.standard, reason: mode.name);
        expect(reduced.enter, motion.enter, reason: mode.name);
        expect(reduced.exit, motion.exit, reason: mode.name);
      }
    });

    test('Movimento reduzido — Animações ativas', () {
      for (final mode in [GjaAnimationMode.full, GjaAnimationMode.basic]) {
        expect(
          GjaAccessibility.resolveMotion(motion, mode: mode),
          same(motion),
          reason: mode.name,
        );
      }
    });

    test('Movimento reduzido — Modo efetivo', () {
      expect(GjaAnimationMode.values.map((m) => m.name), [
        'full',
        'basic',
        'minimal',
        'none',
      ]);
      for (final mode in GjaAnimationMode.values) {
        expect(mode.effective(disableAnimations: false), mode);
        expect(
          mode.effective(disableAnimations: true),
          GjaAnimationMode.none,
        );
      }
      expect(
        [for (final m in GjaAnimationMode.values) m.reducesMotion],
        [false, false, true, true],
      );
    });
  });

  testWidgets(
    'Bateria mínima de testes de acessibilidade — Diretriz de alvo pela densidade',
    (tester) async {
      final handle = tester.ensureSemantics();
      final densities = [
        const GjaDensityTokens.cozy(),
        const GjaDensityTokens.compact(),
      ];

      await tester.pumpWidget(_target(48));
      for (final density in densities) {
        await expectLater(
          tester,
          meetsGuideline(_targetGuideline(density)),
          reason: density.density.name,
        );
      }

      await tester.pumpWidget(_target(20));
      for (final density in densities) {
        final result = await _targetGuideline(density).evaluate(tester);
        expect(result.passed, isFalse, reason: density.density.name);
      }
      handle.dispose();
    },
  );
}

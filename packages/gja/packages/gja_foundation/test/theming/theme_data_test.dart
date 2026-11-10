import 'dart:ui' show Brightness, Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_foundation/gja_primitives.dart';

import '../support/token_set_contract.dart';

/// Tokens de componente de teste.
@immutable
class _ButtonTestTokens extends GjaTokenExtension<_ButtonTestTokens> {
  const _ButtonTestTokens(this.minWidth);

  final double minWidth;

  @override
  _ButtonTestTokens copyWith({double? minWidth}) =>
      _ButtonTestTokens(minWidth ?? this.minWidth);

  @override
  _ButtonTestTokens lerp(_ButtonTestTokens? other, double t) => other == null
      ? this
      : _ButtonTestTokens(minWidth + (other.minWidth - minWidth) * t);

  @override
  bool operator ==(Object other) =>
      other is _ButtonTestTokens && other.minWidth == minWidth;

  @override
  int get hashCode => minWidth.hashCode;
}

@immutable
class _AbsentTokens extends GjaTokenExtension<_AbsentTokens> {
  const _AbsentTokens();

  @override
  _AbsentTokens copyWith() => this;

  @override
  _AbsentTokens lerp(_AbsentTokens? other, double t) => this;
}

/// Tema com cada conjunto, exceto as cores e o brilho, comparável ao outro.
Map<String, Object> _nonColorSets(GjaThemeData t) => {
  'typography': t.typography,
  'density': t.density,
  'radius': t.radius,
  'shadows': t.shadows,
  'motion': t.motion,
  'icons': t.icons,
  'interaction': t.interaction,
  'breakpoints': t.breakpoints,
  'animationMode': t.animationMode,
  'components': t.components,
  'extensions': t.extensions,
};

void main() {
  final light = GjaThemeData.light();
  final dark = GjaThemeData.dark();

  test('Tema centralizado — Tema completo', () {
    expect(light.brightness, Brightness.light);
    expect(light.colors, const GjaColorTokens.light());
    expect(light.typography, const GjaTypographyTokens.fallback());
    expect(light.density, const GjaDensityTokens.cozy());
    expect(light.spacing, light.density.spacing);
    expect(light.radius, const GjaRadiusTokens.fallback());
    expect(light.shadows, const GjaShadowTokens.fallback());
    expect(light.motion, const GjaMotionTokens.fallback());
    expect(light.icons, const GjaIconTokens.fallback());
    expect(light.interaction, const GjaInteractionStateTokens.fallback());
    expect(light.breakpoints, const GjaBreakpointTokens.fallback());
    expect(light.animationMode, GjaAnimationMode.full);
  });

  group('Temas de referência claro e escuro', () {
    test(
      'Temas de referência claro e escuro — Claro e escuro diferem só na cor',
      () {
        expect(dark.brightness, Brightness.dark);
        expect(dark.colors, const GjaColorTokens.dark());
        expect(light.colors, isNot(dark.colors));
        expect(_nonColorSets(light), _nonColorSets(dark));
      },
    );

    test('Temas de referência claro e escuro — Densidade no tema', () {
      final compact = GjaThemeData.light(density: GjaDensity.compact);
      expect(compact.density, const GjaDensityTokens.compact());
      expect(compact.spacing, const GjaDensityTokens.compact().spacing);
      expect(compact.copyWith(density: light.density), light);
    });

    test('Temas de referência claro e escuro — Densidade padrão', () {
      expect(GjaThemeData.light().density.density, GjaDensity.cozy);
      expect(GjaThemeData.dark().density.density, GjaDensity.cozy);
    });
  });

  test('Troca de densidade — Tema compacto a partir do confortável', () {
    expect(
      light.withDensity(GjaDensity.compact),
      GjaThemeData.light(density: GjaDensity.compact),
    );
  });

  group('Personalização controlada', () {
    test('Personalização controlada — Tema de marca válido', () {
      final brand = light.copyWith(
        colors: light.colors.copyWith(brand: GjaColorPrimitives.blue800),
      );
      expect(brand.accessibilityIssues(), isEmpty);
      expect(brand.colors, light.colors.copyWith(brand: brand.colors.brand));
      expect(brand.colors.brand, isNot(light.colors.brand));
      expect(brand.copyWith(colors: light.colors), light);
      expect(light.accessibilityIssues(), isEmpty);
      expect(dark.accessibilityIssues(), isEmpty);
    });

    test('Personalização controlada — Tema de marca inválido', () {
      final broken = light.copyWith(
        colors: light.colors.copyWith(contrastText: light.colors.brand),
      );
      expect(
        broken.accessibilityIssues(),
        contains('contrastText/brand: 1.00 < 4.5'),
      );
    });
  });

  void expectZeroDurations(GjaMotionTokens motion) {
    for (final d in [
      motion.instant,
      motion.short,
      motion.medium,
      motion.long,
    ]) {
      expect(d, Duration.zero);
    }
  }

  test('Movimento reduzido no tema — Tema resolvido com redução', () {
    final resolved = light.resolve(disableAnimations: true);
    expect(resolved.animationMode, GjaAnimationMode.none);
    expectZeroDurations(resolved.motion);
    expect(
      resolved.copyWith(
        motion: light.motion,
        animationMode: light.animationMode,
      ),
      light,
    );
  });

  test(
    'Movimento reduzido no tema — Modo do tema sem pedido da plataforma',
    () {
      final minimal = light.copyWith(animationMode: GjaAnimationMode.minimal);
      final resolved = minimal.resolve(disableAnimations: false);
      expect(resolved.animationMode, GjaAnimationMode.minimal);
      expectZeroDurations(resolved.motion);
    },
  );

  test('Movimento reduzido no tema — Tema sem redução', () {
    expect(light.resolve(disableAnimations: false), same(light));
    final basic = light.copyWith(animationMode: GjaAnimationMode.basic);
    expect(basic.resolve(disableAnimations: false), same(basic));
  });

  test(
    'Tokens de componente e extensões — Componente registrado e ausente',
    () {
      final themed = light.copyWith(
        components: GjaTokenExtensions([const _ButtonTestTokens(64)]),
      );
      expect(
        themed.components.get<_ButtonTestTokens>(),
        const _ButtonTestTokens(64),
      );
      expect(themed.components.get<_AbsentTokens>(), isNull);
      expect(themed.extensions.get<_ButtonTestTokens>(), isNull);
    },
  );

  group('Interpolação entre temas', () {
    test('Interpolação entre temas — Troca animada de claro para escuro', () {
      expect(light.lerp(dark, 0), light);
      expect(light.lerp(dark, 1), dark);
      final mid = light.lerp(dark, 0.5);
      expect(mid.brightness, Brightness.dark);
      expect(
        mid.colors.base,
        Color.lerp(light.colors.base, dark.colors.base, 0.5),
      );
      expect(light.lerp(dark, 0.49).brightness, Brightness.light);
    });

    test('Interpolação entre temas — Contrato verificado', () {
      expectTokenSetContract(a: light, aCopy: GjaThemeData.light(), b: dark);
    });

    test('igualdade e copyWith consideram cada campo isoladamente', () {
      final variants = [
        light.copyWith(brightness: Brightness.dark),
        light.copyWith(colors: dark.colors),
        light.copyWith(
          typography: light.typography.copyWith(base: light.typography.small),
        ),
        light.copyWith(density: const GjaDensityTokens.compact()),
        light.copyWith(radius: light.radius.copyWith(button: 6)),
        light.copyWith(
          shadows: light.shadows.copyWith(card: light.shadows.shadow1),
        ),
        light.copyWith(
          motion: light.motion.copyWith(
            long: const Duration(milliseconds: 400),
          ),
        ),
        light.copyWith(icons: light.icons.copyWith(control: 24)),
        light.copyWith(interaction: light.interaction.copyWith(focusWidth: 3)),
        light.copyWith(breakpoints: light.breakpoints.copyWith(large: 1100)),
        light.copyWith(animationMode: GjaAnimationMode.none),
        light.copyWith(
          components: GjaTokenExtensions([const _ButtonTestTokens(1)]),
        ),
        light.copyWith(
          extensions: GjaTokenExtensions([const _ButtonTestTokens(1)]),
        ),
      ];
      for (final (i, variant) in variants.indexed) {
        expect(variant, isNot(light), reason: 'campo $i');
        expect(variant.lerp(light, 1), light, reason: 'campo $i');
      }
    });

    test('diagnóstico lista cada conjunto', () {
      final dump = light.toDiagnosticsNode().toStringDeep();
      for (final name in [
        'brightness',
        'colors',
        'typography',
        'density',
        'radius',
        'shadows', //
        'motion',
        'icons',
        'interaction',
        'breakpoints',
        'animationMode',
        'components',
        'extensions',
      ]) {
        expect(dump, contains('$name:'), reason: name);
      }
    });
  });
}

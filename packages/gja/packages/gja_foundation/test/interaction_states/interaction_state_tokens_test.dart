import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_foundation/gja_primitives.dart';

import '../support/token_set_contract.dart';

const _t = GjaInteractionStateTokens.fallback();
const _light = GjaColorTokens.light();
const _none = GjaColorPrimitives.transparent;

const _hovered = GjaInteractionState.hovered;
const _focused = GjaInteractionState.focused;
const _pressed = GjaInteractionState.pressed;
const _selected = GjaInteractionState.selected;
const _disabled = GjaInteractionState.disabled;

GjaStateColors _s(Color background, Color border, Color text) =>
    GjaStateColors(background: background, border: border, text: text);

const _semanticFamilies = [
  (GjaControlFamily.accept, GjaValueState.success),
  (GjaControlFamily.reject, GjaValueState.error),
  (GjaControlFamily.attention, GjaValueState.warning),
];

GjaControlColors _of(GjaControlFamily f) =>
    GjaControlColors.of(f, _light);

void main() {
  group('Famílias de controle', () {
    final c = _light;

    test('Famílias de controle — Família standard', () {
      final f = _of(GjaControlFamily.standard);
      expect(f.normal, _s(c.base, c.fieldBorder, c.brand));
      expect(f.hover, _s(c.hoverBackground, c.fieldBorder, c.brand));
      expect(f.active, _s(c.highlight, c.highlight, c.contrastText));
      expect(f.selected, _s(c.selectionBackground, c.brand, c.brand));
      expect(f.selectedHover, _s(c.selectionHoverBackground, c.brand, c.brand));
    });

    test('Famílias de controle — Família emphasized', () {
      final f = _of(GjaControlFamily.emphasized);
      expect(f.normal, _s(c.brand, c.brand, c.contrastText));
      expect(f.hover, _s(c.brandHover, c.brandHover, c.contrastText));
      final active = _s(c.highlight, c.highlight, c.contrastText);
      expect([f.active, f.selected, f.selectedHover], everyElement(active));
    });

    test('Famílias de controle — Famílias transparent e list', () {
      final t = _of(GjaControlFamily.transparent);
      final l = _of(GjaControlFamily.list);
      for (final f in [t, l]) {
        for (final state in f.states.values) {
          expect(state.border, _none);
        }
        expect(f.hover.background, c.hoverBackground);
        expect(f.active.background, c.highlight);
        expect(f.active.text, c.contrastText);
        expect(f.selected.background, c.selectionBackground);
        expect(f.selectedHover.background, c.selectionHoverBackground);
      }
      expect(t.normal.background, _none);
      expect(t.normal.text, c.brand);
      expect(l.normal.background, c.base);
      expect(l.normal.text, c.text);
    });

    test('Famílias de controle — Famílias accept, reject e attention', () {
      for (final (family, state) in _semanticFamilies) {
        final f = _of(family);
        final s = c.stateColors(state);
        expect(f.normal, _s(s.background, s.border, s.foreground));
        expect(f.hover, _s(s.hoverBackground, s.border, s.foreground));
        final active = _s(s.foreground, s.foreground, s.background);
        expect([f.active, f.selected, f.selectedHover], everyElement(active));
      }
    });

    test('Famílias de controle — Ações semânticas sem cores da marca', () {
      final other = _light.copyWith(
        brand: GjaColorPrimitives.cyan700,
        highlight: GjaColorPrimitives.cyan900,
        hoverBackground: GjaColorPrimitives.neutral300,
      );
      for (final (family, _) in _semanticFamilies) {
        expect(
          GjaControlColors.of(family, other),
          GjaControlColors.of(family, _light),
          reason: family.name,
        );
      }
    });

    test('Famílias de controle — Marca alcança as famílias', () {
      final brand = _light.copyWith(brand: GjaColorPrimitives.cyan700);
      final f = GjaControlColors.of(GjaControlFamily.standard, brand);
      expect(f.normal.text, GjaColorPrimitives.cyan700);
      expect(f.selected.border, GjaColorPrimitives.cyan700);
    });
  });

  group('Resolução de cores por estado', () {
    final f = _of(GjaControlFamily.standard);

    test('Resolução de cores por estado — Estados isolados', () {
      final cases = <(Set<GjaInteractionState>, GjaStateColors)>[
        ({}, f.normal),
        ({_hovered}, f.hover),
        ({_pressed}, f.active),
        ({_hovered, _pressed}, f.active),
        ({_focused}, f.normal),
      ];
      for (final (states, expected) in cases) {
        expect(f.resolve(states), expected, reason: '$states');
      }
    });

    test('Resolução de cores por estado — Seleção combinada', () {
      expect(f.resolve({_selected}), f.selected);
      expect(f.resolve({_selected, _hovered}), f.selectedHover);
      expect(f.resolve({_selected, _pressed}), f.active);
    });

    test('Resolução de cores por estado — Desabilitado usa o normal', () {
      final states = {_disabled, _hovered, _pressed};
      expect(f.resolve(states), f.normal);
      expect(_t.opacity(states), _t.disabledOpacity);
    });
  });

  test('Aparência desabilitada — Opacidade de desabilitado', () {
    expect(_t.opacity({_disabled}), 0.4);
    expect(_t.opacity({_hovered}), 1);
    expect(
      GjaInteractionPrimitives.opacities.values,
      contains(_t.disabledOpacity),
    );
  });

  group('Anel de foco', () {
    test('Anel de foco — Visibilidade do anel', () {
      final cases = <(Set<GjaInteractionState>, bool)>[
        ({_focused}, true),
        ({_focused, _pressed}, true),
        ({_hovered}, false),
        ({_focused, _disabled}, false),
      ];
      for (final (states, expected) in cases) {
        expect(_t.showsFocusRing(states), expected, reason: '$states');
      }
    });

    test('Anel de foco — Espessura mínima', () {
      expect(_t.focusWidth, greaterThanOrEqualTo(2));
      expect(_t.focusOffset, greaterThanOrEqualTo(0));
    });
  });

  group('Contrato do conjunto de estados', () {
    test('Contrato do conjunto de estados — Contrato verificado', () {
      expectTokenSetContract(
        a: _t,
        // Instância não canônica, para testar a igualdade por valor.
        // ignore: prefer_const_constructors
        aCopy: GjaInteractionStateTokens.fallback(),
        b: _t.copyWith(disabledOpacity: 0.5),
      );
      final colors = _of(GjaControlFamily.list);
      expectTokenSetContract(
        a: colors,
        aCopy: colors.copyWith(),
        b: _of(GjaControlFamily.emphasized),
      );
    });

    test('Contrato do conjunto de estados — Mapeamento inválido rejeitado', () {
      for (final (name, build)
          in <(String, GjaInteractionStateTokens Function())>[
            ('"disabledOpacity"', () => _t.copyWith(disabledOpacity: 0)),
            ('"focusWidth"', () => _t.copyWith(focusWidth: 1)),
            ('"focusOffset"', () => _t.copyWith(focusOffset: -1)),
          ]) {
        expect(
          build,
          throwsA(
            isA<AssertionError>().having(
              (e) => e.message,
              'message',
              contains(name),
            ),
          ),
          reason: name,
        );
      }
    });

    test('igualdade e copyWith consideram cada campo isoladamente', () {
      final variants = [
        _t.copyWith(disabledOpacity: 0.5),
        _t.copyWith(focusWidth: 3),
        _t.copyWith(focusOffset: 2),
      ];
      for (final (i, variant) in variants.indexed) {
        expect(variant, isNot(_t), reason: 'campo $i');
        expect(variant.lerp(_t, 1), _t, reason: 'campo $i');
      }
    });

    test('diagnóstico lista cada valor', () {
      final dump = _t.toDiagnosticsNode().toStringDeep();
      for (final name in ['disabledOpacity', 'focusWidth', 'focusOffset']) {
        expect(dump, contains('$name:'), reason: name);
      }
    });
  });
}

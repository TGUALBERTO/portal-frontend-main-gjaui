import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_foundation/gja_primitives.dart';

double _max(
  List<GjaShadowLayer> level,
  double Function(GjaShadowLayer) f,
) => level.map(f).fold(0, (a, b) => a > b ? a : b);

void main() {
  group('Escala primitiva de sombras', () {
    test('Escala primitiva de sombras — Profundidade crescente', () {
      const levels = [
        GjaShadowPrimitives.shadow0,
        GjaShadowPrimitives.shadow1,
        GjaShadowPrimitives.shadow2,
        GjaShadowPrimitives.shadow3,
      ];
      expect(GjaShadowPrimitives.none, isEmpty);
      for (var i = 1; i < levels.length; i++) {
        expect(
          _max(levels[i], (l) => l.blurRadius),
          greaterThan(_max(levels[i - 1], (l) => l.blurRadius)),
          reason: 'desfoque de shadow$i',
        );
        expect(
          _max(levels[i], (l) => l.offsetY),
          greaterThanOrEqualTo(_max(levels[i - 1], (l) => l.offsetY)),
          reason: 'deslocamento de shadow$i',
        );
      }
    });

    test('Escala primitiva de sombras — Fatores de opacidade válidos', () {
      for (final MapEntry(key: name, value: level)
          in GjaShadowPrimitives.values.entries) {
        for (final layer in level) {
          expect(layer.isValid, isTrue, reason: name);
          expect(layer.opacity, inInclusiveRange(0, 1), reason: name);
        }
      }
      expect(GjaShadowPrimitives.header, isNotEmpty);
      expect(GjaShadowPrimitives.header.every((l) => l.offsetY > 0), isTrue);
    });
  });

  group('Geometria no modelo Horizon', () {
    bool isOutline(GjaShadowLayer l) =>
        l.offsetY == 0 && l.blurRadius == 0 && l.spreadRadius == 1;

    test(
      'Geometria no modelo Horizon — Contorno nas sombras de sobreposição',
      () {
        for (final (name, shadow) in [
          ('shadow1', GjaShadowPrimitives.shadow1),
          ('shadow2', GjaShadowPrimitives.shadow2),
          ('shadow3', GjaShadowPrimitives.shadow3),
        ]) {
          expect(shadow.where(isOutline), hasLength(1), reason: name);
          expect(shadow.any((l) => l.blurRadius > 0), isTrue, reason: name);
        }
      },
    );

    test('Geometria no modelo Horizon — Cartão sem contorno', () {
      expect(
        GjaShadowPrimitives.shadow0.every((l) => l.spreadRadius == 0),
        isTrue,
      );
    });
  });

  test('GjaShadowLayer.lerp e lerpList', () {
    const a = GjaShadowLayer(offsetY: 2, blurRadius: 4);
    const b = GjaShadowLayer(
      offsetY: 6,
      blurRadius: 8,
      spreadRadius: 2,
      opacity: 0.5,
    );
    expect(GjaShadowLayer.lerp(a, b, 0), a);
    expect(GjaShadowLayer.lerp(a, b, 1), b);
    expect(
      GjaShadowLayer.lerp(a, b, 0.5),
      const GjaShadowLayer(
        offsetY: 4,
        blurRadius: 6,
        spreadRadius: 1,
        opacity: 0.75,
      ),
    );
    final padded = GjaShadowLayer.lerpList(const [a], const [a, b], 1);
    expect(padded, [a, b]);
    expect(GjaShadowLayer.lerpList(const [a, b], const [], 1), isEmpty);
    expect(GjaShadowLayer.lerpList(const [a, b], const [], 0.5), [
      GjaShadowLayer.lerp(a, GjaShadowLayer.zero, 0.5),
      GjaShadowLayer.lerp(b, GjaShadowLayer.zero, 0.5),
    ]);
  });
}

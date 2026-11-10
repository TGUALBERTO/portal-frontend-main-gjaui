// Usa somente as bibliotecas públicas, como faria uma aplicação.
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_foundation/gja_primitives.dart';

void main() {
  test(
    'Primitivos isolados da camada de widgets — Aplicação personaliza a marca',
    () {
      const brand = GjaMotionTokens(
        instant: GjaMotionPrimitives.duration0,
        short: GjaMotionPrimitives.duration150,
        medium: GjaMotionPrimitives.duration250,
        long: GjaMotionPrimitives.duration400,
        standard: GjaMotionPrimitives.curveEaseInOut,
        enter: GjaMotionPrimitives.curveEaseOut,
        exit: GjaMotionPrimitives.curveEaseIn,
      );
      expect(brand.medium, GjaMotionPrimitives.duration250);
      expect(brand, isNot(const GjaMotionTokens.fallback()));
    },
  );
}

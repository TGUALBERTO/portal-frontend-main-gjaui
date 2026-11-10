import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

Widget _ring({required bool visible}) {
  const tokens = GjaInteractionStateTokens.fallback();
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: GjaFocusRing(
        visible: visible,
        width: tokens.focusWidth,
        offset: tokens.focusOffset,
        color: const GjaColorTokens.light().focus,
        child: const SizedBox(key: Key('content'), width: 80, height: 32),
      ),
    ),
  );
}

void main() {
  testWidgets('anel visível usa os tokens e não muda o tamanho do conteúdo', (
    tester,
  ) async {
    await tester.pumpWidget(_ring(visible: false));
    final hiddenSize = tester.getSize(find.byKey(const Key('content')));
    expect(
      find.descendant(
        of: find.byType(GjaFocusRing),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );

    await tester.pumpWidget(_ring(visible: true));
    expect(tester.getSize(find.byKey(const Key('content'))), hiddenSize);
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(GjaFocusRing),
        matching: find.byType(CustomPaint),
      ),
    );
    final painter = paint.foregroundPainter! as GjaFocusRingPainter;
    const tokens = GjaInteractionStateTokens.fallback();
    expect(painter.width, tokens.focusWidth);
    expect(painter.offset, tokens.focusOffset);
    expect(painter.color, const GjaColorTokens.light().focus);
    // O traço fica fora do conteúdo: afastamento + meia espessura.
    final rect = painter.ringRect(hiddenSize);
    expect(rect.left, -(tokens.focusOffset + tokens.focusWidth / 2));
    expect(
      rect.width,
      hiddenSize.width + 2 * (tokens.focusOffset + tokens.focusWidth / 2),
    );
  });
}

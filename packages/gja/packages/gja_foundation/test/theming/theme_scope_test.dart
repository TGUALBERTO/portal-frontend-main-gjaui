import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Lê o tema ativo e guarda cada leitura.
class _Reader extends StatelessWidget {
  const _Reader(this.reads);

  final List<GjaThemeData> reads;

  @override
  Widget build(BuildContext context) {
    reads.add(GjaThemeData.of(context));
    return const SizedBox();
  }
}

void main() {
  group('Tema na árvore de widgets', () {
    testWidgets('Tema na árvore de widgets — Tema mais próximo', (
      tester,
    ) async {
      final reads = <GjaThemeData>[];
      await tester.pumpWidget(
        GjaThemeScope(
          data: GjaThemeData.light(),
          child: GjaThemeScope(
            data: GjaThemeData.dark(),
            child: _Reader(reads),
          ),
        ),
      );
      expect(reads.single, GjaThemeData.dark());
    });

    testWidgets('Tema na árvore de widgets — Árvore sem tema', (tester) async {
      final reads = <GjaThemeData>[];
      await tester.pumpWidget(_Reader(reads));
      expect(reads.single, GjaThemeData.light());
    });

    testWidgets(
      'Tema na árvore de widgets — Animações desligadas pelo sistema',
      (tester) async {
        final reads = <GjaThemeData>[];
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: GjaThemeScope(
              data: GjaThemeData.light(),
              child: _Reader(reads),
            ),
          ),
        );
        final motion = reads.single.motion;
        for (final d in [
          motion.instant,
          motion.short,
          motion.medium,
          motion.long,
        ]) {
          expect(d, Duration.zero);
        }
        expect(reads.single.animationMode, GjaAnimationMode.none);
      },
    );

    testWidgets('Tema na árvore de widgets — Animações desligadas pelo tema', (
      tester,
    ) async {
      final reads = <GjaThemeData>[];
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: GjaThemeScope(
            data: GjaThemeData.light().copyWith(
              animationMode: GjaAnimationMode.none,
            ),
            child: _Reader(reads),
          ),
        ),
      );
      final motion = reads.single.motion;
      for (final d in [
        motion.instant,
        motion.short,
        motion.medium,
        motion.long,
      ]) {
        expect(d, Duration.zero);
      }
    });

    testWidgets('Tema na árvore de widgets — Reconstrução na troca', (
      tester,
    ) async {
      final reads = <GjaThemeData>[];
      // O leitor é constante: só a dependência do escopo o reconstrói.
      final reader = _Reader(reads);
      await tester.pumpWidget(
        GjaThemeScope(data: GjaThemeData.light(), child: reader),
      );
      await tester.pumpWidget(
        GjaThemeScope(data: GjaThemeData.dark(), child: reader),
      );
      expect(reads, [GjaThemeData.light(), GjaThemeData.dark()]);
    });

    testWidgets('mesmo tema não reconstrói quem lê', (tester) async {
      final reads = <GjaThemeData>[];
      final reader = _Reader(reads);
      await tester.pumpWidget(
        GjaThemeScope(data: GjaThemeData.light(), child: reader),
      );
      await tester.pumpWidget(
        GjaThemeScope(data: GjaThemeData.light(), child: reader),
      );
      expect(reads, hasLength(1));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/shared/widgets/toast/toast_card.dart';
import 'package:gjamobile/src/shared/wrappers/screen_util_wrapper.dart';
import 'package:gjamobile/src/theme/theme_constants.dart';

void main() {
  Future<void> pumpToastHost(
    WidgetTester tester, {
    required Size screenSize,
    required String message,
  }) async {
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilWrapper(
        child: MaterialApp(
          theme: buildLightTheme(primaryColorHex: '#de3438'),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showToast(context, message: message),
                  child: const Text('show'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    // Passa da animação de entrada (150 ms) sem chegar no auto-dismiss (2 s).
    await tester.pump(const Duration(milliseconds: 400));
  }

  double toastCardWidth(WidgetTester tester) {
    final decoratedBox = find
        .descendant(
          of: find.byType(ToastCard),
          matching: find.byType(DecoratedBox),
        )
        .first;
    return tester.getSize(decoratedBox).width;
  }

  group('showToast', () {
    testWidgets('limita a largura do card em janelas largas (desktop)',
        (tester) async {
      await pumpToastHost(
        tester,
        screenSize: const Size(1600, 900),
        message: 'Matrícula vinculada com sucesso!',
      );

      expect(find.text('Matrícula vinculada com sucesso!'), findsOneWidget);
      expect(
        toastCardWidth(tester),
        lessThanOrEqualTo(AppBreakpoints.maxToastWidth),
      );

      // Deixa o auto-dismiss concluir para não vazarem timers do
      // flutter_animate no teardown do teste.
      await tester.pumpAndSettle();
    });

    testWidgets('quebra mensagens longas sem overflow em telas compactas',
        (tester) async {
      const longMessage =
          'Não foi possível vincular a matrícula: verifique os dados '
          'informados e tente novamente em alguns instantes.';

      await pumpToastHost(
        tester,
        screenSize: const Size(360, 690),
        message: longMessage,
      );

      expect(find.text(longMessage), findsOneWidget);
      expect(toastCardWidth(tester), lessThanOrEqualTo(360));
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
    });
  });
}

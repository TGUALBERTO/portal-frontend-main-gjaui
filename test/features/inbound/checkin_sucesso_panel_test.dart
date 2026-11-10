import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/entities/checkin_motorista.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/enums/checkin_checkout_veiculo_mode.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/enums/checkin_status.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/presentation/widgets/checkin_sucesso_panel.dart';
import 'package:gjamobile/src/shared/widgets/widgets.dart';
import 'package:gjamobile/src/shared/wrappers/screen_util_wrapper.dart';
import 'package:gjamobile/src/theme/theme.dart';
import 'package:go_router/go_router.dart';

/// O painel de sucesso do check-in/check-out roda no coletor da portaria
/// (Android, tela pequena), em Windows e eventualmente num navegador largo.
/// Estes testes montam a composição real (ScreenUtilWrapper -> MaterialApp ->
/// AppPageScaffold) em cada viewport e falham se qualquer RenderFlex estourar.
void main() {
  const checkin = CheckinMotorista(
    checkin: '0000000009',
    status: CheckinStatus.realizado,
    motorista: 'João da Silva',
    placa: 'ABC1D23',
    cpf: '12345678901',
    tipo: '',
    data: '20260806',
    hora: '083000',
  );

  /// Viewports representativos: coletor pequeno, coletor padrão, coletor
  /// deitado, tablet e desktop.
  const viewports = <String, Size>{
    'coletor pequeno (320x480)': Size(320, 480),
    'coletor padrão (360x690)': Size(360, 690),
    'coletor deitado (690x360)': Size(690, 360),
    'tablet (800x1280)': Size(800, 1280),
    'desktop (1440x900)': Size(1440, 900),
  };

  Future<void> pumpPanel(
    WidgetTester tester, {
    required Size size,
    CheckinMotorista? data = checkin,
    CheckinCheckoutVeiculoMode mode = CheckinCheckoutVeiculoMode.checkIn,
    int segundosRestantes = 10,
    double textScale = 1.0,
  }) async {
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = size;
    addTearDown(tester.view.reset);

    // MaterialApp.router e não `home:`: o AppTopBar chama context.canPop(), que
    // exige um GoRouter na árvore — mesma composição da tela real.
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => AppPageScaffold(
            formWidth: true,
            appBar: AppTopBar(title: mode.tituloTela),
            body: CheckinSucessoPanel(
              mode: mode,
              checkin: data,
              segundosRestantes: segundosRestantes,
              totalSegundos: 10,
              onIrParaHome: () {},
              onNovaOperacao: () {},
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ScreenUtilWrapper(
        child: MaterialApp.router(
          theme: buildLightTheme(primaryColorHex: '#de3438'),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    // pump() e não pumpAndSettle(): basta um frame de layout+paint para o
    // overflow aparecer, e o AnimatedSwitcher do AppButton não precisa assentar.
    await tester.pump();
  }

  group('CheckinSucessoPanel — responsividade', () {
    for (final entry in viewports.entries) {
      testWidgets('sem overflow em ${entry.key}', (tester) async {
        await pumpPanel(tester, size: entry.value);

        expect(tester.takeException(), isNull);
        expect(find.text('Entrada liberada!'), findsOneWidget);
        expect(find.text('ABC1D23  ·  João da Silva'), findsOneWidget);
        expect(find.text('Ir agora para o início'), findsOneWidget);
        expect(find.text('Fazer outro check-in'), findsOneWidget);
      });
    }

    testWidgets('sem overflow com texto ampliado (acessibilidade 1.5x)',
        (tester) async {
      await pumpPanel(
        tester,
        size: const Size(320, 480),
        textScale: 1.5,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('sem overflow com nome de motorista longo', (tester) async {
      await pumpPanel(
        tester,
        size: const Size(320, 480),
        data: const CheckinMotorista(
          checkin: '0000000009',
          status: CheckinStatus.realizado,
          motorista: 'Maria Aparecida dos Santos Nascimento Rodrigues Filho',
          placa: 'ABC1D23',
          cpf: '12345678901',
          tipo: '',
          data: '20260806',
          hora: '083000',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('conteúdo rola quando não cabe na altura', (tester) async {
      await pumpPanel(tester, size: const Size(320, 480));

      // AppPageScaffold é scrollable: o painel alto tem para onde ir em vez de
      // estourar. Se a lista couber, o scroll simplesmente não move.
      final scroll = find.byType(Scrollable).last;
      await tester.drag(scroll, const Offset(0, -200));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Fazer outro check-in'), findsOneWidget);
    });

    testWidgets('check-out mostra os labels do próprio modo', (tester) async {
      await pumpPanel(
        tester,
        size: const Size(360, 690),
        mode: CheckinCheckoutVeiculoMode.checkOut,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Saída liberada!'), findsOneWidget);
      expect(find.text('Fazer outro check-out'), findsOneWidget);
    });

    testWidgets('sem check-in cai na mensagem genérica', (tester) async {
      await pumpPanel(tester, size: const Size(360, 690), data: null);

      expect(tester.takeException(), isNull);
      expect(find.text('Entrada liberada com sucesso'), findsOneWidget);
    });
  });
}

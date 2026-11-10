import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/enums/checkin_checkout_veiculo_mode.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/enums/checkin_status.dart';
import 'package:gjamobile/src/features/inbound/shared/presentation/widgets/leitura_checkin_view.dart';
import 'package:gjamobile/src/shared/widgets/widgets.dart';
import 'package:gjamobile/src/shared/wrappers/screen_util_wrapper.dart';
import 'package:gjamobile/src/theme/theme.dart';
import 'package:go_router/go_router.dart';

/// A primeira tela de todo submódulo do inbound é a mesma: informar o número do
/// check-in. Antes cada uma montava o próprio alvo, separador e bloco de erro, e
/// as três divergiram. Estes testes prendem o contrato da view compartilhada.
void main() {
  const viewports = <String, Size>{
    'coletor pequeno (320x480)': Size(320, 480),
    'coletor padrão (360x690)': Size(360, 690),
    'coletor deitado (690x360)': Size(690, 360),
    'tablet (800x1280)': Size(800, 1280),
    'desktop (1440x900)': Size(1440, 900),
  };

  late TextEditingController controller;
  late FocusNode focusNode;

  setUp(() {
    controller = TextEditingController();
    focusNode = FocusNode();
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  /// A plataforma decide metade da tela: o bloco de câmera só existe em
  /// Android/iOS. Fixá-la é o que faz o teste cobrir o caminho do Windows/web
  /// (o desktop da portaria) — sem isso tudo herda o `android` padrão do
  /// `flutter test`.
  ///
  /// A restauração é `finally` **dentro** do corpo do teste, e não
  /// `tearDown`/`addTearDown`: o framework verifica as vars de debug ao fim do
  /// corpo, antes de qualquer teardown, e uma var pendente reprova o teste.
  Future<void> comPlataforma(
    TargetPlatform plataforma,
    Future<void> Function() corpo,
  ) async {
    debugDefaultTargetPlatformOverride = plataforma;
    try {
      await corpo();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  Future<void> pump(
    WidgetTester tester, {
    required Size size,
    required Widget body,
    double textScale = 1.0,
  }) async {
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = size;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: SafeArea(child: SingleChildScrollView(child: body)),
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
    await tester.pump();
  }

  Widget view({
    String titulo = 'Contagem cega',
    String labelConfirmar = 'Confirmar',
    bool carregando = false,
    Widget? erro,
    Future<void> Function()? onConfirmar,
  }) =>
      LeituraCheckinView(
        titulo: titulo,
        labelConfirmar: labelConfirmar,
        controller: controller,
        focusNode: focusNode,
        carregando: carregando,
        onScan: () async {},
        onConfirmar: onConfirmar ?? () async {},
        erro: erro,
      );

  group('LeituraCheckinView', () {
    for (final entry in viewports.entries) {
      testWidgets('sem overflow em ${entry.key}', (tester) async {
        await comPlataforma(TargetPlatform.android, () async {
          await pump(tester, size: entry.value, body: view());
          expect(tester.takeException(), isNull);
        });
      });
    }

    testWidgets('sem overflow com texto ampliado (1.5x)', (tester) async {
      await comPlataforma(TargetPlatform.android, () async {
        await pump(
          tester,
          size: const Size(320, 480),
          body: view(),
          textScale: 1.5,
        );
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('mostra o kicker e o título recebidos', (tester) async {
      await comPlataforma(TargetPlatform.android, () async {
        await pump(
          tester,
          size: const Size(360, 690),
          body: view(titulo: 'Entrada de Veículos'),
        );

        expect(find.text('Inbound · Recebimento'), findsOneWidget);
        expect(find.text('Entrada de Veículos'), findsOneWidget);
      });
    });

    testWidgets('com câmera: alvo, separador e botão de leitura',
        (tester) async {
      await comPlataforma(TargetPlatform.android, () async {
        await pump(tester, size: const Size(360, 690), body: view());

        expect(find.text('Ler QR-Code'), findsOneWidget);
        expect(find.text('ou digite'), findsOneWidget);
        expect(
          find.text('Aponte para o QR-Code do Check-in gerado na portaria'),
          findsOneWidget,
        );
      });
    });

    testWidgets('sem câmera: só o campo e o botão de confirmação',
        (tester) async {
      // Windows/web: o fluxo completa pelo campo de texto. O alvo de QR Code e
      // o separador não podem aparecer — era o espaço morto que a tela da
      // portaria mostrava no desktop.
      await comPlataforma(TargetPlatform.windows, () async {
        await pump(tester, size: const Size(1440, 900), body: view());

        expect(find.byType(AppTextField), findsOneWidget);
        expect(find.text('Ler QR-Code'), findsNothing);
        expect(find.text('ou digite'), findsNothing);
        expect(
          find.text('Aponte para o QR-Code do Check-in gerado na portaria'),
          findsNothing,
        );
      });
    });

    testWidgets('o label do botão de confirmação vem de quem monta a view',
        (tester) async {
      await comPlataforma(TargetPlatform.android, () async {
        await pump(
          tester,
          size: const Size(360, 690),
          body: view(labelConfirmar: 'Buscar'),
        );

        expect(find.text('Buscar'), findsOneWidget);
        expect(find.text('Confirmar'), findsNothing);
      });
    });

    testWidgets('Enter no campo dispara a confirmação', (tester) async {
      await comPlataforma(TargetPlatform.android, () async {
        var chamou = 0;
        await pump(
          tester,
          size: const Size(360, 690),
          body: view(onConfirmar: () async => chamou++),
        );

        await tester.enterText(find.byType(AppTextField), '3');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();

        expect(chamou, 1);
      });
    });

    testWidgets('carregando desabilita os dois botões', (tester) async {
      // O `AppButton` em loading troca o label pelo spinner, então o assert é
      // sobre `onPressed`, não sobre um toque: buscar pelo texto não acharia
      // nada e o teste passaria sem testar coisa alguma.
      await comPlataforma(TargetPlatform.android, () async {
        await pump(
          tester,
          size: const Size(360, 690),
          body: view(carregando: true),
        );

        final botoes = tester.widgetList<AppButton>(find.byType(AppButton));
        expect(botoes, hasLength(2)); // ler QR-Code + confirmar
        expect(botoes.every((b) => b.onPressed == null), isTrue);
        expect(botoes.any((b) => b.isLoading), isTrue);
      });
    });

    testWidgets('parado, os dois botões respondem', (tester) async {
      await comPlataforma(TargetPlatform.android, () async {
        await pump(tester, size: const Size(360, 690), body: view());

        final botoes = tester.widgetList<AppButton>(find.byType(AppButton));
        expect(botoes.every((b) => b.onPressed != null), isTrue);
      });
    });

    testWidgets('o bloco de erro nasce abaixo do campo, não no lugar dele',
        (tester) async {
      await comPlataforma(TargetPlatform.android, () async {
        await pump(
          tester,
          size: const Size(360, 690),
          body: view(
            erro: const AppErrorWidget(message: 'Check-in 999 não encontrado.'),
          ),
        );

        // O operador precisa continuar vendo o número digitado para corrigir um
        // dígito — o erro não substitui o campo.
        expect(find.byType(AppTextField), findsOneWidget);
        expect(find.text('Check-in 999 não encontrado.'), findsOneWidget);
        expect(
          tester.getTopLeft(find.byType(AppErrorWidget)).dy,
          greaterThan(tester.getTopLeft(find.byType(AppTextField)).dy),
        );
      });
    });

    testWidgets('sem erro não sobra espaço reservado', (tester) async {
      await comPlataforma(TargetPlatform.android, () async {
        await pump(tester, size: const Size(360, 690), body: view());
        expect(find.byType(AppErrorWidget), findsNothing);
      });
    });
  });

  group('CheckinCheckoutVeiculoMode.consulta', () {
    test('não tem ação: não posta nada no SAP', () {
      expect(CheckinCheckoutVeiculoMode.consulta.temAcao, isFalse);
      expect(CheckinCheckoutVeiculoMode.consulta.tipo, isNull);
    });

    test('os modos que liberam movimento mantêm o TIPO do POST', () {
      expect(CheckinCheckoutVeiculoMode.checkIn.temAcao, isTrue);
      expect(CheckinCheckoutVeiculoMode.checkIn.tipo, 'IN');
      expect(CheckinCheckoutVeiculoMode.checkOut.temAcao, isTrue);
      expect(CheckinCheckoutVeiculoMode.checkOut.tipo, 'OUT');
    });

    test('nenhum status autoriza movimento em consulta', () {
      for (final status in CheckinStatus.values) {
        expect(
          status.permitePara(CheckinCheckoutVeiculoMode.consulta),
          isFalse,
          reason: 'consulta é somente leitura, mas ${status.codigo} autorizou',
        );
      }
    });

    test('a regra dos outros dois modos não mudou', () {
      expect(
        CheckinStatus.realizado.permitePara(CheckinCheckoutVeiculoMode.checkIn),
        isTrue,
      );
      expect(
        CheckinStatus.realizado
            .permitePara(CheckinCheckoutVeiculoMode.checkOut),
        isFalse,
      );
      expect(
        CheckinStatus.entregaConcluida
            .permitePara(CheckinCheckoutVeiculoMode.checkOut),
        isTrue,
      );
      expect(
        CheckinStatus.comPendencias
            .permitePara(CheckinCheckoutVeiculoMode.checkIn),
        isTrue,
      );
    });

    test('tem título próprio na tela', () {
      expect(
        CheckinCheckoutVeiculoMode.consulta.tituloTela,
        'Consulta de Check-in',
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/contagem_item/presentation/widgets/identificacao_item_card.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/mock/contagem_cega_mock.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_mensagem.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_item_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_mensagem_tipo.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/itens_nota/presentation/widgets/item_nota_card.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/notas_fiscais/presentation/widgets/nota_fiscal_card.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_app_bar.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_banner.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_footer.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_tag.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/resumo_checkin/presentation/widgets/checkin_finalizado_panel.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/resumo_checkin/presentation/widgets/resumo_nota_card.dart';
import 'package:gjamobile/src/features/inbound/shared/presentation/widgets/alvo_qr_code.dart';
import 'package:gjamobile/src/shared/enums/button_enums.dart';
import 'package:gjamobile/src/shared/widgets/widgets.dart';
import 'package:gjamobile/src/shared/wrappers/screen_util_wrapper.dart';
import 'package:gjamobile/src/theme/theme.dart';
import 'package:go_router/go_router.dart';

/// As telas da contagem cega rodam no coletor do recebimento (Android, tela
/// pequena, às vezes com texto ampliado) e eventualmente num navegador largo.
/// Estes testes montam a composição real em cada viewport e falham se qualquer
/// RenderFlex estourar.
void main() {
  final notas = mockNotasFiscais();
  final notaPendente = notas.first;
  final itemPendente = notaPendente.itens.first;

  /// Mesma nota com o primeiro item divergente — é o pior caso de layout:
  /// tag cheia, linha de "Contado" e lista de divergentes no resumo.
  final notaDevolvida = notaPendente.copyWith(
    itens: [
      itemPendente.copyWith(
        status: ContagemItemStatus.divergente,
        tentativas: 3,
        quantidadeContada: 5,
        loteLido: 'C2212026',
      ),
      ...notaPendente.itens.skip(1),
    ],
  );

  const viewports = <String, Size>{
    'coletor pequeno (320x480)': Size(320, 480),
    'coletor padrão (360x690)': Size(360, 690),
    // Densidade baixa: mesma tela física, mas 540 dp de largura — é onde um
    // tamanho fixo destoa do resto, que escala com o ScreenUtil.
    'coletor 540 dp (540x1080)': Size(540, 1080),
    'coletor deitado (690x360)': Size(690, 360),
    'tablet (800x1280)': Size(800, 1280),
    'desktop (1440x900)': Size(1440, 900),
  };

  /// Monta o widget na composição real das telas: ScreenUtilWrapper ->
  /// MaterialApp.router (o AppTopBar chama `context.canPop()`, que exige um
  /// GoRouter na árvore) -> Scaffold.
  Future<void> pump(
    WidgetTester tester, {
    required Size size,
    required WidgetBuilder body,
    PreferredSizeWidget? appBar,
    Widget? bottom,
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
            appBar: appBar,
            body: SafeArea(child: body(context)),
            bottomNavigationBar: bottom,
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

  group('Lista de notas fiscais', () {
    for (final entry in viewports.entries) {
      testWidgets('sem overflow em ${entry.key}', (tester) async {
        await pump(
          tester,
          size: entry.value,
          appBar: ContagemAppBar(
            kicker: 'Check-in 3',
            titulo: 'Notas fiscais',
            trailing: const ContagemTag(
              label: '2 NFs',
              variante: ContagemTagVariante.contorno,
            ),
            onVoltar: () {},
          ),
          body: (context) => ListView(
            children: [
              NotaFiscalCard(nota: notaPendente, onTap: () {}),
              NotaFiscalCard(nota: notaDevolvida, onTap: () {}),
            ],
          ),
          bottom: ContagemFooter(
            children: [
              AppButton(
                label: 'Resumo do Check-in',
                variant: ButtonVariant.outline,
                isFullWidth: true,
                onPressed: () {},
              ),
            ],
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('NF-e 021.383'), findsNWidgets(2));
        expect(find.text('TRANSPOWER IND. LTDA'), findsNWidgets(2));
        expect(find.text('Devolver'), findsOneWidget);
        expect(find.text('Resumo do Check-in'), findsOneWidget);
      });
    }

    testWidgets('o card ocupa a largura da lista, não a do conteúdo',
        (tester) async {
      await pump(
        tester,
        size: const Size(800, 1280),
        body: (context) => ListView(
          padding: EdgeInsets.zero,
          children: [NotaFiscalCard(nota: notaPendente)],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(NotaFiscalCard)).width, 800);
    });
  });

  group('Lista de itens da NF-e', () {
    for (final entry in viewports.entries) {
      testWidgets('sem overflow em ${entry.key}', (tester) async {
        await pump(
          tester,
          size: entry.value,
          appBar: ContagemAppBar(
            kicker: 'Check-in 3 · TRANSPOWER IND. LTDA',
            titulo: 'NF-e 021.383',
            trailing: ContagemTag.nota(notaDevolvida.status),
            onVoltar: () {},
          ),
          body: (context) => Column(
            children: [
              const ContagemBanner(
                mensagem: ContagemMensagem(
                  texto: 'Divergência confirmada — NF-e 021.383 marcada para '
                      'devolução.',
                  tipo: ContagemMensagemTipo.devolucao,
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final item in notaDevolvida.itens)
                      ItemNotaCard(
                        item: item,
                        bloqueado:
                            item.status == ContagemItemStatus.pendente,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('CORREIA VA 60'), findsOneWidget);
        expect(find.text('Divergente'), findsOneWidget);
        // `findsWidgets` e não uma contagem exata: a ListView só constrói o que
        // cabe, e o coletor deitado mostra menos itens que o tablet.
        expect(find.text('Bloqueado'), findsWidgets);
      });
    }
  });

  group('Contagem do item', () {
    for (final entry in viewports.entries) {
      testWidgets('sem overflow em ${entry.key}', (tester) async {
        await pump(
          tester,
          size: entry.value,
          appBar: ContagemAppBar(
            kicker: 'NF-e 021.383 · Item 1',
            titulo: 'Contagem',
            trailing: const ContagemTag(
              label: 'Tentativa 2/3',
              variante: ContagemTagVariante.contorno,
            ),
            onVoltar: () {},
          ),
          body: (context) => ListView(
            children: [
              IdentificacaoItemCard(item: itemPendente),
              const ContagemBanner(
                mensagem: ContagemMensagem(
                  texto: 'Quantidade divergente. Reconte o material — '
                      'tentativa 2 de 3.',
                  tipo: ContagemMensagemTipo.reconte,
                ),
              ),
            ],
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('CORREIA VA 60'), findsOneWidget);
        // A quantidade da NF não pode vazar na contagem cega.
        expect(find.textContaining('Qtd. NF'), findsNothing);
      });
    }
  });

  group('Resumo do check-in', () {
    for (final entry in viewports.entries) {
      testWidgets('sem overflow em ${entry.key}', (tester) async {
        await pump(
          tester,
          size: entry.value,
          body: (context) => ListView(
            children: [
              ResumoNotaCard(nota: notaDevolvida),
              ResumoNotaCard(nota: notas.last),
            ],
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Devolver'), findsOneWidget);
        expect(find.text('Pendente'), findsOneWidget);
        expect(
          find.textContaining('CORREIA VA 60 · lote NF C2212026'),
          findsOneWidget,
        );
      });
    }

    testWidgets('painel de finalizado sem overflow no coletor pequeno',
        (tester) async {
      await pump(
        tester,
        size: const Size(320, 480),
        body: (context) => CheckinFinalizadoPanel(
          checkin: '3',
          resumo: '1 NF(s) recebida(s) · 1 NF(s) para devolução ao fornecedor',
          onNovoCheckin: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Check-in 3 finalizado'), findsOneWidget);
      expect(find.text('Novo Check-in'), findsOneWidget);
    });
  });

  group('Leitura do check-in', () {
    testWidgets('o alvo do QR Code preenche o quadrado', (tester) async {
      await pump(
        tester,
        size: const Size(360, 690),
        body: (context) => const AlvoQrCode(),
      );

      expect(tester.takeException(), isNull);
      // AspectRatio 1:1 — o card e a moldura tracejada preenchem o quadrado
      // em vez de encolher até o ícone.
      final alvo = tester.getSize(find.byType(AspectRatio));
      expect(alvo.width, alvo.height);
      expect(alvo.width, closeTo(360 * 0.72, 1));
      expect(
        tester.getSize(find.byType(MolduraTracejada)).width,
        greaterThan(alvo.width * 0.7),
      );
    });

    // O lado era fixo em 240 pt enquanto espaçamentos, botões e fontes escalam
    // com o ScreenUtil: num coletor de densidade baixa (540 dp de largura) o
    // alvo virava metade da coluna e sobrava um vazio embaixo da tela.
    testWidgets('o alvo acompanha a largura da coluna', (tester) async {
      for (final largura in [320.0, 360.0, 540.0]) {
        await pump(
          tester,
          size: Size(largura, largura * 2),
          body: (context) => const AlvoQrCode(),
        );

        final alvo = tester.getSize(find.byType(AspectRatio));
        expect(
          alvo.width,
          closeTo((largura * 0.72).clamp(140.0, 320.0), 1),
          reason: 'alvo em ${largura}dp de largura',
        );
      }
    });
  });

  testWidgets('sem overflow com texto ampliado (acessibilidade 1.5x)',
      (tester) async {
    await pump(
      tester,
      size: const Size(320, 480),
      appBar: ContagemAppBar(
        kicker: 'Check-in 3 · TRANSPOWER IND. LTDA',
        titulo: 'NF-e 021.383',
        trailing: ContagemTag.nota(notaDevolvida.status),
        onVoltar: () {},
      ),
      body: (context) => ListView(
        children: [
          for (final item in notaDevolvida.itens)
            ItemNotaCard(item: item, bloqueado: false),
        ],
      ),
      textScale: 1.5,
    );

    expect(tester.takeException(), isNull);
  });
}

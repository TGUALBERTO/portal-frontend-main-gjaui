import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/extensions/context_extension.dart';
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
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_kicker.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_tag.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/resumo_checkin/presentation/widgets/checkin_finalizado_panel.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/resumo_checkin/presentation/widgets/resumo_nota_card.dart';
import 'package:gjamobile/src/features/inbound/shared/presentation/widgets/alvo_qr_code.dart';
import 'package:gjamobile/src/shared/enums/button_enums.dart';
import 'package:gjamobile/src/shared/widgets/widgets.dart';
import 'package:gjamobile/src/shared/wrappers/screen_util_wrapper.dart';
import 'package:gjamobile/src/theme/theme_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// O `MaterialApp` troca de tema com um `AnimatedTheme`: reaproveitando o mesmo
/// tester entre o tema claro e o escuro, um `pump()` só lê o **início** da
/// interpolação — ou seja, ainda o tema anterior. Avançar além da animação é o
/// que faz o teste medir o tema que ele pediu.
const _animacaoDeTema = Duration(milliseconds: 400);

/// Matriz de responsividade das telas da contagem cega: cada composição real é
/// montada em 6 viewports × 2 temas, mais as escalas de texto de
/// acessibilidade. Falha se um RenderFlex estourar, se uma cor não acompanhar o
/// tema ou se o contraste de um selo/faixa cair abaixo de 3:1.
void main() {
  const primaria = '#de3438';

  final notas = mockNotasFiscais();
  final notaPendente = notas.first;
  final itemPendente = notaPendente.itens.first;

  /// Pior caso de layout: tag cheia, linha de "Contado" e itens bloqueados.
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

  final temas = <String, ThemeData>{
    'claro': buildLightTheme(primaryColorHex: primaria),
    'escuro': buildDarkTheme(primaryColorHex: primaria),
  };

  // ── Composições reais das cinco telas ─────────────────────────────────────

  final telas = <String, _Tela>{
    'leitura do check-in': _Tela(
      appBar: () => const AppTopBar(title: 'Contagem cega'),
      body: (context) => ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          const ContagemKicker('Inbound · Recebimento'),
          Text(
            'Contagem cega',
            style: context.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: AppSpacing.lg),
          const AlvoQrCode(),
          SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Ler QR-Code',
            height: ButtonSize.large,
            isFullWidth: true,
            prefixIcon: const Icon(GjaIcons.qrCode),
            onPressed: () {},
          ),
          SizedBox(height: AppSpacing.md),
          const AppTextField(label: 'Nº do Check-in', hint: 'Ex.: 3'),
        ],
      ),
    ),
    'notas fiscais': _Tela(
      appBar: () => ContagemAppBar(
        kicker: 'Check-in 3',
        titulo: 'Notas fiscais',
        trailing: const ContagemTag(
          label: '2 NFs',
          variante: ContagemTagVariante.contorno,
        ),
        onVoltar: () {},
      ),
      body: (context) => ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          NotaFiscalCard(nota: notaPendente, onTap: () {}),
          SizedBox(height: AppSpacing.sm),
          NotaFiscalCard(nota: notaDevolvida, onTap: () {}),
        ],
      ),
      bottom: () => ContagemFooter(
        children: [
          AppButton(
            label: 'Resumo do Check-in',
            variant: ButtonVariant.outline,
            isFullWidth: true,
            onPressed: () {},
          ),
        ],
      ),
    ),
    'itens da NF-e': _Tela(
      appBar: () => ContagemAppBar(
        kicker: 'Check-in 3 · TRANSPOWER IND. LTDA',
        titulo: 'NF-e 021.383',
        trailing: ContagemTag.nota(notaDevolvida.status),
        onVoltar: () {},
      ),
      body: (context) => Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: const ContagemBanner(
              mensagem: ContagemMensagem(
                texto: 'Divergência confirmada — NF-e 021.383 marcada para '
                    'devolução.',
                tipo: ContagemMensagemTipo.devolucao,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                for (final item in notaDevolvida.itens) ...[
                  ItemNotaCard(
                    item: item,
                    bloqueado: item.status == ContagemItemStatus.pendente,
                  ),
                  SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ),
      bottom: () => ContagemFooter(
        children: [
          AppButton(
            label: 'Escanear material',
            height: ButtonSize.large,
            isFullWidth: true,
            prefixIcon: const Icon(GjaIcons.barCode),
            onPressed: () {},
          ),
        ],
      ),
    ),
    'contagem do item': _Tela(
      appBar: () => ContagemAppBar(
        kicker: 'NF-e 021.383 · Item 1',
        titulo: 'Contagem',
        trailing: const ContagemTag(
          label: 'Tentativa 2/3',
          variante: ContagemTagVariante.contorno,
        ),
        onVoltar: () {},
      ),
      body: (context) => ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          IdentificacaoItemCard(item: itemPendente),
          SizedBox(height: AppSpacing.md),
          const ContagemBanner(
            mensagem: ContagemMensagem(
              texto: 'Quantidade divergente. Reconte o material — tentativa '
                  '2 de 3.',
              tipo: ContagemMensagemTipo.reconte,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: AppTextField(
                  label: 'Lote (Batch)',
                  hint: 'Digite ou escaneie o lote',
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              SizedBox(
                height: 48.h,
                width: 48.h,
                child: IconButton.outlined(
                  icon: const Icon(GjaIcons.barCode),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Quantidade contada · unidade do pedido: PC',
            style: context.textTheme.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          TextField(
            textAlign: TextAlign.center,
            style: context.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
            // Unidade do pedido em headline, como na tela real — é o que
            // disputa largura com o número no coletor pequeno.
            decoration: InputDecoration(
              hintText: '0',
              suffixText: 'PC',
              suffixStyle: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      bottom: () => ContagemFooter(
        children: [
          AppButton(
            label: 'Confirmar contagem',
            height: ButtonSize.large,
            isFullWidth: true,
            onPressed: () {},
          ),
          SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Cancelar',
            variant: ButtonVariant.ghost,
            isFullWidth: true,
            onPressed: () {},
          ),
        ],
      ),
    ),
    // Mesma tela durante a gravação no SAP: campos travados, botão em loading e
    // a faixa de falha. É a composição mais alta do fluxo — o spinner tem
    // altura própria e a faixa de erro é a de texto mais longo.
    'contagem do item (gravando)': _Tela(
      appBar: () => ContagemAppBar(
        kicker: 'NF-e 021.383 · Item 1',
        titulo: 'Contagem',
        trailing: const ContagemTag(
          label: 'Tentativa 2/3',
          variante: ContagemTagVariante.contorno,
        ),
        onVoltar: () {},
      ),
      body: (context) => ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          IdentificacaoItemCard(item: itemPendente),
          SizedBox(height: AppSpacing.md),
          const ContagemBanner(
            mensagem: ContagemMensagem(
              texto: 'A contagem NÃO foi gravada no SAP. O SAP respondeu 500 '
                  'ao gravar a contagem do item 00010. Tente confirmar '
                  'novamente.',
              tipo: ContagemMensagemTipo.erro,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: AppTextField(
                  label: 'Lote (Batch)',
                  hint: 'Digite ou escaneie o lote',
                  enabled: false,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              SizedBox(
                height: 48.h,
                width: 48.h,
                child: const IconButton.outlined(
                  icon: Icon(GjaIcons.barCode),
                  onPressed: null,
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: () => ContagemFooter(
        children: [
          const AppButton(
            label: 'Confirmar contagem',
            height: ButtonSize.large,
            isFullWidth: true,
            isLoading: true,
          ),
          SizedBox(height: AppSpacing.sm),
          const AppButton(
            label: 'Cancelar',
            variant: ButtonVariant.ghost,
            isFullWidth: true,
          ),
        ],
      ),
    ),
    'resumo do check-in': _Tela(
      appBar: () => ContagemAppBar(
        kicker: 'Check-in 3',
        titulo: 'Resumo',
        onVoltar: () {},
      ),
      body: (context) => ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          ResumoNotaCard(nota: notaDevolvida),
          SizedBox(height: AppSpacing.sm),
          ResumoNotaCard(nota: notas.last),
        ],
      ),
      // Estado desabilitado: é o pior caso de largura do rótulo.
      bottom: () => const ContagemFooter(
        children: [
          AppButton(
            label: 'Finalizar Check-in — itens pendentes',
            height: ButtonSize.large,
            variant: ButtonVariant.outline,
            isFullWidth: true,
            onPressed: null,
          ),
        ],
      ),
    ),
    'check-in finalizado': _Tela(
      body: (context) => CheckinFinalizadoPanel(
        checkin: '3',
        resumo: '1 NF(s) recebida(s) · 1 NF(s) para devolução ao fornecedor',
        onNovoCheckin: () {},
      ),
    ),
  };

  /// Monta a tela na composição real do app: ScreenUtilWrapper ->
  /// MaterialApp.router (o AppTopBar chama `context.canPop()`, que exige um
  /// GoRouter na árvore) -> Scaffold.
  Future<void> pump(
    WidgetTester tester, {
    required _Tela tela,
    required Size size,
    required ThemeData theme,
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
            appBar: tela.appBar?.call(),
            body: SafeArea(child: tela.body(context)),
            bottomNavigationBar: tela.bottom?.call(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ScreenUtilWrapper(
        child: MaterialApp.router(
          theme: theme,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump(_animacaoDeTema);
  }

  // ── Tamanho de tela × tema ────────────────────────────────────────────────

  for (final tela in telas.entries) {
    testWidgets('${tela.key}: sem overflow em 6 viewports × 2 temas',
        (tester) async {
      for (final tema in temas.entries) {
        for (final viewport in viewports.entries) {
          await pump(
            tester,
            tela: tela.value,
            size: viewport.value,
            theme: tema.value,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${tela.key} estourou no tema ${tema.key}, '
                'viewport ${viewport.key}',
          );
        }
      }
    });
  }

  // ── Escala de texto (acessibilidade) ──────────────────────────────────────

  for (final escala in [1.3, 1.6, 2.0]) {
    testWidgets('texto em ${escala}x cabe em todas as telas (claro e escuro)',
        (tester) async {
      for (final tema in temas.entries) {
        for (final tela in telas.entries) {
          // Pior caso: a menor tela com o maior texto.
          await pump(
            tester,
            tela: tela.value,
            size: const Size(320, 480),
            theme: tema.value,
            textScale: escala,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${tela.key} estourou em ${escala}x no tema ${tema.key}',
          );
        }
      }
    });
  }

  // ── Cores ─────────────────────────────────────────────────────────────────

  group('cores', () {
    /// Fundo pintado pelo selo, já composto sobre a superfície do card (as
    /// variantes translúcidas só existem depois da composição).
    Color fundoDoSelo(WidgetTester tester, Color superficie) {
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ContagemTag),
              matching: find.byType(Container),
            )
            .first,
      );
      final cor = (container.decoration! as BoxDecoration).color!;
      return Color.alphaBlend(cor, superficie);
    }

    Color textoDoSelo(WidgetTester tester, String label) =>
        tester.widget<Text>(find.text(label)).style!.color!;

    Future<void> pumpSelo(
      WidgetTester tester,
      ThemeData theme,
      ContagemTag selo,
    ) async {
      tester.view
        ..devicePixelRatio = 1.0
        ..physicalSize = const Size(400, 400);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilWrapper(
          child: MaterialApp(
            theme: theme,
            home: Scaffold(body: Center(child: AppCard(child: selo))),
          ),
        ),
      );
      await tester.pump(_animacaoDeTema);
    }

    const selos = <String, ContagemTag>{
      'Conferida': ContagemTag(
        label: 'Conferida',
        variante: ContagemTagVariante.sucesso,
      ),
      'Devolver': ContagemTag(
        label: 'Devolver',
        variante: ContagemTagVariante.alerta,
      ),
      'Pendente': ContagemTag(
        label: 'Pendente',
        variante: ContagemTagVariante.neutro,
      ),
      'Contar': ContagemTag(
        label: 'Contar',
        variante: ContagemTagVariante.contorno,
      ),
    };

    for (final tema in temas.entries) {
      testWidgets('selos têm contraste >= 3:1 no tema ${tema.key}',
          (tester) async {
        final superficie = tema.value.colorScheme.surfaceContainerLow;

        for (final selo in selos.entries) {
          await pumpSelo(tester, tema.value, selo.value);

          final razao = _contraste(
            textoDoSelo(tester, selo.key),
            fundoDoSelo(tester, superficie),
          );
          expect(
            razao,
            greaterThanOrEqualTo(3.0),
            reason: 'selo "${selo.key}" no tema ${tema.key} '
                'ficou em ${razao.toStringAsFixed(2)}:1',
          );
        }
      });
    }

    testWidgets('faixas de mensagem têm contraste >= 3:1 nos dois temas',
        (tester) async {
      for (final tema in temas.entries) {
        for (final tipo in ContagemMensagemTipo.values) {
          tester.view
            ..devicePixelRatio = 1.0
            ..physicalSize = const Size(400, 400);
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            ScreenUtilWrapper(
              child: MaterialApp(
                theme: tema.value,
                home: Scaffold(
                  body: ContagemBanner(
                    mensagem: ContagemMensagem(texto: 'aviso', tipo: tipo),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(_animacaoDeTema);

          final container = tester.widget<Container>(
            find
                .descendant(
                  of: find.byType(ContagemBanner),
                  matching: find.byType(Container),
                )
                .first,
          );
          final fundo = Color.alphaBlend(
            (container.decoration! as BoxDecoration).color!,
            tema.value.colorScheme.surface,
          );
          final texto = tester.widget<Text>(find.text('aviso')).style!.color!;

          final razao = _contraste(texto, fundo);
          expect(
            razao,
            greaterThanOrEqualTo(3.0),
            reason: 'faixa ${tipo.name} no tema ${tema.key} '
                'ficou em ${razao.toStringAsFixed(2)}:1',
          );
        }
      }
    });

    testWidgets('nada é hardcoded: as cores mudam junto com o tema',
        (tester) async {
      Future<(Color fundoCard, Color selo, Color codigo)> amostra(
        ThemeData theme,
      ) async {
        tester.view
          ..devicePixelRatio = 1.0
          ..physicalSize = const Size(400, 800);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ScreenUtilWrapper(
            child: MaterialApp(
              theme: theme,
              home: Scaffold(
                body: ListView(
                  children: [NotaFiscalCard(nota: notaPendente)],
                ),
              ),
            ),
          ),
        );
        await tester.pump(_animacaoDeTema);

        final card = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(AppCard),
                matching: find.byType(Container),
              )
              .first,
        );
        return (
          (card.decoration! as BoxDecoration).color!,
          tester.widget<Text>(find.text('Pendente')).style!.color!,
          tester
              .widget<Text>(find.textContaining('Chave 522604'))
              .style!
              .color!,
        );
      }

      final claro = await amostra(temas['claro']!);
      final escuro = await amostra(temas['escuro']!);

      expect(claro.$1, isNot(escuro.$1), reason: 'fundo do card');
      expect(claro.$2, isNot(escuro.$2), reason: 'texto do selo');
      expect(claro.$3, isNot(escuro.$3), reason: 'código técnico');

      // O tema escuro precisa de fato ser escuro — pega o caso de um card ter
      // ficado preso numa cor clara.
      expect(escuro.$1.computeLuminance(), lessThan(0.2));
      expect(claro.$1.computeLuminance(), greaterThan(0.8));
    });

    test('a paleta semântica existe nos dois temas', () {
      for (final tema in temas.values) {
        expect(tema.extension<AppColorsExtension>(), isNotNull);
      }
    });
  });
}

/// Composição de uma tela, para a matriz montar sempre a árvore real.
class _Tela {
  const _Tela({required this.body, this.appBar, this.bottom});

  final PreferredSizeWidget Function()? appBar;
  final WidgetBuilder body;
  final Widget Function()? bottom;
}

/// Razão de contraste WCAG entre duas cores opacas.
double _contraste(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final claro = math.max(l1, l2);
  final escuro = math.min(l1, l2);
  return (claro + 0.05) / (escuro + 0.05);
}

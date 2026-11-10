import 'package:gjamobile/src/features/inbound/contagem_cega/contagem_item/presentation/widgets/identificacao_item_card.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/contagem_quantidade.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_resultado.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/controllers/contagem_cega_controller.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_app_bar.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_banner.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_footer.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_tag.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gjamobile/src/shared/wrappers/base_state_wrapper.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Contagem de um item: lote lido e quantidade contada.
///
/// A quantidade da NF fica escondida (contagem cega) — só o modo supervisor a
/// revela. Divergiu? A tela **permanece** aberta com a quantidade zerada para a
/// recontagem, até esgotarem as tentativas.
class ContagemItemScreen extends StatefulWidget {
  const ContagemItemScreen({
    super.key,
    required this.notaIndex,
    required this.itemIndex,
  });

  final int notaIndex;
  final int itemIndex;

  @override
  State<ContagemItemScreen> createState() => _ContagemItemScreenState();
}

class _ContagemItemScreenState
    extends BaseState<ContagemItemScreen, ContagemCegaController> {
  @override
  void initState() {
    super.initState();
    // Deep-link/refresh: a nota e o item da URL mandam sobre o que ficou
    // selecionado na sessão. Só os índices — `initState` roda durante o build,
    // e mexer em mensagem/campos aqui (o que `abrirItem` faz) escreveria signal
    // no meio do build. Quem preenche o lote e zera a quantidade é o handler de
    // toque que trouxe até aqui.
    controller.sincronizarRota(
      nota: widget.notaIndex,
      item: widget.itemIndex,
    );
  }

  void _voltarParaItens() => context.go(
        AppRoutes.gjaautoInboundContagemCegaItensPath(widget.notaIndex),
      );

  Future<void> _confirmar() async {
    final resultado = await controller.confirmarContagem();
    if (!mounted) return;
    switch (resultado) {
      // Gravado no SAP: sai da contagem — para o resumo quando esta fechou a
      // última nota, senão para a lista de itens, onde o retorno (conferido ou
      // devolução) aparece como faixa.
      case ContagemResultado.conferido:
      case ContagemResultado.divergenciaConfirmada:
        _sairDaContagem();
      // Fica na tela: o banner já instrui a recontar, a preencher o que faltou
      // ou a tentar gravar de novo — e no caso de falha o botão "Confirmar"
      // logo abaixo já é o retry.
      case ContagemResultado.reconte:
      case ContagemResultado.invalido:
      case ContagemResultado.falhaGravacao:
        break;
    }
  }

  /// Para onde ir depois de uma contagem gravada.
  ///
  /// Se esta foi a contagem que fechou a **última nota pendente**, o check-in
  /// acabou e o destino é o resumo: a lista de itens e a de notas viriam sem
  /// nenhuma decisão a tomar, só dois toques entre o conferente e o botão de
  /// finalizar. Enquanto sobrar nota, o retorno continua sendo a lista de
  /// itens — é lá que está o próximo item a contar.
  ///
  /// "Fechar" inclui a devolução: nota condenada não tem mais o que contar, e
  /// o desfecho de cada NF-e — inclusive quais itens a condenaram — é
  /// justamente o que o resumo mostra na chegada.
  void _sairDaContagem() {
    if (controller.todasResolvidasSignal.value) {
      context.go(AppRoutes.gjaautoInboundContagemCegaResumo);
      return;
    }
    _voltarParaItens();
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(builder: (context) {
      final nota = controller.notaAtual;
      final item = controller.itemAtual;
      final mensagem = controller.mensagemSignal.value;
      final cega = controller.contagemCegaSignal.value;
      final gravando = controller.gravandoSignal.value;

      if (nota == null || item == null) {
        return Scaffold(
          appBar: ContagemAppBar(
            kicker: 'Contagem cega',
            titulo: 'Contagem',
            onVoltar: _voltarParaItens,
          ),
          body: AppEmptyState(
            icon: GjaIcons.inventory,
            title: 'Item não encontrado',
            subtitle: 'Volte à nota e selecione um item para contar.',
            actionLabel: 'Voltar aos itens',
            onAction: _voltarParaItens,
          ),
        );
      }

      return Scaffold(
        appBar: ContagemAppBar(
          kicker: 'NF-e ${nota.numero} · Item ${item.itemXmlLabel}',
          titulo: 'Contagem',
          trailing: ContagemTag(
            label: 'Tentativa ${controller.tentativaLabel}',
            variante: ContagemTagVariante.contorno,
          ),
          onVoltar: _voltarParaItens,
        ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.ms,
            ),
            children: [
              IdentificacaoItemCard(item: item),
              if (mensagem != null) ...[
                SizedBox(height: AppSpacing.md),
                ContagemBanner(mensagem: mensagem),
              ],
              SizedBox(height: AppSpacing.md),
              _buildCampoLote(context, gravando),
              SizedBox(height: AppSpacing.md),
              _buildCampoQuantidade(context, item.unidade, gravando),
              if (!cega) ...[
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Qtd. NF (modo supervisor): ${item.quantidadeNfLabel}',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: ContagemFooter(
          children: [
            AppButton(
              label: 'Confirmar contagem',
              height: ButtonSize.large,
              isFullWidth: true,
              isLoading: gravando,
              onPressed: gravando ? null : _confirmar,
            ),
            SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Cancelar',
              variant: ButtonVariant.ghost,
              isFullWidth: true,
              // Sair no meio da gravação deixaria a tela de itens mostrando um
              // estado que o SAP ainda não confirmou.
              onPressed: gravando ? null : _voltarParaItens,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCampoLote(BuildContext context, bool gravando) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AppTextField(
            label: 'Lote (Batch)',
            hint: 'Digite ou escaneie o lote',
            controller: controller.loteController,
            enabled: !gravando,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => controller.quantidadeFocus.requestFocus(),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        SizedBox(
          height: 48.h,
          width: 48.h,
          child: IconButton.outlined(
            tooltip: 'Escanear lote',
            icon: const Icon(GjaIcons.barCode),
            onPressed: gravando ? null : controller.aplicarLoteLido,
          ),
        ),
      ],
    );
  }

  /// Campo grande e centralizado: é o único número que importa na tela, e o
  /// conferente digita com luva, olhando o material, não o teclado.
  ///
  /// A **unidade do pedido de compra** fica dentro do campo, ao lado do número:
  /// contar 2,5 quando o pedido é em KG e 2,5 quando é em CX são coisas muito
  /// diferentes, e a unidade só no rótulo pequeno de cima passava batido.
  Widget _buildCampoQuantidade(
    BuildContext context,
    String unidade,
    bool gravando,
  ) {
    final estilo = context.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quantidade contada'
          '${unidade.isEmpty ? '' : ' · unidade do pedido: $unidade'}',
          style: context.textTheme.bodySmall
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller.quantidadeController,
          focusNode: controller.quantidadeFocus,
          // A tela abre com o cursor aqui: o lote já vem preenchido da NF-e, e
          // este é o único campo que o conferente sempre digita. Poupa um toque
          // por item e já sobe o teclado numérico — quem precisa corrigir o lote
          // toca no campo de cima, que é a exceção.
          autofocus: true,
          // Decimal: a contagem é na unidade do pedido, e KG/L/M têm fração.
          // O formatter aceita vírgula ou ponto (o teclado do coletor mostra
          // um ou outro conforme o locale) e limita as casas ao que o SAP
          // grava.
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            DecimalInputFormatter(casas: casasDecimaisQuantidade),
          ],
          textInputAction: TextInputAction.done,
          textAlign: TextAlign.center,
          enabled: !gravando,
          // Trava o `onSubmitted` durante a gravação — este é o caminho real do
          // duplo disparo: o leitor físico do coletor manda o Enter, e não é
          // raro ele mandar duas vezes. O guard do controller é o backstop;
          // esta é a primeira linha.
          onSubmitted: gravando ? null : (_) => _confirmar(),
          style: estilo,
          decoration: InputDecoration(
            hintText: '0',
            contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.ms),
            hintStyle: estilo?.copyWith(
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            // Unidade grande, colada no número — é a do pedido de compra.
            suffixText: unidade.isEmpty ? null : unidade,
            suffixStyle: estilo?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

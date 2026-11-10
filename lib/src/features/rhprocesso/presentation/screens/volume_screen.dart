import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/consulta_volume.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/periodo.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/enums/visao_equipe.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/volume_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/rhprocesso_format.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/widgets/rh_tabela.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Seções do resultado da consulta.
enum _Secao { detalhe, notas, resumo }

/// Tela — RH Processo › Volume x NF (`/rh/volume`).
///
/// Visões Consultor e Supervisor: período + matrícula, processar, e o
/// resultado com detalhe, notas, resumo por característica e totais. Daqui
/// saem o PDF de DANFEs ("Gerar NF-e") e a planilha ("Exportar").
class VolumeScreen extends StatefulWidget {
  const VolumeScreen({super.key, this.controller});

  /// Só nos testes; por padrão vem do DI.
  final VolumeController? controller;

  @override
  State<VolumeScreen> createState() => _VolumeScreenState();
}

class _VolumeScreenState extends State<VolumeScreen> {
  late final _controller = widget.controller ?? AppInjector.get<VolumeController>();
  final _matricula = TextEditingController();
  final _secao = signal(_Secao.detalhe);

  @override
  void initState() {
    super.initState();
    final atual = _controller.consulta.value;
    if (atual != null) _matricula.text = atual.equipe.matricula;
    _controller.carregarPeriodos();
  }

  @override
  void dispose() {
    _matricula.dispose();
    _secao.dispose();
    super.dispose();
  }

  void _processar() {
    FocusScope.of(context).unfocus();
    _controller.processar(_matricula.text);
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      appBar: const AppTopBar(title: 'Volume x Nota Fiscal'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Filtros(
            controller: _controller,
            matricula: _matricula,
            onProcessar: _processar,
          ),
          SizedBox(height: AppSpacing.md),
          SignalBuilder(builder: (context) {
            final erro = _controller.erro.value;
            final consulta = _controller.consulta.value;
            if (_controller.consultando.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: AppLoading(message: 'Consultando volume…'),
              );
            }
            if (erro != null) {
              return _MensagemErro(mensagem: erro.message);
            }
            if (consulta == null) {
              return const AppEmptyState(
                icon: GjaIcons.receipt,
                title: 'Informe o período e a matrícula',
                subtitle: 'Depois clique em Processar para ver o volume e '
                    'gerar os DANFEs.',
              );
            }
            return _Resultado(
              consulta: consulta,
              controller: _controller,
              secao: _secao,
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filtros
// ─────────────────────────────────────────────────────────────────────────────

class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.controller,
    required this.matricula,
    required this.onProcessar,
  });

  final VolumeController controller;
  final TextEditingController matricula;
  final VoidCallback onProcessar;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: LayoutBuilder(builder: (context, constraints) {
        final estreito = constraints.maxWidth < 720;
        final largura = estreito ? constraints.maxWidth : 220.0;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: estreito ? constraints.maxWidth : null,
              child: SignalBuilder(builder: (context) {
                return SegmentedButton<VisaoEquipe>(
                  segments: [
                    for (final v in VisaoEquipe.values)
                      ButtonSegment(value: v, label: Text(v.rotulo)),
                  ],
                  selected: {controller.visao.value},
                  onSelectionChanged: (s) => controller.selecionarVisao(s.first),
                );
              }),
            ),
            SizedBox(
              width: largura,
              child: SignalBuilder(builder: (context) {
                final periodos = controller.periodos.value;
                return DropdownButtonFormField<Periodo>(
                  // Recria o campo quando a lista ou a selecao mudam fora dele.
                  key: ValueKey('${periodos.length}-${controller.periodo.value?.valor}'),
                  initialValue: controller.periodo.value,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Período',
                    suffixIcon: controller.carregandoPeriodos.value
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  items: [
                    for (final p in periodos)
                      DropdownMenuItem(value: p, child: Text(p.rotulo)),
                  ],
                  onChanged: controller.selecionarPeriodo,
                );
              }),
            ),
            SizedBox(
              width: largura,
              child: AppTextField(
                label: 'Matrícula',
                hint: 'Ex.: 12345',
                controller: matricula,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onFieldSubmitted: (_) => onProcessar(),
              ),
            ),
            SignalBuilder(builder: (context) {
              return AppButton(
                label: 'Processar',
                prefixIcon: const Icon(GjaIcons.search, size: 18),
                isLoading: controller.consultando.value,
                isFullWidth: estreito,
                onPressed: controller.consultando.value ? null : onProcessar,
              );
            }),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Resultado
// ─────────────────────────────────────────────────────────────────────────────

class _Resultado extends StatelessWidget {
  const _Resultado({
    required this.consulta,
    required this.controller,
    required this.secao,
  });

  final ConsultaVolume consulta;
  final VolumeController controller;
  final Signal<_Secao> secao;

  @override
  Widget build(BuildContext context) {
    final equipe = consulta.equipe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          title: equipe.nome.isEmpty ? 'Matrícula ${equipe.matricula}' : equipe.nome,
          subtitle: 'Matrícula ${equipe.matricula} · ${_intervalo(consulta.periodo)}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final rota in equipe.codigosRotas)
                    Chip(
                      avatar: const Icon(GjaIcons.split),
                      label: Text('Rota $rota'),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              _Acoes(controller: controller),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        _Totais(totais: consulta.totais),
        SizedBox(height: AppSpacing.md),
        if (consulta.vazia)
          const AppEmptyState(
            icon: GjaIcons.inbox,
            title: 'Nenhuma nota no período',
            subtitle: 'A equipe não tem notas fiscais neste período.',
          )
        else ...[
          SignalBuilder(builder: (context) {
            return Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<_Secao>(
                segments: [
                  ButtonSegment(
                    value: _Secao.detalhe,
                    label: Text('Detalhe (${consulta.detalhe.length})'),
                  ),
                  ButtonSegment(
                    value: _Secao.notas,
                    label: Text('Notas (${consulta.notas.length})'),
                  ),
                  ButtonSegment(
                    value: _Secao.resumo,
                    label: Text('Resumo (${consulta.resumo.length})'),
                  ),
                ],
                selected: {secao.value},
                onSelectionChanged: (s) => secao.value = s.first,
              ),
            );
          }),
          SizedBox(height: AppSpacing.sm),
          SignalBuilder(builder: (context) {
            return switch (secao.value) {
              _Secao.detalhe => _TabelaDetalhe(itens: consulta.detalhe),
              _Secao.notas => _TabelaNotas(notas: consulta.notas),
              _Secao.resumo => _TabelaResumo(resumo: consulta.resumo),
            };
          }),
        ],
      ],
    );
  }
}

/// `202608` -> `01/08/2026 a 31/08/2026`.
String _intervalo(String periodo) {
  final p = Periodo(periodo);
  if (!p.valido) return p.rotulo;
  final ano = int.parse(periodo.substring(0, 4));
  final mes = int.parse(periodo.substring(4));
  return '${RhFormat.data(DateTime(ano, mes))} a ${RhFormat.data(DateTime(ano, mes + 1, 0))}';
}

class _Acoes extends StatelessWidget {
  const _Acoes({required this.controller});

  final VolumeController controller;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(builder: (context) {
      final gerando = controller.gerandoDanfe.value;
      final exportando = controller.exportando.value;
      final pode = controller.podeGerar;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          AppButton(
            label: gerando ? 'Gerando…' : 'Gerar NF-e',
            prefixIcon: const Icon(GjaIcons.pdfAttachment, size: 18),
            height: ButtonSize.small,
            isLoading: gerando,
            onPressed: pode && !gerando ? controller.gerarDanfe : null,
          ),
          AppButton(
            label: exportando ? 'Exportando…' : 'Exportar',
            variant: ButtonVariant.outline,
            prefixIcon: const Icon(GjaIcons.tableView, size: 18),
            height: ButtonSize.small,
            isLoading: exportando,
            onPressed: pode && !exportando ? controller.exportarPlanilha : null,
          ),
        ],
      );
    });
  }
}

class _Totais extends StatelessWidget {
  const _Totais({required this.totais});

  final TotaisVolume totais;

  @override
  Widget build(BuildContext context) {
    // Mesmas caixas (e ordem) da tela do desktop.
    final itens = [
      ('Valor Total Unidade', null, RhFormat.moeda(totais.valorUnitario)),
      ('Valor Imposto Item', '(ICMS Subst. + IPI)', RhFormat.moeda(totais.valorImpostoUnitario)),
      ('Valor Total Imposto', '(ICMS Subst. + IPI)', RhFormat.moeda(totais.valorImpostoTotal)),
      ('Valor Total (Unid + Imp)', null, RhFormat.moeda(totais.valorUnitarioComImposto)),
      ('Valor Total Item (Sem Imp)', null, RhFormat.moeda(totais.valorSemImposto)),
      ('Valor Total Item (Com Imp)', '(ICMS Subst. + IPI)', RhFormat.moeda(totais.valorComImposto)),
      ('Volume Total', '(CX Unitária)', 'CXU ${RhFormat.decimal(totais.quantidadeCxu)}'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final (rotulo, detalhe, valor) in itens)
              SizedBox(
                width: 190,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rotulo, style: context.textTheme.labelMedium),
                      if (detalhe != null)
                        Text(detalhe, style: context.textTheme.bodySmall),
                      SizedBox(height: AppSpacing.xs),
                      Text(valor, style: context.textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          '${RhFormat.inteiro(totais.quantidadeItens)} registros referente a '
          '${RhFormat.inteiro(totais.quantidadeNotas)} NF-e · '
          'valor das notas ${RhFormat.moeda(totais.valorNotas)}',
          style: context.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _TabelaDetalhe extends StatelessWidget {
  const _TabelaDetalhe({required this.itens});

  final List<ItemVolume> itens;

  @override
  Widget build(BuildContext context) {
    return RhTabela<ItemVolume>(
      colunas: const [
        RhColuna('Unidade'),
        RhColuna('Nota'),
        RhColuna('Emissão'),
        RhColuna('Prest. contas'),
        RhColuna('Rota'),
        RhColuna('Produto'),
        RhColuna('Descrição'),
        RhColuna('Característica'),
        RhColuna('Qtd.', numerica: true),
        RhColuna('CXU', numerica: true),
        RhColuna('Vlr. unid.', numerica: true),
        RhColuna('Vlr. imp. unit.', numerica: true),
        RhColuna('Vlr. imp. total', numerica: true),
        RhColuna('Vlr. unid. + imp.', numerica: true),
        RhColuna('Total item s/ imp.', numerica: true),
        RhColuna('Total item c/ imp.', numerica: true),
        RhColuna('Status'),
        RhColuna('Op. fiscal'),
      ],
      itens: itens,
      celulas: (i) => [
        Text(i.unidade),
        Text(i.numeroNota),
        Text(RhFormat.data(i.dataEmissao)),
        Text(RhFormat.data(i.dataPrestacao)),
        Text(i.rota),
        Text(i.codigoProduto),
        Text(i.descricaoProduto),
        Text(RhFormat.texto(i.caracteristica)),
        Text(RhFormat.decimal(i.quantidade)),
        Text(RhFormat.cxu(i.quantidadeCxu)),
        Text(RhFormat.moeda(i.valorUnitario)),
        Text(RhFormat.moeda(i.valorImpostoUnitario)),
        Text(RhFormat.moeda(i.valorImpostoTotal)),
        Text(RhFormat.moeda(i.valorUnitarioComImposto)),
        Text(RhFormat.moeda(i.valorTotalSemImposto)),
        Text(RhFormat.moeda(i.valorTotalComImposto)),
        Text(RhFormat.texto(i.status)),
        Text(RhFormat.texto(i.operacaoFiscal)),
      ],
    );
  }
}

class _TabelaNotas extends StatelessWidget {
  const _TabelaNotas({required this.notas});

  final List<NotaVolume> notas;

  @override
  Widget build(BuildContext context) {
    return RhTabela<NotaVolume>(
      colunas: const [
        RhColuna('Unidade'),
        RhColuna('Nota'),
        RhColuna('Emissão'),
        RhColuna('Prest. contas'),
        RhColuna('Rota'),
        RhColuna('Op. fiscal'),
        RhColuna('Valor', numerica: true),
      ],
      itens: notas,
      celulas: (n) => [
        Text(n.unidade),
        Text(n.numero),
        Text(RhFormat.data(n.dataEmissao)),
        Text(RhFormat.data(n.dataPrestacao)),
        Text(n.rota),
        Text(RhFormat.texto(n.operacaoFiscal)),
        Text(RhFormat.moeda(n.valorNota)),
      ],
    );
  }
}

class _TabelaResumo extends StatelessWidget {
  const _TabelaResumo({required this.resumo});

  final List<ResumoCaracteristica> resumo;

  @override
  Widget build(BuildContext context) {
    return RhTabela<ResumoCaracteristica>(
      colunas: const [
        RhColuna('Característica'),
        RhColuna('Volume (CXU)', numerica: true),
        RhColuna('Valor', numerica: true),
      ],
      itens: resumo,
      celulas: (r) => [
        Text(r.caracteristica),
        Text(RhFormat.cxu(r.quantidadeCxu)),
        Text(RhFormat.moeda(r.valor)),
      ],
    );
  }
}

class _MensagemErro extends StatelessWidget {
  const _MensagemErro({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return AppCard(
      color: cores.errorContainer,
      child: Row(
        children: [
          Icon(GjaIcons.error, color: cores.onErrorContainer),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              mensagem,
              style: context.textTheme.bodyMedium
                  ?.copyWith(color: cores.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/integracoes/data/models/models.dart';
import 'package:gjamobile/src/features/integracoes/presentation/controllers/integracoes_controller.dart';
import 'package:gjamobile/src/features/integracoes/presentation/integracao_format.dart';
import 'package:gjamobile/src/features/integracoes/presentation/widgets/integracao_status_badge.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela — Gerenciamento de Deltas (`/ga/integracoes`).
///
/// Lista todos os processos de integracao do catalogo, inclusive os
/// desativados no ambiente, e permite disparar qualquer um sob demanda. Tabela
/// em telas largas, cards em telas estreitas, como as demais listas do portal.
class IntegracoesScreen extends StatefulWidget {
  const IntegracoesScreen({super.key});

  @override
  State<IntegracoesScreen> createState() => _IntegracoesScreenState();
}

class _IntegracoesScreenState extends State<IntegracoesScreen> {
  final _controller = AppInjector.get<IntegracoesController>();
  late final TextEditingController _busca;

  @override
  void initState() {
    super.initState();
    _busca = TextEditingController(text: _controller.busca.value);
    // Volta para a tela: mostra o que ja tem e revalida sem piscar o loading.
    if (_controller.processos.value.isEmpty) {
      _controller.load();
    } else {
      _controller.refresh();
    }
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  void _limpar() {
    _busca.clear();
    _controller.limparFiltros();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      scrollable: false,
      appBar: AppTopBar(
        title: 'Gerenciamento de Deltas',
        actions: [
          SignalBuilder(builder: (context) {
            if (_controller.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            return IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(GjaIcons.refresh),
              onPressed: _controller.refresh,
            );
          }),
        ],
      ),
      body: Column(
        children: [
          _Filtros(controller: _controller, busca: _busca, onLimpar: _limpar),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _controller.refresh,
              child: SignalBuilder(builder: (context) {
                final todos = _controller.processos.value;
                final visiveis = _controller.visiveis.value;
                final carregando = _controller.isLoading.value;
                final erro = _controller.error.value;

                if (carregando && todos.isEmpty) {
                  return const AppLoading(message: 'Carregando processos…');
                }
                if (erro != null && todos.isEmpty) {
                  return AppErrorWidget(
                    title: 'Não foi possível carregar os processos',
                    message: erro.message,
                    onRetry: _controller.load,
                  );
                }
                if (todos.isEmpty) {
                  return ListView(children: [
                    SizedBox(height: context.height * 0.12),
                    const AppEmptyState(
                      icon: GjaIcons.synchronize,
                      title: 'Nenhum processo de integração',
                      subtitle: 'O catálogo de rotinas está vazio.',
                    ),
                  ]);
                }
                if (visiveis.isEmpty) {
                  return ListView(children: [
                    SizedBox(height: context.height * 0.12),
                    AppEmptyState(
                      icon: GjaIcons.sysFind,
                      title: 'Nenhum processo para estes filtros',
                      subtitle: 'Ajuste a busca ou limpe os filtros.',
                      actionLabel: 'Limpar filtros',
                      onAction: _limpar,
                    ),
                  ]);
                }
                return IntegracoesConteudo(
                  processos: visiveis,
                  total: todos.length,
                  sortColumn: _controller.sortColumn.value,
                  sortAscending: _controller.sortAscending.value,
                  executandoNome: _controller.executandoNome.value,
                  onSort: _controller.ordenarPor,
                  onExecutar: _controller.executarAgora,
                );
              }),
            ),
          ),
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
    required this.busca,
    required this.onLimpar,
  });

  final IntegracoesController controller;
  final TextEditingController busca;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: LayoutBuilder(builder: (context, constraints) {
        final estreito = constraints.maxWidth < 720;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: estreito ? constraints.maxWidth : 280,
              child: SignalBuilder(builder: (context) {
                final temTexto = controller.busca.value.isNotEmpty;
                return AppTextField(
                  hint: 'Buscar por nome, descrição ou recurso',
                  controller: busca,
                  prefixIcon: const Icon(GjaIcons.search, size: 18),
                  suffixIcon: temTexto
                      ? IconButton(
                          icon: const Icon(GjaIcons.decline, size: 18),
                          onPressed: () {
                            busca.clear();
                            controller.setBusca('');
                          },
                        )
                      : null,
                  onChanged: controller.setBusca,
                );
              }),
            ),
            SignalBuilder(builder: (context) {
              return FilterChip(
                label: const Text('Somente ativos'),
                selected: controller.apenasAtivos.value,
                onSelected: (_) => controller.alternarApenasAtivos(),
              );
            }),
            SignalBuilder(builder: (context) {
              return TextButton(
                onPressed: controller.temFiltroAtivo ? onLimpar : null,
                child: const Text('Limpar'),
              );
            }),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conteúdo: tabela em telas largas, cards em telas estreitas
// ─────────────────────────────────────────────────────────────────────────────

typedef OnSortProcesso = void Function(ProcessoSortColumn coluna, bool ascendente);

/// Tabela em telas largas, cards em telas estreitas.
///
/// Publico (e nao `_Conteudo`) para o teste de layout poder monta-lo com
/// larguras controladas sem subir o injector da app inteira.
@visibleForTesting
class IntegracoesConteudo extends StatelessWidget {
  const IntegracoesConteudo({
    super.key,
    required this.processos,
    required this.total,
    required this.sortColumn,
    required this.sortAscending,
    required this.executandoNome,
    required this.onSort,
    required this.onExecutar,
  });

  final List<ProcessoIntegracao> processos;
  final int total;
  final ProcessoSortColumn sortColumn;
  final bool sortAscending;
  final String? executandoNome;
  final OnSortProcesso onSort;
  final ValueChanged<String> onExecutar;

  /// Abaixo desta largura a tela usa cards. Derivado das larguras das colunas.
  static double get larguraMinimaTabela => _Tabela.larguraMinimaTabela;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final contagem = _Contagem(visiveis: processos.length, total: total);
      // O corte vem das larguras das colunas, nao de um numero solto: abaixo
      // dele a tabela nao caberia na janela e voltaria a rolagem horizontal.
      if (constraints.maxWidth >= _Tabela.larguraMinimaTabela) {
        return Column(
          children: [
            contagem,
            Expanded(
              child: _Tabela(
                processos: processos,
                sortColumn: sortColumn,
                sortAscending: sortAscending,
                executandoNome: executandoNome,
                onSort: onSort,
                onExecutar: onExecutar,
              ),
            ),
          ],
        );
      }
      return Column(
        children: [
          contagem,
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              itemCount: processos.length,
              itemBuilder: (_, i) => _ProcessoTile(
                processo: processos[i],
                disparando: executandoNome == processos[i].nome,
                onExecutar: () => onExecutar(processos[i].nome),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _Contagem extends StatelessWidget {
  const _Contagem({required this.visiveis, required this.total});

  final int visiveis;
  final int total;

  @override
  Widget build(BuildContext context) {
    final texto = visiveis == total
        ? '$total ${total == 1 ? 'processo' : 'processos'}'
        : '$visiveis de $total processos';
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Text(
          texto,
          style: context.textTheme.bodySmall
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ),
    );
  }
}

enum _Col { processo, tipo, status, ultima, duracao, registros, proxima, acoes }

ProcessoSortColumn? _chaveDeOrdenacao(_Col c) => switch (c) {
      _Col.processo => ProcessoSortColumn.nome,
      _Col.tipo => ProcessoSortColumn.tipo,
      _Col.status => ProcessoSortColumn.status,
      _Col.ultima => ProcessoSortColumn.ultimaExecucao,
      _Col.proxima => ProcessoSortColumn.proximaExecucao,
      _Col.duracao || _Col.registros || _Col.acoes => null,
    };

String _rotulo(_Col c) => switch (c) {
      _Col.processo => 'Processo',
      _Col.tipo => 'Tipo',
      _Col.status => 'Status',
      // Rotulos curtos: o cabecalho e quem dita a largura da coluna no
      // DataTable, e "Ultima execucao"/"Proxima execucao" sozinhos custavam
      // mais de 200px cada, empurrando a coluna de acoes para fora da janela.
      _Col.ultima => 'Última',
      _Col.duracao => 'Duração',
      _Col.registros => 'Registros',
      _Col.proxima => 'Próxima',
      _Col.acoes => 'Ações',
    };

class _Tabela extends StatelessWidget {
  const _Tabela({
    required this.processos,
    required this.sortColumn,
    required this.sortAscending,
    required this.executandoNome,
    required this.onSort,
    required this.onExecutar,
  });

  final List<ProcessoIntegracao> processos;
  final ProcessoSortColumn sortColumn;
  final bool sortAscending;
  final String? executandoNome;
  final OnSortProcesso onSort;
  final ValueChanged<String> onExecutar;

  static const _cols = _Col.values;

  /// Espacamento entre colunas (padrao do Material e 56, largo demais para 8).
  static const _espacamentoColunas = 16.0;

  /// Margem nas bordas da tabela (padrao 24).
  static const _margemHorizontal = 8.0;

  /// Quanto as sete colunas fora "Processo" ocupam somadas — conteudo mais
  /// espacamento. As de data cabem "03/09/2026 as 16:08"; as demais sao curtas
  /// (Delta / Carga completa, um badge, "537 ms", contadores, o icone de play).
  /// O que sobrar da largura vai para "Processo", que e a coluna elastica.
  ///
  /// Os valores sao medidos, nao estimados: o DataTable dimensiona a coluna
  /// pelo maior conteudo — e o cabecalho, com o icone de ordenacao, costuma ser
  /// o maior. `integracoes_layout_test` reprova se a soma sair do lugar.
  static const _larguraDasDemaisColunas = 92.0 + // tipo
      112.0 + // status (badge)
      152.0 + // ultima
      104.0 + // duracao
      132.0 + // registros
      152.0 + // proxima
      76.0 + // acoes (IconButton)
      _espacamentoColunas * 7 +
      _margemHorizontal * 2;

  /// Minimo da coluna elastica. Somado a `_larguraDasDemaisColunas` define a
  /// largura minima da tabela — e por isso o ponto de corte para cards
  /// ([_larguraMinimaTabela]) nao pode ser menor que essa soma, senao a tabela
  /// volta a estourar a janela.
  static const _larguraMinimaProcesso = 120.0;

  /// Abaixo disto a tela usa cards: 8 colunas nao cabem legiveis.
  static const larguraMinimaTabela =
      _larguraDasDemaisColunas + _larguraMinimaProcesso;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final indiceOrdenado =
        _cols.indexWhere((c) => _chaveDeOrdenacao(c) == sortColumn);

    return LayoutBuilder(builder: (context, constraints) {
      // Sem rolagem horizontal: as 8 colunas cabem na largura disponivel. As
      // sete de dado tem largura previsivel (data, duracao, contadores, o
      // icone de acao), entao a coluna "Processo" fica com o que sobrar — e
      // ela que absorve a variacao de tamanho da janela.
      final larguraProcesso = (constraints.maxWidth - _larguraDasDemaisColunas)
          .clamp(_larguraMinimaProcesso, 420.0);

      return SingleChildScrollView(
        child: DataTable(
          showCheckboxColumn: false,
          // Padrao e 56; apertado o suficiente para as 8 colunas caberem sem
          // espremer o texto.
          columnSpacing: _espacamentoColunas,
          horizontalMargin: _margemHorizontal,
          // A celula "Processo" empilha nome + descricao de ate duas linhas, o
          // que passa da altura padrao (48) e estoura a linha por poucos pixels.
          dataRowMinHeight: 64,
          dataRowMaxHeight: 76,
          sortColumnIndex: indiceOrdenado >= 0 ? indiceOrdenado : null,
          sortAscending: sortAscending,
          headingRowColor: WidgetStatePropertyAll(
              cs.surfaceContainerHighest.withValues(alpha: 0.4)),
          columns: [
            for (final c in _cols)
              DataColumn(
                label: Text(_rotulo(c), overflow: TextOverflow.ellipsis),
                onSort: _chaveDeOrdenacao(c) == null
                    ? null
                    : (indice, ascendente) =>
                        onSort(_chaveDeOrdenacao(_cols[indice])!, ascendente),
              ),
          ],
          rows: [
            for (final p in processos)
              DataRow(cells: [
                for (final c in _cols)
                  _celula(context, p, c, larguraProcesso: larguraProcesso),
              ]),
          ],
        ),
      );
    });
  }

  DataCell _celula(BuildContext context, ProcessoIntegracao p, _Col col,
      {required double larguraProcesso}) {
    final tt = context.textTheme;
    final cs = context.colors;
    final ultima = p.ultimaExecucao;

    switch (col) {
      case _Col.processo:
        return DataCell(SizedBox(
          width: larguraProcesso,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(
                p.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ));
      case _Col.tipo:
        return DataCell(Text(p.tipo.label));
      case _Col.status:
        return DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IntegracaoStatusBadge(status: p.statusExibido, ativo: p.ativo),
            if (ultima?.mensagemErro != null) ...[
              SizedBox(width: AppSpacing.xs),
              Tooltip(
                message: ultima!.mensagemErro!,
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(GjaIcons.information, size: 16, color: cs.error),
              ),
            ],
          ],
        ));
      case _Col.ultima:
        return DataCell(_DataCompacta(quando: ultima?.iniciadoEm));
      case _Col.duracao:
        return DataCell(Text(IntegracaoFormat.duracao(ultima?.duracaoMs)));
      case _Col.registros:
        return DataCell(Text(ultima == null
            ? '—'
            : IntegracaoFormat.registros(
                processados: ultima.registrosProcessados,
                inseridos: ultima.registrosInseridos,
                atualizados: ultima.registrosAtualizados,
              )));
      case _Col.proxima:
        return DataCell(_DataCompacta(quando: p.proximaExecucao));
      case _Col.acoes:
        return DataCell(_BotaoExecutar(
          processo: p,
          disparando: executandoNome == p.nome,
          onExecutar: () => onExecutar(p.nome),
          compacto: true,
        ));
    }
  }
}

/// Data curta na tabela (`03/09 16:08`), com a forma completa no tooltip.
///
/// A forma por extenso ocupa mais de 200px por coluna; com duas colunas de data
/// isso e o bastante para empurrar a coluna de acoes para fora da janela.
class _DataCompacta extends StatelessWidget {
  const _DataCompacta({required this.quando});

  final DateTime? quando;

  @override
  Widget build(BuildContext context) {
    final curta = Text(IntegracaoFormat.dataHoraCompacta(quando));
    if (quando == null) return curta;
    return Tooltip(message: IntegracaoFormat.dataHora(quando), child: curta);
  }
}

/// Botao "Executar agora", desabilitado com o motivo no tooltip.
///
/// O motivo vem do backend (integração desligada, processo já rodando, outro
/// processo do mesmo recurso à frente): sem ele o administrador ficaria diante
/// de um botão cinza sem saber o que fazer.
class _BotaoExecutar extends StatelessWidget {
  const _BotaoExecutar({
    required this.processo,
    required this.disparando,
    required this.onExecutar,
    this.compacto = false,
  });

  final ProcessoIntegracao processo;
  final bool disparando;
  final VoidCallback onExecutar;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    if (disparando) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final habilitado = processo.podeExecutar;
    final botao = compacto
        ? IconButton(
            tooltip: habilitado ? 'Executar agora' : null,
            icon: const Icon(GjaIcons.mediaPlay, size: 20),
            onPressed: habilitado ? onExecutar : null,
          )
        : AppButton(
            label: 'Executar agora',
            variant: ButtonVariant.outline,
            prefixIcon: const Icon(GjaIcons.mediaPlay, size: 18),
            onPressed: habilitado ? onExecutar : null,
          );

    final motivo = processo.motivoIndisponivel;
    if (habilitado || motivo == null) return botao;
    return Tooltip(message: motivo, child: botao);
  }
}

class _ProcessoTile extends StatelessWidget {
  const _ProcessoTile({
    required this.processo,
    required this.disparando,
    required this.onExecutar,
  });

  final ProcessoIntegracao processo;
  final bool disparando;
  final VoidCallback onExecutar;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    final ultima = processo.ultimaExecucao;

    return AppCard(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(processo.nome,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              IntegracaoStatusBadge(
                  status: processo.statusExibido, ativo: processo.ativo),
            ],
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(processo.descricao,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Tipo: ${processo.tipo.label}  ·  Recurso: ${processo.grupoRecurso}',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          Text(
            'Última: ${IntegracaoFormat.dataHora(ultima?.iniciadoEm)}'
            '  ·  Duração: ${IntegracaoFormat.duracao(ultima?.duracaoMs)}',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          Text(
            'Registros: ${ultima == null ? '—' : IntegracaoFormat.registros(
                processados: ultima.registrosProcessados,
                inseridos: ultima.registrosInseridos,
                atualizados: ultima.registrosAtualizados,
              )}'
            '  ·  Próxima: ${IntegracaoFormat.dataHora(processo.proximaExecucao)}',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (ultima?.mensagemErro != null) ...[
            SizedBox(height: AppSpacing.xs),
            Text(ultima!.mensagemErro!,
                style: tt.bodySmall?.copyWith(color: cs.error)),
          ],
          if (!processo.podeExecutar && processo.motivoIndisponivel != null) ...[
            SizedBox(height: AppSpacing.xs),
            Text(processo.motivoIndisponivel!,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
          SizedBox(height: AppSpacing.sm),
          _BotaoExecutar(
            processo: processo,
            disparando: disparando,
            onExecutar: onExecutar,
          ),
        ],
      ),
    );
  }
}

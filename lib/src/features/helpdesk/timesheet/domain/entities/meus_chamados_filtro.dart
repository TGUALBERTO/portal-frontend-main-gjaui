import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/tipo_vinculo.dart';

/// Filtro ativo do painel "Meus chamados".
///
/// Não reaproveita o `DashboardFilter` do BI porque aquele não expõe
/// `urgencia`/`status` no `copyWith` (só os copia) e não tem `tipoVinculo` nem
/// `termo` — esticá-lo para caber aqui mudaria o contrato de outra feature.
///
/// [status] e [apenasAbertos] são mutuamente exclusivos, espelhando o backend:
/// informar um status específico vence a restrição de "em aberto".
class MeusChamadosFiltro extends Equatable {
  const MeusChamadosFiltro({
    this.dataIni,
    this.dataFim,
    this.empresaNome,
    this.urgencia,
    this.status,
    this.apenasAbertos = true,
    this.tipoVinculo,
    this.termo = '',
  });

  /// Período de **abertura** do chamado (`data_criacao`).
  final DateTime? dataIni;
  final DateTime? dataFim;

  /// Nome normalizado da empresa (mesmo canal do BI, via `/dashboards/filtros`).
  final String? empresaNome;

  final int? urgencia;

  /// Código de status do GLPI (1..6). Nulo com [apenasAbertos] = a lista abre
  /// mostrando só o que está em andamento, que é o padrão pedido.
  final int? status;

  final bool apenasAbertos;
  final TipoVinculo? tipoVinculo;

  /// Busca livre por título ou número; vazio = sem busca.
  final String termo;

  /// Flags de limpeza porque `copyWith` não distingue "não mexi" de "quero
  /// nulo" — mesmo padrão do `DashboardFilter`.
  MeusChamadosFiltro copyWith({
    DateTime? dataIni,
    DateTime? dataFim,
    String? empresaNome,
    int? urgencia,
    int? status,
    bool? apenasAbertos,
    TipoVinculo? tipoVinculo,
    String? termo,
    bool limparPeriodo = false,
    bool limparEmpresa = false,
    bool limparUrgencia = false,
    bool limparStatus = false,
    bool limparVinculo = false,
  }) {
    return MeusChamadosFiltro(
      dataIni: limparPeriodo ? null : (dataIni ?? this.dataIni),
      dataFim: limparPeriodo ? null : (dataFim ?? this.dataFim),
      empresaNome: limparEmpresa ? null : (empresaNome ?? this.empresaNome),
      urgencia: limparUrgencia ? null : (urgencia ?? this.urgencia),
      status: limparStatus ? null : (status ?? this.status),
      apenasAbertos: apenasAbertos ?? this.apenasAbertos,
      tipoVinculo: limparVinculo ? null : (tipoVinculo ?? this.tipoVinculo),
      termo: termo ?? this.termo,
    );
  }

  /// `true` quando algo além do padrão está aplicado — liga o "Limpar filtros".
  /// O período inicial (últimos 12 meses) não conta como filtro do usuário.
  bool get temFiltroAtivo => filtrosAtivos > 0;

  /// Quantos filtros o usuário aplicou — o número do rótulo quando a seção
  /// está recolhida, que é o que diz se vale a pena abri-la.
  ///
  /// Conta exatamente o que [temFiltroAtivo] considera (o período de fora, o
  /// termo de busca dentro): o contador e o botão "Limpar" precisam concordar,
  /// senão a tela mostra "1 ativo" sem oferecer como limpar.
  int get filtrosAtivos {
    var n = 0;
    if (empresaNome != null) n++;
    if (urgencia != null) n++;
    // Status e "apenas abertos" são o mesmo seletor na tela: um código
    // específico ou "todos" (que desliga o padrão) valem um filtro, não dois.
    if (status != null || !apenasAbertos) n++;
    if (tipoVinculo != null) n++;
    if (termo.trim().isNotEmpty) n++;
    return n;
  }

  @override
  List<Object?> get props => [
        dataIni,
        dataFim,
        empresaNome,
        urgencia,
        status,
        apenasAbertos,
        tipoVinculo,
        termo,
      ];
}

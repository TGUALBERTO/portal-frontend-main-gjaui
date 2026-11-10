import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/chamado.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/tipo_vinculo.dart';

/// Chamado do usuário logado, retornado por `GET /helpdesk/meus-chamados`.
///
/// É uma entidade separada da [Chamado] de propósito: aquela é o modelo do
/// autocomplete (HAL, id extraído de `_links.self.href`, 4 campos), esta vem de
/// um DTO JSON plano com todos os campos da listagem. Fundir as duas deixaria
/// metade dos campos nulos em cada uso, e o `props` da [Chamado] — que decide a
/// igualdade nas sugestões do autocomplete — passaria a comparar campos
/// irrelevantes.
class ChamadoResumo extends Equatable {
  /// UUID do chamado no portal. É o que o POST de apontamento espera em
  /// `chamadoId` — por isso o painel consegue abrir o formulário já preenchido.
  final String id;

  /// Número do ticket no GLPI: o que o usuário reconhece e cita.
  final int origemId;

  final String titulo;
  final String? empresaNome;
  final int? status;
  final String? statusLabel;

  /// Urgência (código GLPI 1..5). A origem não tem mapa de rótulo para ela, só
  /// o código — o rótulo é montado no frontend por [urgenciaLabel].
  final int? urgencia;

  final int? prioridade;
  final String? prioridadeLabel;
  final int? tipo;
  final String? tipoLabel;
  final String? categoria;
  final DateTime? dataCriacao;
  final DateTime? dataSolucao;
  final DateTime? prazoSolucao;
  final bool emAberto;

  /// Papéis do usuário neste chamado. É uma lista porque quem abre um chamado
  /// pode também atendê-lo — nesse caso o card mostra os dois selos.
  final List<TipoVinculo> vinculos;

  const ChamadoResumo({
    required this.id,
    required this.origemId,
    required this.titulo,
    required this.empresaNome,
    required this.status,
    required this.statusLabel,
    required this.urgencia,
    required this.prioridade,
    required this.prioridadeLabel,
    required this.tipo,
    required this.tipoLabel,
    required this.categoria,
    required this.dataCriacao,
    required this.dataSolucao,
    required this.prazoSolucao,
    required this.emAberto,
    required this.vinculos,
  });

  factory ChamadoResumo.fromJson(Map<String, dynamic> json) {
    return ChamadoResumo(
      id: (json['id'] as String?) ?? '',
      origemId: (json['origemId'] as num?)?.toInt() ?? 0,
      titulo: (json['titulo'] as String?) ?? '',
      empresaNome: json['empresaNome'] as String?,
      status: (json['status'] as num?)?.toInt(),
      statusLabel: json['statusLabel'] as String?,
      urgencia: (json['urgencia'] as num?)?.toInt(),
      prioridade: (json['prioridade'] as num?)?.toInt(),
      prioridadeLabel: json['prioridadeLabel'] as String?,
      tipo: (json['tipo'] as num?)?.toInt(),
      tipoLabel: json['tipoLabel'] as String?,
      categoria: json['categoria'] as String?,
      dataCriacao: _data(json['dataCriacao']),
      dataSolucao: _data(json['dataSolucao']),
      prazoSolucao: _data(json['prazoSolucao']),
      emAberto: json['emAberto'] as bool? ?? false,
      vinculos: _vinculos(json['vinculos']),
    );
  }

  static DateTime? _data(dynamic valor) =>
      valor is String ? DateTime.tryParse(valor) : null;

  /// Códigos desconhecidos são descartados (ver [TipoVinculo.fromCodigo]).
  static List<TipoVinculo> _vinculos(dynamic valor) {
    if (valor is! List) return const [];
    return valor
        .map((e) => TipoVinculo.fromCodigo((e as num?)?.toInt()))
        .nonNulls
        .toList();
  }

  /// Converte para o modelo que o formulário de apontamento consome. Só o UUID
  /// e o número são realmente necessários lá; o título alimenta o rótulo do
  /// campo travado.
  Chamado toChamado() => Chamado(
        id: id,
        origemId: origemId,
        titulo: titulo,
        dataCriacao: dataCriacao,
      );

  /// Rótulo pt-BR da urgência (GLPI 1..5). Vem do frontend porque a origem não
  /// mantém tabela de referência para esse código.
  String? get urgenciaLabel => switch (urgencia) {
        1 => 'Muito baixa',
        2 => 'Baixa',
        3 => 'Média',
        4 => 'Alta',
        5 => 'Muito alta',
        _ => null,
      };

  /// Prazo de solução vencido e chamado ainda sem solução.
  bool get atrasado {
    final prazo = prazoSolucao;
    return prazo != null && dataSolucao == null && prazo.isBefore(DateTime.now());
  }

  /// `#4242 — Título`, mesmo formato do autocomplete.
  String get label => '#$origemId — $titulo';

  @override
  List<Object?> get props => [id, origemId, titulo, status, vinculos];
}

/// Uma página de [ChamadoResumo] — envelope JSON plano do endpoint custom
/// (não é HAL, então não tem `_embedded`/`_links`).
class PaginaChamados {
  const PaginaChamados({
    required this.itens,
    required this.pagina,
    required this.totalElementos,
    required this.totalPaginas,
  });

  final List<ChamadoResumo> itens;
  final int pagina;
  final int totalElementos;
  final int totalPaginas;

  factory PaginaChamados.fromJson(Map<String, dynamic> json) {
    final conteudo = json['conteudo'];
    return PaginaChamados(
      itens: conteudo is List
          ? conteudo
              .whereType<Map<String, dynamic>>()
              .map(ChamadoResumo.fromJson)
              .toList()
          : const [],
      pagina: (json['pagina'] as num?)?.toInt() ?? 0,
      totalElementos: (json['totalElementos'] as num?)?.toInt() ?? 0,
      totalPaginas: (json['totalPaginas'] as num?)?.toInt() ?? 0,
    );
  }
}

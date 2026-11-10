import 'package:equatable/equatable.dart';

/// Filtro comum a todos os dashboards do BI. Espelha o `DashboardFilter` do
/// backend; enviado como query string em `GET /dashboards/*`. Campos nulos não
/// entram na query (predicados condicionais no backend).
class DashboardFilter extends Equatable {
  final int? empresa;

  /// Filtro por NOME de empresa (rótulo normalizado). É o canal usado pela barra
  /// de filtros — um nome agrupa todos os `entidade_id` com o mesmo rótulo
  /// (ex.: "BANDEIRANTES" cobre os ids 5 e 9). O `empresa` (id) segue para
  /// drill-down/retrocompatibilidade.
  final String? empresaNome;
  final DateTime? inicio;
  final DateTime? fim;
  final int? grupo;
  final int? usuario;
  final int? sistema;
  final int? categoria;
  final int? tipo;
  final int? prioridade;
  final int? urgencia;
  final int? impacto;
  final int? status;
  final int? localizacao;

  const DashboardFilter({
    this.empresa,
    this.empresaNome,
    this.inicio,
    this.fim,
    this.grupo,
    this.usuario,
    this.sistema,
    this.categoria,
    this.tipo,
    this.prioridade,
    this.urgencia,
    this.impacto,
    this.status,
    this.localizacao,
  });

  DashboardFilter copyWith({
    int? empresa,
    String? empresaNome,
    DateTime? inicio,
    DateTime? fim,
    int? grupo,
    int? sistema,
    int? tipo,
    bool limparEmpresa = false,
    bool limparPeriodo = false,
    bool limparGrupo = false,
    bool limparSistema = false,
    bool limparTipo = false,
  }) {
    return DashboardFilter(
      empresa: limparEmpresa ? null : (empresa ?? this.empresa),
      empresaNome: limparEmpresa ? null : (empresaNome ?? this.empresaNome),
      inicio: limparPeriodo ? null : (inicio ?? this.inicio),
      fim: limparPeriodo ? null : (fim ?? this.fim),
      grupo: limparGrupo ? null : (grupo ?? this.grupo),
      usuario: usuario,
      sistema: limparSistema ? null : (sistema ?? this.sistema),
      categoria: categoria,
      tipo: limparTipo ? null : (tipo ?? this.tipo),
      prioridade: prioridade,
      urgencia: urgencia,
      impacto: impacto,
      status: status,
      localizacao: localizacao,
    );
  }

  /// Só as chaves não-nulas; datas em `yyyy-MM-dd`.
  Map<String, dynamic> toQuery() => {
        if (empresa != null) 'empresa': empresa,
        if (empresaNome != null) 'empresaNome': empresaNome,
        if (inicio != null) 'inicio': _iso(inicio!),
        if (fim != null) 'fim': _iso(fim!),
        if (grupo != null) 'grupo': grupo,
        if (usuario != null) 'usuario': usuario,
        if (sistema != null) 'sistema': sistema,
        if (categoria != null) 'categoria': categoria,
        if (tipo != null) 'tipo': tipo,
        if (prioridade != null) 'prioridade': prioridade,
        if (urgencia != null) 'urgencia': urgencia,
        if (impacto != null) 'impacto': impacto,
        if (status != null) 'status': status,
        if (localizacao != null) 'localizacao': localizacao,
      };

  bool get vazio => props.every((p) => p == null);

  static String _iso(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  List<Object?> get props => [
        empresa, empresaNome, inicio, fim, grupo, usuario, sistema, categoria,
        tipo, prioridade, urgencia, impacto, status, localizacao,
      ];
}
